#!/usr/bin/perl

package NetServer::SMTP;

$NetServer::SMTP::VERSION = "0.01";

@ISA = (qw(NetServer NetServer::Generic));

use Carp;
use File::Flock;
use Time::CTime;
use IO::Handle;
use IO::File;
use Data::Dumper;
use Net::SMTP;
use FreezeThaw qw(freeze thaw);

=pod

=head1 NAME

NetServer::SMTP - basic SMTP server class for Perl

=head1 SYNOPSIS

    my ($self) = NetServer::SMTP->new();
    while (<STDIN>) {
        next if (! defined($_));
        my (@vec) = split(/\s+/);
        my ($fn) = shift @vec;
        $fn = uc($fn);
        if (grep(/$fn/i, @$NetServer::SMTP::States) != 0) {
            $self->in($in);
            $self->out($out);
            $self->next_state_ok($fn) && do {
                $self->$fn(@vec);
            };
        } else {
              print STDERR "What on earth does [$fn][", 
	                   join(" ", @vec), "] mean?\n";
        }
        if ($self->{ERROR} > 0 ) {
	    $self->DESTROY();
	    exit;
	}
    }

=head1 DESCRIPTION 

A class that provides a basic SMTP server object and some methods. (Note
that it doesn't provide a B<run> method with a main execution loop -- hence
the above example.) 

(C<Net::SMTP> provides a corresponding client class.)

It accepts requests in accordance with RFC 821, 4.5.1 ("Minimum
Implementation"). No attempt to verify the authenticity of the sender is
made; no attempt is made to filter out relay attacks or deliver the
mail, and it doesn't even attempt to check messages for RFC 822 compliance. 
Instead, the mail is spooled in the form of a deep-frozen C<NetServer::SMTP> 
object, dropped into the spool directory.

Spooled mail may be transmitted by (a) unfreezing it into a live
C<NetServer::SMTP> object and (b) invoking the B<send()> method on it. 
This is the low-level delivery mechanism; it does not include a queueing 
mechanism. 

Only one delivery method is supported in the base C<NetServer::SMTP>
class; this is dumb SMTP forwarding to a remote smarthost. Child classes
derived from C<NetServer::SMTP> may provide alternative B<send()>
methods which override this default, for example to supply local
delivery methods, routing, and associated transport mechanisms for
transport via UUCP or other protocols.

=head2 To-do list 

RFC822 checking of incoming mail to ensure it's not totally corrupt
(via Mail::Internet?).

Velocity checking implemented at the server level -- a semaphore
maintains a count of children spawned/reaped, and if the spawn rate goes
over a designated hot limit the server will begin issuing 421 responses.

Queued mail should be tracked via a queue database -- probably a tied
DB_File.  The key to each record is the position in the queue; the value
is a record containing items like the number of retries (so far), the
filename of the message, whether to use local or remote delivery
methods, and so on.  The queue is handled in a round-robin fashion by
a queue delivery subroutine. Additional methods for queueing needed.

Currently, mail is stored using Freeze::Thaw to dump a frozen NetServer::SMTP
object. A better solution would be to dump a Mail::Internet object and a
NetServer::SMTP object containing delivery and queueing metainformation.
(Expect this in release 0.02.)

=head2 States

C<NetServer::SMTP> implements a rather minimalist mechanism for checking
that state transactions within the SMTP protocol are valid. When entering
a given state (or receiving an SMTP command), it checks the hash of arrays
C<NetServer::SMTP::NFA>; this contains a list of acceptable antecedent
states for the requested command. If the current state isn't in this list,
it assumes an error has occured and complains. This is just about okay
for a simple program which is intended to receive and spool messages,
but it is not a good basis for extension (e.g. for the implementation
of a full ESMTP server architecture). In any event, state consistency 
checking is carried out by calling C<next_state_ok()> -- more sophisticated
servers will want to override this.

Attempts to start an ESMTP session will therefore be politely rejected.

=head2 Methods

NetServer::SMTP knows about a few standard messages, and a basic set of SMTP
commands (each of which is implemented as a method): 

=over 4

=item new()

Create a new NetServer::SMTP object. The object is now available to process
incoming mail. It reads from STDIN, and writes responses to STDOUT; it
should be called via C<NetServer::Generic>.

Some initialisation parameters may be specified as a hash, or as a
filehandle referring to a configuration file, or as a configuration
file name.

Initialisation parameters may I<not> be changed once the object has
been created; you need to destroy it and start a new one. (Don't worry,
this isn't a major overhead.)

=item HELO

Commence new session

=item MAIL

Begin a new mail

=item RCPT

Specify recipients

=item DATA

Send data

=item RSET

Reset session

=item NOOP

Do nothing

=item QUIT

End session (spooling mail)

=back

These are the minimal SMTP commands required for a basic implementation
of RFC 821. Each command is handled via the autoloader, which knows what
to do.

In addition, NetServer::SMTP knows about the following extra commands,
which may not behave quite as you expect them to do:

=over 4

=item HELP

Normally, provides help on a command. 

=back

=cut

# known SMTP states
$NetServer::SMTP::States = [ qw(EHELO HELO MAIL RCPT DATA RSET NOOP 
                                QUIT HELP DUMP TURN) ];

# valid autoloaded methods

$NetServer::SMTP::methods = [ @$NetServer::SMTP::States, qw(IN OUT SERV) ];

# known SMTP response codes
$NetServer::SMTP::Err = {
    "211" => "System status, or system help reply",
    "214" => "Help message \n %s",
    "220" => "%s: ready for action",
    "221" => "Bye! %s",
    "250" => "OK: %s",
    "251" => "User not local; will forward to <forward-path>",
    "354" => "%s",
    "421" => "%s Service not available, closing connection",
    "450" => "Requested mail action not taken: mailbox unavailable",
    "451" => "Requested action aborted: error in processing",
    "452" => "Requested action not taken: insufficient system storage",
    "500" => "Syntax error, command unrecognized",
    "501" => "Syntax error in parameter or arguments: %s",
    "502" => "Command not implemented %s",
    "503" => "Bad sequence of commands",
    "504" => "Command parameter not implemented",
    "550" => "Requested action not taken: %s",
    "551" => "User not local; please try %s",
    "552" => "Requested mail action aborted: exceeded storage allocation",
    "553" => "Requested action not taken: mailbox name not allowed",
    "554" => "Transaction failed: %s"
};

# legal SMTP state transitions -- each state is followed by an arrayref
# to its legal predecessors. To determine if a new state is legal, check
# to see if it's predecessor is in the array in NFA. 

$NetServer::SMTP::NFA = {
    "HELO" => [ "undef" ],
    "EHELO" => [ "undef" ],
    "MAIL" => [ qw(HELO RSET NOOP DATA) ],
    "RCPT" => [ qw(MAIL NOOP RCPT RSET) ],
    "MAIL" => [ qw(HELO NOOP DATA RSET) ],
    "DATA" => [ qw(RCPT NOOP) ],
    "TURN" => [ @$NetServer::SMTP::States ],
    "NOOP" => [ @$NetServer::SMTP::States ],
    "QUIT" => [ @$NetServer::SMTP::States ],
    "HELP" => [ @$NetServer::SMTP::States ],
    "DUMP" => [ @$NetServer::SMTP::States ],
    "RSET" => [ @$NetServer::SMTP::States ],
};
    
sub new {
    # create a new NetServer::SMTP
    my ($class) = shift; 
    my ($self) = bless {}, $class;
    if (@_) {
        $self = $self->initialise(@_);
    }
    if (! defined($self->{silent})) {
        $self->respond(220, "leafmail $NetServer::SMTP::VERSION is ready");
    }
    return $self;
}

sub initialise {

=pod

=item initialise()

Called by B<new()> to initialise the new object.  Initialisation keys 
may be specified as a hash, supplied as a parameter to the new
object, or as a filename or file handle containing a frozen 
B<NetServer::SMTP> object which is users to overlay the object. 

Recognized keys are:

=over 4

=item myhost

My host name (FQDN) 

=item allowed

array of aliases for hosts users allowed to send mail

=item silent

If silent, dont say hello when creating a new server (we have other
reasons for creating NetServer::SMTP objects, once in a while :)

=item relay

Relay hostname (FQDN) 

=item ERROR

If this flag goes non-zero, Something Bad has happened and the session
should either terminate or refuse to proceed further

=item spooldir

Directory where spooled transactions are waiting

=back

=cut

    my ($self) = shift ;
    my (@junk);
    if (scalar(@_) == 1) {
        # it's a filehandle or filename -- open it and load the contents
        my ($file);
        my ($fn) = shift;
        if (ref($fn) !~ /file/i) {
            $file = new IO::File($fn, "r") or croak "Could not open $fn\n";
        }
        my ($frozen) = join( "", $file->getlines() );
        $file->close();
        ($self, @junk) = thaw($frozen);
        $self->{spooledfile} = $fn;
        return $self;
    } elsif (scalar(@_) % 2 == 0)  {
        # it's an initialisation hash -- overlay it on $self
        %$self = (@_);
        return $self;
    } else {
        croak "Don't know how to initialise from [", join("][", @_), "]\n";
    }
}

sub respond ($$;@) {
    # issue a response code and the corresponding message
    # NOTE: SMTP response messages are printf() format strings and 
    # positional substitution may occur if additional respond() parameters
    # are available
    my ($self) = shift; 
    my ($resp) = shift;
    my (@args) = @_;
    print STDOUT "$resp ", sprintf($NetServer::SMTP::Err->{$resp}, @args), 
        "\r\n";
}

sub EHLO {
    my $self = shift;
    $self->respond(550, "I don't talk ESMTP");
    return;
}

sub HELP {
    my $self = shift;
    my $resp = "<<%%"
NetServer::SMTP $NetServer::SMTP::VERSION

Known Commands: 

HELO MAIL RCPT DATA RSET NOOP QUIT HELP DUMP TURN

%%
    $self->respond("214", $resp);
    return;
}

sub HELO {
    # say hello -- start a session
    my ($self) = shift;
    my ($next) = join(" ", @_);
    $next =~ s/\r\n//;;
    my ($f, $snd) = "";
    if ($next =~ /^from:/i) {
        $next =~ /(from:*)\s+(.*)/i;
        ($f, $snd) = ($1, $2);
        $snd =~ s/[><]//g;
    } else {
        $snd = $next;
    }
    if (grep(/$snd/i, @{ $self->{allowed} }) != 0) {
        $self->{host} = $snd;
        my ($s) = $self->serv();
	my ($peer) = $s->peer();
        if ($self->{host} ne $peer->[0]) {
            $self->respond(554, " lie to me at your peril!" );
            $self->{ERROR} = 1;
            return;
        }
	my ($line) = "Hello to you too, $snd";
        $self->respond(250, $line);
    } else {
        $self->respond(421, $snd);
	$self->{ERROR} = 1;
    }
    return;
}

sub MAIL {
    # specify sender
    my ($self) = shift;
    my ($next) = join(" ", @_);
    if ($next !~ /FROM:/i) {
        $self->respond(501);
        return;
    }
    my ($t, $from) = split(/:/, $next);
    $from =~ s/<(.+)>/$1/;
    if ($from !~ /\S+@\S+/) {
        my ($serv) = $self->serv();
        $from .= "@" . $serv->peername() ;
    }
    $self->{from} = $from;
    $self->respond(250, "sender seems okay (note: no MX or alias checking!)");
    return;
}

sub RCPT {
    # append to recipient list -- this is an arrayref method 
    my ($self) = shift;
    my ($next) = join(" ", @_);
    if ($next !~ /TO:/i) {
        $self->respond(501);
        return;
    } else {
        my ($t, $rcpt) = split(/:/, $next);
        $rcpt =~ s/<(.+)>/$1/;
        if ($rcpt !~ /\S+@\S+/) {
            my ($serv) = $self->serv();
            $rcpt .= "@" . $serv->peername() ;
        }
        push @{$self->{rcpt}}, $rcpt;
        $self->respond(250, "recipient okay");
        return;
    }
}

sub DATA {
    # append message data, read from STDIN (unless optional filehandle is
    # specified)
    my ($self) = shift;
    my ($in) = $self->in();
    my ($out) = $self->out();
    $self->respond(354, "Ready for data");
    my (@head, @body) = ();
    my $state = "hdr";
    DATA:
    while (defined($tmp = $in->getline())) {
        $tmp =~ s/\r\n$//;
        chomp $tmp;
        last DATA if ($tmp =~ /^\.$/) ;
	if ($tmp eq "") {
            $state = "body";
	}
        if ($state eq "hdr") {
            push (@head, $tmp);
	} else {
            push (@body, $tmp);
	}
    }
    # tricky bit; brand the data with our received: line
    if ( (grep(/^From: /, @head) && 
         (grep(/^To: /, @head)) && 
	 (grep(/^Subject: /, @head))) ) {
        my $s = $self->serv();
	my $p = $s->peer();
        my ($received) = "Received: from " . $self->{host} . "(" . 
	    $p->[0] . "[" . $p->[1] . "]) at " .
            strftime("%c", localtime(time)) . " by " . $self->{myhost} .
            " with SMTP via LeafMail ($NetServer::SMTP::VERSION) " .
	    "(relaying via " . $self->{relay} .  ");" . 
	    strftime(" %c", localtime(time));
        unshift(@head , $received);
        my ($all) = join ("\r\n", @head, @body);
        $self->{body} = $all;
        if ($self->spool() == 0) {
            my $sp = $self->{spooledfile};
            $self->respond(250, "Mail accepted (spooled in $sp)");
        } else {
            $self->{ERROR} = 1;
        }
    } else {
        # missing header lines -- one of From:, To:, or Subject:
	$self->respond(501, "Missing header lines");
    }
    return;
}


sub RSET {
    my ($self) = shift;
    $self->{rcpt} = $self->{from} = $self->{body} = undef;
    $self->respond(250, "Reset OK");
    return;
}

sub NOOP {
    my ($self) = shift;
    $self->respond(250, "I'm waiting ...");
    return;
}

sub QUIT {
    my $self = shift ;
    $self->respond(221, "So long, and thanks for all the fish");
    $self->{ERROR}++;
    return;
}

sub TURN {
    my $self = shift;
    $self->respond(502, "- I don't do scat");
    return;
}

sub DUMP {
    my $self = shift ;
    print STDOUT Dumper $self;
    return;
}

sub spool {
    # return 1 error, 0 for success
    my $self = shift;
    my ($tmphash) = {};
    my ($foo);
    foreach $foo (qw(SERV IN OUT allowed prevstate)) {
        next if (! defined($self->{$foo}));
        $tmphash->{$foo} = $self->{$foo};
        delete $self->{$foo};
    }
    my $tmp = $self->{spooldir} . "/spool." . $$  . time;
    $self->{spooledfile} = $tmp;
    my $frozen = freeze($self);
    print STDERR "spooled to $tmp\n";
    # $self->{junk} = $junk;
    my $sp = IO::File->new($tmp, "w");
    if (defined $sp) {
	lock $tmp;
	$sp->print($frozen);
        $sp->close();
        unlock $tmp;
    } else {
        $self->respond(554, "I hate it when this happens!");
        return 1;
    }
    foreach my $foo (qw(serv in out allowed prevstate)) {
        $self->{$foo} = $tmphash->{$foo} ;
    }
    return 0;
}

sub send {
    my ($self) = shift;
    my ($smtp, $abort) = 0;
    if (defined ($self->{smtp_session} )) {
        $smtp = $self->{smtp_session};
    } else {
        my (%options) = (
            "hello" => $self->{myhost},
            "timeout" => 60 ,
            "Debug" => 0
        );
        $smtp = Net::SMTP->new($self->{relay}, %options );
    }
    if (ref($smtp) =~ /smtp/i) {
        $smtp->mail($self->{from}) || $abort++;
	foreach (@{ $self->{rcpt} }) {
	    next if (! defined($_));
	    print "sending to: $_\n";
            $smtp->to($_) || $abort++;
	}
        my $data = $self->{body};
        $smtp->data( $data ) || $abort++;
        $self->{smtp_session} = $smtp;
    }
    if ($abort == 0) {
        # nothing blew up, so don't remove the spooled file
        if (unlink($self->{spooledfile}) != 1) {
            warn "failed to unlink ", $self->{spooledfile}, ":$!\n";
	}
    } else {
        warn "Failed to send ", $self->{spooledfile}, ": try again later\n";
	return 0;
    }
    return $self->{spooledfile};
}

sub prevstate {
    # we're messing with an arrayref here, hence incompatability with AUTOLOAD
    my ($self) = shift;
    if (@_) {
        push @{$self->{prevstate}}, @_;
    } else {
        my $tmp = pop @{$self->{prevstate}};
        push @{$self->{prevstate}}, $tmp;
        return $tmp;
    }
}

sub next_state_ok {
    my ($self) = shift;
    my ($next) = shift;
    # check if next state is okay; return 0 if it's in wrong order,
    # and emit an appropriate failure message
    my ($prevstate) = $self->prevstate() || "undef";
    if (! grep(/$prevstate/i, @{ $NetServer::SMTP::NFA->{$next} } )) {
        # $prevstate was not found in one of the permitted previous states
        $self->respond(503);
        # $self->{ERROR}++;
        return 0;
    }
    $self->prevstate($next);
    return 1;
}

sub AUTOLOAD {
    # change state, process SMTP commands. Recognized commands are
    my ($self) = shift;
    my ($name) = uc($AUTOLOAD) ;
    $name =~ s/.*://;
    if (@_) {
        if (! grep(/$name/i, @$NetServer::SMTP::methods)) { # States
            $self->respond(502);
            return;
        }
        return $self->{$name} = shift;
    } else {
        return $self->{$name};
    }
}

1;

