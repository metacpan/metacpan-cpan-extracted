package Net::IMAP::Simple::NB;

our $VERSION = '1.1';

use strict;
use warnings;

no warnings 'deprecated';

use base qw(Danga::Socket Net::IMAP::Simple);

=head1 NAME

Net::IMAP::Simple::NB - Non-blocking IMAP.

=head1 SYNOPSIS

    use Net::IMAP::Simple::NB;
    use Scalar::Util qw(weaken isweak);
    Danga::Socket->AddTimer(0, sub {
        # Create the object
        my $imap = Net::IMAP::Simple::NB->new('server:143') ||
           die "Unable to connect to IMAP: $Net::IMAP::Simple::errstr\n";
        
        $imap->login('user','password', sub {
            my $login_ok = shift;
            if ($login_ok) {
                print "Login OK\n";
                $imap->select("INBOX", sub {
                    my $nm = shift;
                    print "Got $nm Messages\n";
                    my $i = 1;
                    my $sub;
                    $sub = sub {
                        weaken($sub) unless isweak($sub);
                        my $headers = shift;
                        print grep { /^Subject:/ } @$headers;
                        $i++;
                        $imap->top($i, $sub) unless $i == $nm;
                    };
                    $imap->top($i, $sub);
                });
            }
            else {
                warn("Login failed!");
            }
        });
    });
    
    Danga::Socket->EventLoop;

=head1 DESCRIPTION

This module models the Net::IMAP::Simple API, but works non-blocking. It is based
on the Danga::Socket framework, rather than anything generic. Sorry if that doesn't
fit your world-view.

=head1 API

The C<Net::IMAP::Simple::NB> API models the C<Net::IMAP::Simple> API exactly,
with the difference that instead of having return values, you supply a callback
as the last parameter of the method call. This callback will receive in @_ the
same as whatever the C<Net::IMAP::Simple> method would have returned.

The only real difference aside from that is a slightly modified constructor:

=head2 C<< CLASS->new(...) >>

 my $imap = Net::IMAP::Simple->new( $server [ :port ]);
 OR
 my $imap = Net::IMAP::Simple->new( $server [, option_name => option_value ] );

This class method constructs a new C<Net::IMAP::Simple::NB> object. It takes one
required parameter which is the server to connect to, and additional optional
parameters.

The server parameter may specify just the server, or both the server and port
number. To specify an alternate port, seperate it from the server with a colon
(C<:>), C<example.com:5143>.

On success an object is returned. On failure, nothing is returned and an error
message is set to $Net::IMAP::Simple::errstr.

B<OPTIONS:>

 port             => Assign the port number (default: 143)

 timeout          => Connection timeout in seconds.

 use_v6           => If set to true, attempt to use IPv6
                  -> sockets rather than IPv4 sockets.
                  -> This option requires the
                  -> IO::Socket::INET6 module

 bindaddr         => Assign a local address to bind


 use_select_cache => Enable select() caching internally

 select_cache_ttl => The number of seconds to allow a
                  -> select cache result live before running
                  -> select() again.

=cut

use constant CLEANUP_TIME => 5; # every N seconds

sub max_idle_time       { 3600  }   # one hour idle timeout
sub max_connect_time    { 18000 }   # 5 hours max connect time

sub event_err { my $self = shift; $self->close("Error") }
sub event_hup { my $self = shift; $self->close("Disconnect (HUP)") }
sub close     { my $self = shift; warn("Close: $_[0]\n"); $self->SUPER::close(@_); }

use fields qw(
    count
    server
    port
    timeout
    use_v6
    bindaddr
    use_select_cache
    select_cache_ttl
    current_callback
    current_command
    line
    create_time
    alive_time
    command_final
    command_process
    BOXES
    last
    working_box
    _errstr
    read_bytes
    );

sub new {
    my ( $class, $server, %opts) = @_;

    my Net::IMAP::Simple::NB $self = fields::new($class);
    
    $self->{count} = -1;
    
    my ($srv, $prt) = split(/:/, $server, 2);
    $prt ||= ($opts{port} ? $opts{port} : $self->_port);
    
    $self->{server} = $srv;
    $self->{port} = $prt;
    $self->{timeout} = ($opts{timeout} ? $opts{timeout} : $self->_timeout);
    $self->{use_v6} = ($opts{use_v6} ? 1 : 0);
    $self->{bindaddr} = $opts{bindaddr};
    $self->{use_select_cache} = $opts{use_select_cache};
    $self->{select_cache_ttl} = $opts{select_cache_ttl};
    $self->{line} = '';
    $self->{create_time} = $self->{alive_time} = time;

    # Pop the port off the address string if it's not an IPv6 IP address
    if(!$self->{use_v6} && $self->{server} =~ /^[A-Fa-f0-9]{4}:[A-Fa-f0-9]{4}:/ && $self->{server} =~ s/:(\d+)$//g){
        $self->{port} = $1;
    }
    
    my $sock = $self->_connect;
    if(!$sock){
        $! =~ s/IO::Socket::INET6?: //g;
        $Net::IMAP::Simple::errstr = "connection failed $!";
        return;
    }
    
    $self->SUPER::new($sock);
    $self->watch_read(1);
    
    return $self;
}

sub _connect {
    my Net::IMAP::Simple::NB $self = shift;
    my $sock = $self->SUPER::_connect;
    return unless $sock;
    IO::Handle::blocking($sock, 0);
    return $sock;
}

sub event_read {
    my Net::IMAP::Simple::NB $self = shift;
    
    $self->{alive_time} = time;
    
    my $bref = $self->read(131072);
    return $self->close("read failed: $!") unless defined $bref;
    
    $self->{line} .= $$bref;
    
    while ($self->{line} =~ s/^([^\n]*\n)//) {
        my $line = $1;
        $self->process_response_line($line);
    }
}

sub process_response_line {
    my Net::IMAP::Simple::NB $self = shift;
    my $line = shift;
    
    #print "S: $line";

    if ($self->{read_bytes}) {
        $self->{read_bytes} -= bytelength($line);
        $self->{read_bytes} = 0 if $self->{read_bytes} < 0;
        $self->{command_process}->($line);
    }
    elsif ($line =~ /^\*.*\{(\d+)\}$/ ) {
        my $bytes = $1;
        $self->{read_bytes} = $1;
        $self->{command_process}->($line);
    }
    else {
        my $ok = $self->_cmd_ok($line);
        if ($ok) {
            $self->{current_command} = undef;
            return $self->{current_callback}->($self->{command_final}->($line));
        }
        elsif (defined($ok)) { # $ok is false here
            $self->{current_command} = undef;
            return $self->{current_callback}->();
        }
        else {
            $self->{command_process}->($line) if $self->{command_process};
        }
    }
}

sub _send_cmd {
    my Net::IMAP::Simple::NB $self = shift;
    my ( $name, $value ) = @_;
    my $id   = $self->_nextid;
    my $cmd  = "$id $name" . ($value ? " $value" : "") . "\r\n";
    #print "C: $cmd";
    $self->write($cmd);
}

sub _process_cmd {
    my Net::IMAP::Simple::NB $self = shift;
    my (%args) = @_;
    die "Command currently in progress: $self->{current_command}\n" if $self->{current_command};
    $self->{command_final} = $args{final} || die "No final calling $args{cmd}";
    $self->{command_process} = $args{process} || die "No process calling $args{cmd}";
    $self->_send_cmd(@{$args{cmd}});
    $self->{current_command} = $args{cmd};
}

use Carp qw(confess);
sub set_callback {
    my Net::IMAP::Simple::NB $self = shift;
    $self->{current_callback} = shift || confess "set_callback called with no callback";
}

sub login { my $self = shift; $self->set_callback(pop); $self->SUPER::login(@_); }
sub messages {my $self = shift; $self->set_callback(pop); $self->SUPER::messages(@_) }
sub top {my $self = shift; $self->set_callback(pop); $self->SUPER::top(@_) }
sub seen {my $self = shift; $self->set_callback(pop); $self->SUPER::seen(@_) }
sub list {my $self = shift; $self->set_callback(pop); $self->SUPER::list(@_) }
sub get {my $self = shift; $self->set_callback(pop); $self->SUPER::get(@_) }
sub getfh {my $self = shift; $self->set_callback(pop); $self->SUPER::getfh(@_) }
sub delete {my $self = shift; $self->set_callback(pop); $self->SUPER::delete(@_) }
sub create_mailbox {my $self = shift; $self->set_callback(pop); $self->SUPER::create_mailbox(@_) }
sub delete_mailbox {my $self = shift; $self->set_callback(pop); $self->SUPER::delete_mailbox(@_) }
sub rename_mailbox {my $self = shift; $self->set_callback(pop); $self->SUPER::rename_mailbox(@_) }
sub copy {my $self = shift; $self->set_callback(pop); $self->SUPER::copy(@_) }


# modified from original to include $last_sub support
sub select {
    my Net::IMAP::Simple::NB $self = shift;
    $self->set_callback(pop);
    
    my ( $mbox, $last_sub ) = @_;
    
    $mbox = 'INBOX' unless $mbox;
    
    $self->{working_box} = $mbox;
    
    $self->{BOXES}->{ $mbox }->{proc_time} ||= 0;
    
    if($self->{use_select_cache} && (time - $self->{BOXES}->{ $mbox }->{proc_time}) <= $self->{select_cache_ttl}){
        return $self->{BOXES}->{$mbox}->{messages};
    }
    
    $self->{BOXES}->{$mbox}->{proc_time} = time;
    
    my $t_mbox = $mbox;
    
    $self->_process_cmd(
        cmd     => [SELECT => _escape($t_mbox)],
        final   => sub { 
                       $self->{last} = $self->{BOXES}->{$mbox}->{messages};
                       if ($last_sub) {
                           return $last_sub->();
                       }
                       else {
                           return $self->{last};
                       }
                   },
        process => sub {
                if($_[0] =~ /^\*\s+(\d+)\s+EXISTS/i){
                        $self->{BOXES}->{$mbox}->{messages} = $1;
                } elsif($_[0] =~ /^\*\s+FLAGS\s+\((.*?)\)/i){
                        $self->{BOXES}->{$mbox}->{flags} = [ split(/\s+/, $1) ];
                } elsif($_[0] =~ /^\*\s+(\d+)\s+RECENT/i){
                        $self->{BOXES}->{$mbox}->{recent} = $1;
                } elsif($_[0] =~ /^\*\s+OK\s+\[(.*?)\s+(.*?)\]/i){
                        my ($flag, $value) = ($1, $2);
                        if($value =~ /\((.*?)\)/){
                                $self->{BOXES}->{$mbox}->{sflags}->{$flag} = [split(/\s+/, $1)];
                        } else {
                                $self->{BOXES}->{$mbox}->{oflags}->{$flag} = $value;
                        }
                }
        },
    );
}

sub unread {
    my ( $self ) = @_;
    $self->set_callback(pop);
    
    my @list;
    $self->_process_cmd(
        cmd     => [SEARCH => qq[UNSEEN]],
        final   => sub { \@list },
        process => sub {
            if ($_[0] =~ /\* SEARCH (.*)$/) {
                push @list, split(/\s+/, $1);
            }
        },
    );
}

sub message_info {
    my ( $self, $number ) = @_;
    $self->set_callback(pop);
    
    my %flags;
    my @lines;
    $self->_process_cmd(
        cmd     => [FETCH => qq[$number (FLAGS INTERNALDATE RFC822.HEADER)]],
        final   => sub { \%flags, \@lines },
        process => sub {
            if (%flags) {
                push @lines, $_[0];
            }
            else {
                $_ = shift;
                if (/\bFLAGS \((.*?)\)/) {
                    $flags{$_}++ for split(/\s+/, $1);
                }
                if (/\bINTERNALDATE "(\d\d-[a-zA-Z]{3}-\d{4} \d\d:\d\d:\d\d [\+\-]\d{4})"/) {
                    $flags{DATE} = $1;
                }
            }
        },
    );
}

sub message {
    my ( $self, $number ) = @_;
    $self->set_callback(pop);
    
    my %flags;
    my @lines;
    $self->_process_cmd(
        cmd     => [FETCH => qq[$number (FLAGS INTERNALDATE RFC822)]],
        final   => sub { \%flags, \@lines },
        process => sub {
            if (%flags) {
                push @lines, $_[0];
            }
            else {
                if (/\bFLAGS (\(.*?\))/) {
                    $flags{$_}++ for split(/\s+/, $1);
                }
                if (/\bINTERNALDATE "(\d\d-[a-zA-Z]{3}-\d{4} \d\d:\d\d:\d\d [\+\-]\d{4})"/) {
                    $flags{DATE} = $1;
                }
            }
        },
    );
}

sub flags {
    my Net::IMAP::Simple::NB $self = shift;
    my $cb = pop;
    my $folder = shift;
    
    $self->select($folder, sub { @{ $self->{BOXES}->{ $self->current_box }->{flags} } }, $cb );
}


sub recent {
    my Net::IMAP::Simple::NB $self = shift;
    my $cb = pop;
    my $folder = shift;
    
    $self->select($folder, sub { $self->{BOXES}->{ $self->current_box }->{recent} }, $cb );
}

sub expunge_mailbox {
    my Net::IMAP::Simple::NB $self = shift;
    my $cb = pop;
    my $box = shift;
    $self->select($box, sub {
        $self->_process_cmd(
            cmd     => ['EXPUNGE'],
            final   => sub { 1 },
            process => sub { },
        );
    }, $cb);
}

sub folder_subscribe {
    my ($self, $box) = @_;
    my $cb = pop;
    $self->select($box, sub {
        $self->_process_cmd(
            cmd     => [SUBSCRIBE => _escape($box)],
            final   => sub { 1 },
            process => sub { },
        );
    }, $cb);
}

sub folder_unsubscribe {
    my ($self, $box) = @_;
    my $cb = pop;
    $self->select($box, sub {
        $self->_process_cmd(
            cmd     => [UNSUBSCRIBE => _escape($box)],
            final   => sub { 1 },
            process => sub { },
        );
    }, $cb);
}

sub quit {
    my Net::IMAP::Simple::NB $self = shift;
    $self->set_callback(pop);
    my ( $hq ) = @_;
    $self->_send_cmd('EXPUNGE');
    
    if(!$hq){   
        $self->_process_cmd(cmd => ['LOGOUT'], final => sub { $self->close }, process => sub{});
    } else {
        $self->_send_cmd('LOGOUT');
        $self->close;
    }
    
    return 1;
}

sub mailboxes {
    my Net::IMAP::Simple::NB $self = shift;
    $self->_mailboxes('LIST', @_);
}

sub mailboxes_subscribed {
    my Net::IMAP::Simple::NB $self = shift;
    $self->_mailboxes('LSUB', @_);
}

sub _mailboxes {
    my Net::IMAP::Simple::NB $self = shift;
    $self->set_callback(pop);
    my ( $type, $box, $ref ) = @_;
    
    $ref ||= '""';
    my @list;
    my $mode = 'listcheck';
    my $query = [$type => qq[$ref *]];
    if ( defined $box ) {
        my $query = [$type => qq[$ref $box]];
    }
    
    # recurse, should probably follow
    # RFC 2683: 3.2.1.1.  Listing Mailboxes
    return $self->_process_cmd(
        cmd     => $query,
        final   => sub { _unescape($_) for @list; @list },
        process => sub {
            my $line = shift;
            # * LIST (\Unmarked \HasNoChildren) "." "INBOX.web_board"
            if ($mode eq 'listcheck') {
                if ( $line =~ /^\*\s+(LIST|LSUB).*\s+(\".*?\")\s*$/i ||
                     $line =~ /^\*\s+(LIST|LSUB).*\s+(\S+)\s*$/i )
                {
                    push @list, $2;
                }
                elsif ( $line =~ /^\*\s+(LIST|LSUB).*\s+\{\d+\}\s*$/i ) {
                    $mode = 'listextra';
                }
            }
            elsif ($mode eq 'listextra') {
                chomp($line);
                $line =~ s/\r//;
                _escape($line);
                push @list, $line;
                $mode = 'listcheck';
            }
        },
    );
}

sub bytelength {
    use bytes;
    return length($_[0]);
}

sub _escape {
    $_[0] =~ s/\\/\\\\/g;
    $_[0] =~ s/\"/\\\"/g;
    $_[0] = "\"$_[0]\"";
    $_[0];
}

sub _unescape {
    $_[0] =~ s/^"//g;
    $_[0] =~ s/"$//g;
    $_[0] =~ s/\\\"/\"/g;
    $_[0] =~ s/\\\\/\\/g;
}

Danga::Socket->AddTimer(CLEANUP_TIME, \&_do_cleanup);

# Cleanup routine to get rid of timed out sockets
sub _do_cleanup {
    my $now = time;
    
    Danga::Socket->AddTimer(CLEANUP_TIME, \&_do_cleanup);
    
    my $sf = __PACKAGE__->get_sock_ref;
    
    my $conns = 0;

    my %max_age;  # classname -> max age (0 means forever)
    my %max_connect; # classname -> max connect time
    my @to_close;
    while (my $k = each %$sf) {
        my Net::IMAP::Simple::NB $v = $sf->{$k};
        my $ref = ref $v;
        next unless $v->isa('Net::IMAP::Simple::NB');
        $conns++;
        unless (defined $max_age{$ref}) {
            $max_age{$ref}      = $ref->max_idle_time || 0;
            $max_connect{$ref}  = $ref->max_connect_time || 0;
        }
        if (my $t = $max_connect{$ref}) {
            if ($v->{create_time} < $now - $t) {
                push @to_close, $v;
                next;
            }
        }
        if (my $t = $max_age{$ref}) {
            if ($v->{alive_time} < $now - $t) {
                push @to_close, $v;
            }
        }
    }
    
    $_->close("Timeout") foreach @to_close;
}



1;

__END__

=head1 AUTHOR

Matt Sergeant, <matt@sergeant.org>.

=head1 SEE ALSO

L<Net::IMAP::Simple>

=head1 LICENSE

You may use and redistribute this module under the same terms as perl itself.

=cut
