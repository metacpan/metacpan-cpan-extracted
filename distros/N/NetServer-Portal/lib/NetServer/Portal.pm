use strict;
package NetServer::Portal;
use Event 0.70 qw(time);
use Carp;
use Symbol;
use Socket;
use Storable 0.6 qw(store retrieve);
use Sys::Hostname;
use constant NICE => -1;
use base 'Exporter';
use vars qw($VERSION @EXPORT_OK $BasePort $Host $Port %PortInfo
	    $StoreFile $StoreTop $Storer);
$VERSION = '1.08';
@EXPORT_OK = qw($Host $Port %PortInfo term);

$BasePort = 7000;
$Host = eval { hostname } || 'somewhere';

$StoreFile = $0;
$StoreFile =~ s,^.*/,,;
$StoreFile =~ s/[-\._]//g;
$StoreFile = "/var/tmp/$StoreFile" . '.npc';

my $terminal;
sub term {
    return $terminal
	if $terminal;
    require Term::Cap;
    $terminal = Term::Cap->Tgetent({ TERM => 'xterm', OSPEED => 9600 });
}

sub register {
    shift;
    my %attr = @_;
    confess "no package" if !exists $attr{package};
    $PortInfo{ $attr{package} } = \%attr;
}

sub set_storefile {
    my ($class, $path) = @_;
    $StoreFile = $path;
}

sub default_start {
    require NetServer::Portal::Top;
    require NetServer::Portal::Pi;
    eval {
	my $sock = NetServer::Portal->new_socket();
	NetServer::Portal->start($sock);
#	warn "Listening on ".(7000+($$%1000))."\n";
    };
    if ($@) { warn; return }
}

sub new_socket {
    my ($class, $port) = @_;
    $Port = $port || $BasePort + $$ % 1000;
    
    # Mostly snarfed from perlipc example; thanks!
    my $proto = getprotobyname('tcp');
    my $sock = gensym;
    socket($sock, PF_INET, SOCK_STREAM, $proto) or die "socket: $!";
    setsockopt($sock, SOL_SOCKET, SO_REUSEADDR, pack('l', 1))
	or die "setsockopt: $!";
    bind($sock, sockaddr_in($Port, INADDR_ANY)) or die "bind: $!";
    listen($sock, SOMAXCONN);
    $sock;
}

sub start {
    my ($class, $sock) = @_;
    
    eval { $StoreTop = retrieve($StoreFile) };
    if ($@) {
	if ($@ =~ /No such file/) {
	    # ok
	} else {
	    warn $@;
	}
	$StoreTop = {};
    };
    $Storer =
	Event->idle(desc => "NetServer::Portal $StoreFile", parked=>1,
		    min => 15, max => 300, nice => 1, cb => sub {
			store $StoreTop, $StoreFile;
		    });

    Event->io(fd => $sock, nice => NICE, cb => \&service_client,
	      desc => "NetServer::Portal");
}

sub service_client {
    my ($e) = @_;
    my $sock = gensym;
    my $paddr = accept $sock, $e->w->fd or die "accept: $!";
    my ($port,$iaddr) = sockaddr_in($paddr);
    (bless {
	    from => gethostbyaddr($iaddr, AF_INET) || inet_ntoa($iaddr),
	   }, 'NetServer::Portal::Client')->init($sock);
}

package NetServer::Portal::Client;
use Carp;
use constant NICE => -1;

use vars qw($Clients);
$Clients = 0;

require NetServer::Portal::Login;
use constant LOGIN => 'NetServer::Portal::Login';

sub init {
    my ($o, $sock) = @_;
    if (!$Clients) {
	$NetServer::Portal::Storer->repeat(1);
	$NetServer::Portal::Storer->start;
    }
    ++$Clients;
    $o->{io} = Event->io(fd => $sock, nice => NICE,
			 cb => [$o, 'cmd'],
			 desc => ref($o)." $o->{from}");
    $o->set_screen(LOGIN);
    $o->refresh;
}

sub set_screen {
    my ($o, $to) = @_;

    $to = $o->{prev_screen} if 
	$to && $to eq 'back';
    if ($o->{screen}) {
	$to = LOGIN
	    if $to && $to eq ref $o->{screen};
	$o->{prev_screen} = ref $o->{screen};
	$o->{screen}->leave
	    if $o->{screen}->can('leave');
	$o->{io}->timeout(undef);
    }

    my $login = $o->{screens}{ &LOGIN };
    my $user = $login->{user} if
	$login;
    $o->{screens}{$to} = $to->new($o, $user) if
	$to && !exists $o->{screens}{$to};
    if ($to) {
	if ($user) {
	    my $c = $o->conf;
	    $c->{screen} = $to;
	}
	$o->{screen} = $o->{screens}{$to};
	die "$to->new failed"
	    if !ref $o->{screen};
	$o->{screen}{error} = '';
	$o->{screen}->enter($o)
	    if $o->{screen}->can('enter');
    } else {
	# logging out
    }
    $o->{needs_clear}=1;
    $o->{screen}
}

sub conf {
    my ($o, $pkg) = @_;
    my $login = $o->{screens}{ &LOGIN };
    confess "eh?" if !$login;
    my $user = $login->{user};
    if (!$pkg) {
	$NetServer::Portal::StoreTop->{$user}
    } else {
	$NetServer::Portal::StoreTop->{$user}{$pkg} ||= bless {}, $pkg;
    }
}

sub format_line {
    my ($o) = @_;
    my $col = $o->conf->{cols} - 1;
    sub {
	my $l;
	if (@_ == 0) {
	    $l = '';
	} elsif (@_ == 1) {
	    $l = $_[0]
	} else {
	    my $fmt = shift @_;
	    $l = sprintf $fmt, @_;
	}
	if (length $l < $col) { $l .= ' 'x($col - length $l); }
	elsif (length $l > $col) { $l = substr($l,0,$col) }
	$l .= "\n";
	$l;
    }
}

sub refresh {
    my ($o) = @_;

    my $buf;
    if ($o->{needs_clear}) {
	$o->{needs_clear} = 0;
	$buf .= NetServer::Portal::term->Tputs('cl',1,$o->{io}->fd);
    }
    $buf .= $o->{screen}->update($o);

    # Deliberately ignore partial writes.  We do *not* want to block
    # here!  It is better to send half a screen and let the user
    # request an explicit update.
    #
    return $o->cancel if !defined syswrite $o->{io}->fd, $buf, length $buf;
}

sub cmd {
    my ($o, $e) = @_;
    if ($e->got eq 't') {
	$o->refresh;
	return;
    }
    my $in;
    return $o->cancel if !sysread $e->w->fd, $in, 200;

    if ($in =~ s/\s*\n$//) {
	#ok
    } else {
	$o->refresh;  # ^C pressed
	return;
    }
    $in =~ s/^\s+//;
    $o->{screen}{error} = '';

    if ($in =~ m/^\!/) {
	$o->{screens}{&LOGIN}->cmd($o, $in);
    } else {
	$o->{screen}->cmd($o, $in);
    }
    $o->refresh
	if $o->{io};
}

sub cancel {
    my ($o) = @_;
    --$Clients;
    if (!$Clients) {
	$NetServer::Portal::Storer->repeat(0);
	$NetServer::Portal::Storer->now;
    }
#    warn "$o->cancel\n";
    $o->set_screen();  # leave
    close $o->{io}->fd;
    $o->{io}->cancel;
    $o->{io} = undef;
}

1;

__END__

=head1 NAME

NetServer::Portal - Interactively Manipulate Daemon Processes

=head1 SYNOPSIS

  require NetServer::Portal;

  'NetServer::Portal'->default_start();  # creates server
  warn "NetServer::Portal listening on port ".(7000+($$ % 1000))."\n";

=head1 DESCRIPTION

This module implements a framework for adding interactive windows into
daemon processes.  The portal server listens on port 7000+($$%1000) by
default.

A C<top>-like server is included that can help debug complicated event
loops.

=head1 SEE ALSO

L<NetServer::Portal::Pi>, L<NetServer::Portal::Top>

=cut
