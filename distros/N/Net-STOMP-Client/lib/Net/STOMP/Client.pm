#+##############################################################################
#                                                                              #
# File: Net/STOMP/Client.pm                                                    #
#                                                                              #
# Description: STOMP object oriented client module                             #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Net::STOMP::Client;
use strict;
use warnings;
our $VERSION  = "2.3";
our $REVISION = sprintf("%d.%02d", q$Revision: 2.6 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Net::STOMP::Client::Auth qw();
use Net::STOMP::Client::Connection qw();
use Net::STOMP::Client::Frame qw(demessagify);
use Net::STOMP::Client::HeartBeat qw(*);
use Net::STOMP::Client::IO qw();
use Net::STOMP::Client::Peer qw();
use Net::STOMP::Client::Receipt qw(*);
use Net::STOMP::Client::Version qw(*);
use No::Worries::Die qw(dief);
use No::Worries::Log qw(log_debug);
use Params::Validate qw(validate :types);
use Time::HiRes qw();

#
# global variables
#

our(
    $Debug,  # default debug string
    %Hook,   # registered frame hooks
    %Setup,  # registered setup helpers
);

#+++############################################################################
#                                                                              #
# timeout handling                                                             #
#                                                                              #
#---############################################################################

#
# check the timeout attribute and convert it to its expanded form
#

sub _check_timeout ($) {
    my($self) = @_;
    my($timeout);

    $timeout = $self->{"timeout"};
    if (defined($timeout)) {
        if (ref($timeout) eq "") {
            # scalar timeout specified -> backward compatibility
            $timeout = {
                "connect"    => $timeout,
                "connected"  => $timeout,
                "disconnect" => $timeout,
                "send"       => undef,
                "receive"    => undef,
            };
        } elsif (ref($timeout) eq "HASH") {
            # hash timeout specified -> use it as is
        } else {
            dief("unexpected timeout: %s", $timeout);
        }
    } else {
        # no timeout specified -> use hard-coded defaults
        $timeout = {
            "connect"    => undef,
            "connected"  => 10,
            "disconnect" => 10,
            "send"       => undef,
            "receive"    => undef,
        };
    }
    $self->{"timeout"} = $timeout;
}

#+++############################################################################
#                                                                              #
# callback handling                                                            #
#                                                                              #
#---############################################################################

#
# user-friendly accessors for the callbacks
#

sub _any_callback ($$;$) {
    my($self, $command, $callback) = @_;

    return($self->{"callback"}{$command}) unless $callback;
    $self->{"callback"}{$command} = $callback;
    return($self);
}

sub connected_callback : method {
    my($self, $callback) = @_;

    return(_any_callback($self, "CONNECTED", $callback));
}

sub error_callback : method {
    my($self, $callback) = @_;

    return(_any_callback($self, "ERROR", $callback));
}

sub message_callback : method {
    my($self, $callback) = @_;

    return(_any_callback($self, "MESSAGE", $callback));
}

sub receipt_callback : method {
    my($self, $callback) = @_;

    return(_any_callback($self, "RECEIPT", $callback));
}

#
# dispatch one received frame, calling the appropriate callback if existing
#

sub dispatch_frame : method {
    my($self, $frame, %option) = @_;
    my($command, $callback);

    $command = $frame->command();
    dief("unexpected %s frame received", $command)
        unless $command =~ /^(CONNECTED|ERROR|MESSAGE|RECEIPT)$/;
    $callback = $self->{"callback"}{$command};
    return() unless $callback;
    return($callback->($self, $frame));
}

#+++############################################################################
#                                                                              #
# hook handling                                                                #
#                                                                              #
#---############################################################################

#
# run all the hooks of the given frame
#

sub _run_hooks ($$) {
    my($self, $frame) = @_;
    my($command);

    $command = $frame->command();
    return unless $Hook{$command};
    foreach my $name (sort(keys(%{ $Hook{$command} }))) {
        $Hook{$command}{$name}->($self, $frame);
    }
}

#
# default CONNECT hook
#

$Hook{"CONNECT"}{"default"} = sub {
    my($self, $frame) = @_;

    # do nothing when only STOMP 1.0 is asked
    return unless grep($_ ne "1.0", $self->accept_version());
    # add the required host header if missing
    $frame->header("host", $self->host())
        unless defined($frame->header("host"));
};

#
# default CONNECTED hook
#

$Hook{"CONNECTED"}{"default"} = sub {
    my($self, $frame) = @_;
    my($value);

    # make sure we receive this frame only once!
    dief("already connected") if $self->{"session"};
    # keep track of session information
    $value = $frame->header("session");
    if ($value) {
        # keep it only if true as it will be used elsewhere to check state
        $self->{"session"} = $value;
    } else {
        # this header is optional but often used so we forge our own if needed
        $self->{"session"} = sprintf("sid-%s", $self->{"id"});
    }
    # keep track of server information
    $value = $frame->header("server");
    $self->{"server"} = $value if defined($value) and length($value);
};

#+++############################################################################
#                                                                              #
# object constructor and destructor                                            #
#                                                                              #
#---############################################################################

#
# FIXME: compatibility hack for Net::STOMP::Client 1.x (to be removed one day)
#

sub _hacknew ($) {
    my($option) = @_;

    # Net::STOMP::Client::Debug::Flags to be replaced by ???
    if ($Net::STOMP::Client::Debug::Flags and not exists($option->{"debug"})) {
        No::Worries::Log::log_filter("debug caller=~^Net::STOMP::Client")
            unless No::Worries::Log::log_wants_debug();
        $option->{"debug"} = "+";
        $option->{"debug"} .= "api+"
            if $Net::STOMP::Client::Debug::Flags & (1 << 0);
        $option->{"debug"} .= "command+"
            if $Net::STOMP::Client::Debug::Flags & (1 << 1);
        $option->{"debug"} .= "header+"
            if $Net::STOMP::Client::Debug::Flags & (1 << 2);
        $option->{"debug"} .= "body+"
            if $Net::STOMP::Client::Debug::Flags & (1 << 3);
        $option->{"debug"} .= "io+"
            if $Net::STOMP::Client::Debug::Flags & (1 << 4);
    }
}

#
# create a new Net::STOMP::Client object and connect to the server (socket level only)
#

my %new_options = (
    "uri"               => { optional => 1, type => SCALAR },
    "host"              => { optional => 1, type => SCALAR },
    "port"              => { optional => 1, type => SCALAR },
    "sockopts"          => { optional => 1, type => HASHREF },
    "debug"             => { optional => 1, type => SCALAR },
    "timeout"           => { optional => 1, type => UNDEF|SCALAR|HASHREF },
    # additional options from the sub-modules
    map($_->(), values(%Setup)),
);

sub new : method {
    my($class, %option, $self, %sockopts, %connopt, $timeout, $socket, $peer);

    $class = shift(@_);
    %option = validate(@_, \%new_options);
    _hacknew(\%option);
    $self = bless(\%option, $class);
    foreach my $name (sort(keys(%Setup))) {
        $Setup{$name}->($self);
    }
    if ($self =~ /\(0x(\w+)\)/) {
        $self->{"id"} =
            sprintf("%s-%x-%x-%x", $1, time(), $$, int(rand(65536)));
    } else {
        dief("unexpected Perl object: %s", $self);
    }
    # check the debug option (and set defaults)
    $self->{"debug"} = $Debug unless exists($self->{"debug"});
    # check the timeout option (and set defaults)
    _check_timeout($self);
    # check the sockopts option
    %sockopts = %{ $self->{"sockopts"} } if $self->{"sockopts"};
    $sockopts{SSL_use_cert} = 1
        if $sockopts{SSL_cert_file} or $sockopts{SSL_key_file};
    unless (exists($sockopts{Timeout})) {
        $timeout = $self->{"timeout"}{"connect"};
        $sockopts{Timeout} = $timeout if $timeout;
    }
    # connect (TCP level only)
    $connopt{"debug"}   = $self->{"debug"} if defined($self->{"debug"});
    $connopt{"host"}    = $self->{"host"}  if defined($self->{"host"});
    $connopt{"port"}    = $self->{"port"}  if defined($self->{"port"});
    $connopt{"uri"}     = $self->{"uri"}   if defined($self->{"uri"});
    $connopt{"sockopt"} = \%sockopts       if keys(%sockopts);
    ($socket, $peer) = Net::STOMP::Client::Connection::new(%connopt);
    # bookkeeping
    $self->{"peer"} = $peer;
    if ($self->uri()) {
        # keep track of the peer this way too...
        $self->{"host"} = $peer->host();
        $self->{"port"} = $peer->port();
    }
    $self->{"io"} = Net::STOMP::Client::IO->new($socket);
    $self->{"serial"} = 1;
    $self->{"callback"} = {
        "ERROR" => sub {
            my($_self, $_frame) = @_;
            dief("unexpected ERROR frame received: %s",
                 $_frame->header("message") || "?");
        },
    };
    # so far so good!
    return($self);
}

#
# close the socket opened by new()
#

sub _close ($) {
    my($self) = @_;
    my($socket, $ignored);

    # try to disconnect gracefully if possible
    $self->disconnect() if $self->{"session"} and $self->{"io"};
    # then destroy the I/O object while keeping a handle on the socket
    $socket = $self->{"io"}{"socket"};
    delete($self->{"io"});
    # then maybe shutdown the socket (http://www.perlmonks.org/?node=108244)
    if ($socket) {
        # call shutdown() without checking if it fails or not since there is
        # not much that can be done in case of failure... unless we use SSL
        # for which it is better not to call shutdown(), see IO::Socket::SSL's
        # man page for more information
        $ignored = shutdown($socket, 2) unless $socket->isa("IO::Socket::SSL");
    }
    # the socket will auto-close when $socket gets destroyed
}

#
# object destructor
#

sub DESTROY {
    my($self) = @_;

    local $@ = ""; # preserve $@!
    _close($self);
}

#+++############################################################################
#                                                                              #
# accessors                                                                    #
#                                                                              #
#---############################################################################

#
# very simple-minded read-only accessors
#

sub host    : method { my($self) = @_; return($self->{"host"});    }
sub peer    : method { my($self) = @_; return($self->{"peer"});    }
sub port    : method { my($self) = @_; return($self->{"port"});    }
sub server  : method { my($self) = @_; return($self->{"server"});  }
sub session : method { my($self) = @_; return($self->{"session"}); }
sub uri     : method { my($self) = @_; return($self->{"uri"});     }

#
# I/O-related read-only accessors
#

sub socket : method {  ## no critic 'ProhibitBuiltinHomonyms'
    my($self) = @_;

    return(undef) unless $self->{"io"};
    return($self->{"io"}{"socket"});
}

sub incoming_buffer_reference : method {
    my($self) = @_;

    return(undef) unless $self->{"io"};
    return(\$self->{"io"}{"incoming_buffer"});
}

sub outgoing_buffer_length : method {
    my($self) = @_;

    return(undef) unless $self->{"io"};
    return($self->{"io"}{"outgoing_length"});
}

#
# return a universal pseudo-unique id to be used in receipts and transactions
#

sub uuid : method {
    my($self) = @_;

    return(sprintf("%s-%x", $self->{"id"}, $self->{"serial"}++));
}

#+++############################################################################
#                                                                              #
# low-level API                                                                #
#                                                                              #
#---############################################################################

#
# FIXME: compatibility hack for Net::STOMP::Client 1.x (to be removed one day)
#

sub _hackopt (@) {
    return("timeout" => $_[0]) if @_ == 1;
    return(@_);
}

#
# helper for the debug and timeout options
#

sub _chkopt ($$%) {
    my($self, $what, %option) = @_;

    # handle the global debug option
    $option{"debug"} = $self->{"debug"}
        unless exists($option{"debug"});
    # handle the global timeout option
    if ($what) {
        $option{"timeout"} = $self->{"timeout"}{$what}
            unless exists($option{"timeout"});
    } else {
        delete($option{"timeout"});
    }
    # so far so good
    return(%option);
}

#
# send data
#

sub send_data : method {
    my($self, %option);

    $self = shift(@_);
    %option = _hackopt(@_);
    # check that the I/O object is still usable
    dief("lost connection") unless $self->{"io"};
    # just do it
    return($self->{"io"}->send_data(_chkopt($self, "send", %option)));
}

#
# receive data
#

sub receive_data : method {
    my($self, %option);

    $self = shift(@_);
    %option = _hackopt(@_);
    # check that the I/O object is still usable
    dief("lost connection") unless $self->{"io"};
    # just do it
    return($self->{"io"}->receive_data(_chkopt($self, "receive", %option)));
}

#
# queue the given frame
#

sub queue_frame : method {
    my($self, $frame, %option) = @_;
    my($data);

    # check that the I/O object is still usable
    dief("lost connection") unless $self->{"io"};
    if (ref($frame)) {
        # a real frame
        _run_hooks($self, $frame);
        # encode it
        $option{"version"} = $self->{"version"} if $self->{"version"};
        $data = $frame->encode(_chkopt($self, undef, %option));
    } else {
        # handle already encoded frames (including the special NOOP frame)
        $data = \$frame;
    }
    # queue what we have
    return($self->{"io"}->queue_data($data));
}

#
# send the given frame (i.e. queue and then send _all_ data)
#

sub send_frame : method {
    my($self, $frame, %option);

    $self = shift(@_);
    $frame = shift(@_);
    %option = _hackopt(@_);
    # queue the frame
    $self->queue_frame($frame, %option);
    # send queued data
    $self->send_data(%option);
    # make sure we did send _all_ data
    dief("could not send all data!") if $self->outgoing_buffer_length();
}

#
# try to receive one frame
#

sub receive_frame : method {
    my($self, %option, $maxtime, %decopt, $bufref, $frame, $remaining);

    $self = shift(@_);
    %option = _hackopt(@_);
    # keep track of time
    $option{"timeout"} = $self->{"timeout"}{"receive"}
        unless exists($option{"timeout"});
    $maxtime = Time::HiRes::time() + $option{"timeout"}
        if defined($option{"timeout"});
    # first try to use the incoming buffer
    %decopt = ("state" => {});
    $decopt{"version"} = $self->{"version"} if $self->{"version"};
    $decopt{"debug"} = $option{"debug"} if exists($option{"debug"});
    $decopt{"debug"} = $self->{"debug"} unless exists($decopt{"debug"});
    $bufref = $self->incoming_buffer_reference();
    $frame = Net::STOMP::Client::Frame::decode($bufref, %decopt);
    # if this fails, try to receive more data until we are done
    while (not $frame) {
        # where are we with time?
        if (not defined($option{"timeout"})) {
            # timeout = undef => blocking
        } elsif ($option{"timeout"}) {
            # timeout > 0 => try once more if not too late
            $remaining = $maxtime - Time::HiRes::time();
            return(0) if $remaining <= 0;
            $option{"timeout"} = $remaining;
        } else {
            # timeout = 0 => non-blocking
        }
        # receive more data
        return() unless $self->receive_data(%option);
        # do we have a complete frame now?
        $frame = Net::STOMP::Client::Frame::decode($bufref, %decopt);
    }
    # so far so good
    _run_hooks($self, $frame) if $frame;
    return($frame);
}

#
# wait for new frames and dispatch them
#

sub wait_for_frames : method {
    my($self, %option) = @_;
    my($callback, $maxtime, $frame, $result, $remaining, %recvopt);

    $callback = $option{callback};
    %recvopt = ();
    $recvopt{"debug"} = $option{"debug"} if exists($option{"debug"});
    $recvopt{"debug"} = $self->{"debug"} unless exists($recvopt{"debug"});
    if (defined($option{"timeout"})) {
        $maxtime = Time::HiRes::time() + $option{"timeout"};
        $recvopt{"timeout"} = $option{"timeout"};
    }
    while (1) {
        $frame = $self->receive_frame(%recvopt);
        if ($frame) {
            # we always call first the per-command callback
            $self->dispatch_frame($frame);
            if ($callback) {
                # user callback: we stop if callback returns error or true or if once
                $result = $callback->($self, $frame);
                return($result)
                    if not defined($result) or $result or $option{once};
            } else {
                # no user callback: we stop on the first frame and return it
                return($frame);
            }
        }
        # we check if we exceeded the timeout
        if (defined($maxtime)) {
            $remaining = $maxtime - Time::HiRes::time();
            return(0) if $remaining <= 0;
            $recvopt{"timeout"} = $remaining;
        }
    }
    # not reached...
    die("ooops!");
}

#
# convenient shortcuts
#

sub queue_message : method {
    my($self, $message, %option) = @_;

    return($self->queue_frame(demessagify($message), %option));
}

sub send_message : method {
    my($self, $message, %option) = @_;

    return($self->send_frame(demessagify($message), %option));
}

#+++############################################################################
#                                                                              #
# high-level API (each method matches a client frame command)                  #
#                                                                              #
#---############################################################################

#
# check the method invocation for the high-level API (except connect)
#

sub _check_api ($$$$) {
    my($self, $name, $header, $option) = @_;
    my($debug);

    $option->{debug} = delete($header->{debug})
        if exists($header->{debug});
    $option->{timeout} = delete($header->{timeout})
        if exists($header->{timeout});
    $debug = exists($option->{debug}) ? $option->{debug} : $self->{debug};
    log_debug("%s->%s()", "$self", $name)
        if $debug and $debug =~ /\b(api|all)\b/;
    if ($name eq "connect") {
        dief("already connected") if $self->{"session"};
    } else {
        dief("not connected") unless $self->{"session"};
    }
}

#
# connect to server
#

sub connect : method {  ## no critic 'ProhibitBuiltinHomonyms'
    my($self, %header) = @_;
    my(%option, $frame);

    _check_api($self, "connect", \%header, \%option);
    # send a CONNECT frame
    $frame = Net::STOMP::Client::Frame->new(
        command => "CONNECT",
        headers => \%header,
    );
    $self->send_frame($frame, %option);
    # wait for the CONNECTED frame to come back
    $self->wait_for_frames(
        callback => sub { return($self->{"session"}) },
        timeout  => $self->{"timeout"}{"connected"},
    );
    dief("no CONNECTED frame received") unless $self->{"session"};
    return($self);
}

#
# disconnect from server
#

sub disconnect : method {
    my($self, %header) = @_;
    my(%option, $frame);

    _check_api($self, "disconnect", \%header, \%option);
    # send a DISCONNECT frame
    $frame = Net::STOMP::Client::Frame->new(
        command => "DISCONNECT",
        headers => \%header,
    );
    $self->send_frame($frame, %option);
    # if a receipt has been given, wait for it!
    if ($header{receipt}) {
        # at this point, the server may abruptly close the socket without
        # lingering so we ignore I/O errors while we wait for the receipt
        # to come back
        eval {
            $self->wait_for_frames(
                timeout  => $self->{"timeout"}{"disconnect"},
                callback => sub {
                    return(! $self->{"receipts"}{$header{receipt}});
                },
            );
        };
    }
    # additional bookkeeping
    delete($self->{"peer"});
    delete($self->{"session"});
    _close($self);
    return($self);
}

#
# subscribe to something
#

sub subscribe : method {
    my($self, %header) = @_;
    my(%option, $frame);

    _check_api($self, "subscribe", \%header, \%option);
    # send a SUBSCRIBE frame
    $frame = Net::STOMP::Client::Frame->new(
        command => "SUBSCRIBE",
        headers => \%header,
    );
    $self->send_frame($frame, %option);
    return($self);
}

#
# unsubscribe from something
#

sub unsubscribe : method {
    my($self, %header) = @_;
    my(%option, $frame);

    _check_api($self, "unsubscribe", \%header, \%option);
    # send an UNSUBSCRIBE frame
    $frame = Net::STOMP::Client::Frame->new(
        command => "UNSUBSCRIBE",
        headers => \%header,
    );
    $self->send_frame($frame, %option);
    return($self);
}

#
# send a message somewhere
#

sub send : method {  ## no critic 'ProhibitBuiltinHomonyms'
    my($self, %header) = @_;
    my(%option, %frameopt, $frame);

    _check_api($self, "send", \%header, \%option);
    # we can optionally give a message body here
    $frameopt{body} = delete($header{body})
        if defined($header{body});
    $frameopt{body_reference} = delete($header{body_reference})
        if defined($header{body_reference});
    # send a SEND frame
    $frame = Net::STOMP::Client::Frame->new(%frameopt,
        command => "SEND",
        headers => \%header,
    );
    $self->send_frame($frame, %option);
    return($self);
}

#
# acknowledge the reception of a message
#

sub ack : method {
    my($self, %header) = @_;
    my(%option, $frame, $value);

    _check_api($self, "ack", \%header, \%option);
    # we can optionally give a MESSAGE frame here
    if ($header{frame}) {
        $value = $header{frame}->header("message-id");
        $header{"message-id"} = $value if defined($value);
        $value = $header{frame}->header("subscription");
        $header{"subscription"} = $value if defined($value);
        $value = $header{frame}->header("ack");
        $header{"id"} = $value if defined($value);
        delete($header{frame});
    }
    # send an ACK frame
    $frame = Net::STOMP::Client::Frame->new(
        command => "ACK",
        headers => \%header,
    );
    $self->send_frame($frame, %option);
    return($self);
}

#
# acknowledge the rejection of a message
#

sub nack : method {
    my($self, %header) = @_;
    my(%option, $frame, $value);

    _check_api($self, "nack", \%header, \%option);
    dief("unsupported NACK frames for STOMP 1.0")
        if $self->{"version"} eq "1.0";
    # we can optionally give a MESSAGE frame here
    if ($header{frame}) {
        $value = $header{frame}->header("message-id");
        $header{"message-id"} = $value if defined($value);
        $value = $header{frame}->header("subscription");
        $header{"subscription"} = $value if defined($value);
        $value = $header{frame}->header("ack");
        $header{"id"} = $value if defined($value);
        delete($header{frame});
    }
    # send an NACK frame
    $frame = Net::STOMP::Client::Frame->new(
        command => "NACK",
        headers => \%header,
    );
    $self->send_frame($frame, %option);
    return($self);
}

#
# begin/start a transaction
#

sub begin : method {
    my($self, %header) = @_;
    my(%option, $frame);

    _check_api($self, "begin", \%header, \%option);
    # send a BEGIN frame
    $frame = Net::STOMP::Client::Frame->new(
        command => "BEGIN",
        headers => \%header,
    );
    $self->send_frame($frame, %option);
    return($self);
}

#
# commit a transaction
#

sub commit : method {
    my($self, %header) = @_;
    my(%option, $frame);

    _check_api($self, "commit", \%header, \%option);
    # send a COMMIT frame
    $frame = Net::STOMP::Client::Frame->new(
        command => "COMMIT",
        headers => \%header,
    );
    $self->send_frame($frame, %option);
    return($self);
}

#
# abort/rollback a transaction
#

sub abort : method {
    my($self, %header) = @_;
    my(%option, $frame);

    _check_api($self, "abort", \%header, \%option);
    # send a ABORT frame
    $frame = Net::STOMP::Client::Frame->new(
        command => "ABORT",
        headers => \%header,
    );
    $self->send_frame($frame, %option);
    return($self);
}

#
# send an empty/noop frame (in fact, a single newline byte)
#

sub noop : method {
    my($self, %header) = @_;
    my(%option, $frame);

    _check_api($self, "noop", \%header, \%option);
    # there is no NOOP frame (yet) so we simply send a newline
    $frame = "\n";
    $self->send_frame($frame, %option);
    return($self);
}

1;

__END__

=head1 NAME

Net::STOMP::Client - STOMP object oriented client module

=head1 SYNOPSIS

  #
  # simple producer
  #

  use Net::STOMP::Client;

  $stomp = Net::STOMP::Client->new(host => "127.0.0.1", port => 61613);
  $stomp->connect(login => "guest", passcode => "guest");
  $stomp->send(destination => "/queue/test", body => "hello world!");
  $stomp->disconnect();

  #
  # consumer with client side acknowledgment
  #

  use Net::STOMP::Client;

  $stomp = Net::STOMP::Client->new(host => "127.0.0.1", port => 61613);
  $stomp->connect(login => "guest", passcode => "guest");
  # declare a callback to be called for each received message frame
  $stomp->message_callback(sub {
      my($self, $frame) = @_;
      $self->ack(frame => $frame);
      printf("received: %s\n", $frame->body());
      return($self);
  });
  # subscribe to the given queue
  $stomp->subscribe(
      destination => "/queue/test",
      id          => "testsub",          # required in STOMP 1.1
      ack         => "client",           # client side acknowledgment
  );
  # wait for a specified message frame
  $stomp->wait_for_frames(callback => sub {
      my($self, $frame) = @_;
      if ($frame->command() eq "MESSAGE") {
          # stop waiting for new frames if body is "quit"
          return(1) if $frame->body() eq "quit";
      }
      # continue to wait for more frames
      return(0);
  });
  $stomp->unsubscribe(id => "testsub");
  $stomp->disconnect();

=head1 DESCRIPTION

This module provides an object oriented client interface to interact with
servers supporting STOMP (Streaming Text Orientated Messaging Protocol). It
supports the major features of modern messaging brokers: SSL, asynchronous
I/O, receipts and transactions.

=head1 CONSTRUCTOR

The new() method can be used to create a Net::STOMP::Client object that will
later be used to interact with a server. The following attributes are
supported:

=over

=item C<accept_version>

the STOMP version to use (string) or versions to use (reference to a
list of strings); this defaults to the list of all supported versions;
see L<Net::STOMP::Client::Version> for more information

=item C<version>

this attribute is obsolete and should not be used anymore, use
C<accept_version> instead; it is left here only to provide backward
compatibility with Net::STOMP::Client 1.x

=item C<uri>

the Uniform Resource Identifier (URI) specifying where the STOMP service is
and how to connect to it, this can be for instance C<tcp://msg01:6163> or
something more complex, see L<Net::STOMP::Client::Connection> for more
information

=item C<host>

the server name or IP address

=item C<port>

the port number of the STOMP service

=item C<auth>

the authentication credential(s) to use, see L<Net::STOMP::Client::Auth> for
more information

=item C<sockopts>

arbitrary socket options (as a hash reference) that will be passed to
IO::Socket::INET->new() or IO::Socket::SSL->new()

=item C<client_heart_beat>

the desired client-side heart-beat setting, see
L<Net::STOMP::Client::HeartBeat> for more information

=item C<server_heart_beat>

the desired server-side heart-beat setting, see
L<Net::STOMP::Client::HeartBeat> for more information

=item C<debug>

the debugging flags for this object, see the L</"DEBUGGING"> section for
more information

=item C<timeout>

the maximum time (in seconds) for various operations, see the L</"TIMEOUTS">
section for more information

=back

Upon object creation, a TCP connection is made to the server but no data
(i.e. STOMP frame) is exchanged.

=head2 DEBUGGING

Net::STOMP::Client uses L<No::Worries::Log>'s log_debug() to log debugging
information. In addition, to avoid useless data massaging, it also uses a
debug string to specify what will be logged using log_debug().

The debug string should contain a list of words describing what to log. For
instance, "io" logs I/O information while "io connection" logs both I/O and
connection information.

Here are the supported debug words that can be used:

=over

=item C<all>

everything

=item C<api>

high-level API calls

=item C<body>

frame bodies

=item C<command>

frame commands

=item C<connection>

connection establishment

=item C<header>

frame headers

=item C<io>

I/O as bytes sent/received

=back

To enable debugging, you must first configure L<No::Worries::Log> so that it
indeed reports debugging messages. This can be done with something like:

  log_filter("debug");

or, to enable logging only from Net::STOMP::Client modules:

  log_filter("debug caller=~^Net::STOMP::Client");

See the L<No::Worries::Log> documentation for more information.

Then, you have to tell Net::STOMP::Client to indeed log what you want to
see. This can be done globally for all connections by setting the global
variable $Net::STOMP::Client::Debug:

  $Net::STOMP::Client::Debug = "connection api";

or per connection via the new() method:

  $stomp = Net::STOMP::Client->new(
      uri   => "stomp://mybroker:6163",
      debug => "connection api",
  );

=head2 TIMEOUTS

By default, when sending STOMP frames, the module waits until the frame
indeed has been sent (from the socket point of view). In case the server is
stuck or unusable, the module can therefore hang.

When creating the Net::STOMP::Client object, you can pass a C<timeout>
attribute to better control how certain operations handle timeouts.

This attribute should contain a reference to hash with the following keys:

=over

=item connect

TCP-level timeout that will be given to the underlying L<IO::Socket::INET>
or L<IO::Socket::SSL> object (default: none)

=item connected

timeout used while waiting for the initial C<CONNECTED> frame from the broker
(default: 10)

=item disconnect

timeout specifying how long the disconnect() method should wait for a
C<RECEIPT> frame back in case the C<DISCONNECT> frame contained a receipt
(default: 10)

=item receive

timeout used while trying to receive any frame (default: none)

=item send

timeout used while trying to send any frame (default: none)

=back

All values are in seconds. No timeout means wait until the operation
succeeds.

As a shortcut, the C<timeout> attribute can also be a scalar. In this case,
only the C<connect> and C<connected> operations use this value.

=head1 STOMP METHODS

With a Net::STOMP::Client object, the following methods can be used to
interact with the server. They match one-to-one the different commands that
a client frame can hold:

=over

=item connect()

connect to server

=item disconnect()

disconnect from server

=item subscribe()

subscribe to something

=item unsubscribe()

unsubscribe from something

=item send()

send a message somewhere

=item ack()

acknowledge the reception of a message

=item nack()

acknowledge the rejection of a message (STOMP >=1.1 only)

=item begin()

begin/start a transaction

=item commit()

commit a transaction

=item abort()

abort/rollback a transaction

=back

All these methods can receive options that will be passed directly as frame
headers. For instance:

  $stomp->subscribe(
      destination => "/queue/test",
      id          => "testsub",
      ack         => "client",
  );

Some methods also support additional options:

=over

=item send()

C<body> or C<body_reference>: holds the body or body reference of the
message to be sent

=item ack()

C<frame>: holds the C<MESSAGE> frame object to ack

=item nack()

C<frame>: holds the C<MESSAGE> frame object to nack

=back

Finally, all methods support C<debug> and C<timeout> options that will be
given to the send_frame() method called internally to send the crafted
frame.

=head1 OTHER METHODS

In addition to the STOMP methods, the following ones are also available:

=over

=item new(OPTIONS)

return a new Net::STOMP::Client object (constructor)

=item peer()

return a L<Net::STOMP::Client::Peer> object containing information about the
connected STOMP server

=item socket()

return the file handle of the socket connecting the client and the server

=item server()

return the server header seen on the C<CONNECTED> frame (if any)

=item session()

return the session identifier if connected or false otherwise

=item uuid()

return a universal pseudo-unique identifier to be used for instance in
receipts and transactions

=item wait_for_frames()

wait for frames coming from the server, see the next section for more
information

=item noop([timeout => TIMEOUT])

send an empty/noop frame i.e. a single newline byte, using send_frame()
underneath

=back

=head1 CALLBACKS

Since STOMP is asynchronous (for instance, C<MESSAGE> frames could be sent
by the server at any time), Net::STOMP::Client uses callbacks to handle
frames. There are in fact two levels of callbacks.

First, there are per-command callbacks that will be called each time a frame
is handled (via the internal dispatch_frame() method). Net::STOMP::Client
implements default callbacks that should be sufficient for all frames except
C<MESSAGE> frames, which should really be handled by the coder.  These
callbacks should return undef on error, something else on success.

Here is an example with a callback counting the messages received:

  $stomp->message_callback(sub {
      my($self, $frame) = @_;
      $MessageCount++;
      return($self);
  });

Here are the methods that can be used to get or set these per-command
callbacks:

=over

=item connected_callback([SUBREF])

=item error_callback([SUBREF])

=item message_callback([SUBREF])

=item receipt_callback([SUBREF])

=back

These callbacks are somehow global and it is good practice not to change
them during a session. If you do not need a global message callback, you can
supply the dummy:

  $stomp->message_callback(sub { return(1) });

Then, the wait_for_frames() method takes an optional callback argument
holding some code to be called for each received frame, after the
per-command callback has been called. This can be seen as a local callback,
only valid for the call to wait_for_frames(). This callback must return
undef on error, false if more frames are expected or true if
wait_for_frames() can now stop waiting for new frames and return.

Here are all the options that can be given to wait_for_frames():

=over

=item callback

code to be called for each received frame (see above)

=item timeout

time to wait before giving up, undef means wait forever, this is the default

=item once

wait only for one frame, within the given timeout

=back

The return value of wait_for_frames() can be: false if no suitable frame has
been received, the received frame if there is no user callback or the user
callback return value otherwise.

=head1 TRANSACTIONS

Here is an example using transactions:

  # create a unique transaction id
  $tid = $stomp->uuid();
  # begin the transaction
  $stomp->begin(transaction => $tid);
  # send two messages as part of this transaction
  $stomp->send(
      destination => "/queue/test1",
      body        => "message 1",
      transaction => $tid,
  );
  $stomp->send(
      destination => "/queue/test2",
      body        => "message 2",
      transaction => $tid,
  );
  # commit the transaction
  $stomp->commit(transaction => $tid);

=head1 LOW-LEVEL API

It should be enough to use the high-level API and use, for instance, the
send() method to create a C<MESSAGE> frame and send it in one go.

If you need lower level interaction, you can manipulate frames with the
L<Net::STOMP::Client::Frame> module.

You can also use:

=over

=item $stomp->dispatch_frame(FRAME, [OPTIONS])

dispatch one received frame by calling the appropriate callback;
supported options: C<debug>

=item $stomp->send_frame(FRAME, [OPTIONS])

try to send the given frame object;
supported options: C<timeout> and C<debug>

=item $stomp->send_message(MESSAGE, [OPTIONS])

identical to send_frame() but taking a L<Messaging::Message> object

=item $stomp->queue_frame(FRAME, [OPTIONS])

add the given frame to the outgoing buffer queue;
supported options: C<debug>

=item $stomp->queue_message(MESSAGE, [OPTIONS])

identical to queue_frame() but taking a L<Messaging::Message> object

=item $stomp->send_data([OPTIONS])

send all the queued data;
supported options: C<timeout> and C<debug>

=item $stomp->receive_frame([OPTIONS])

try to receive a frame;
supported options: C<timeout> and C<debug>

=item $stomp->receive_data([OPTIONS])

try to receive data (this data will be appended to the incoming buffer);
supported options: C<timeout> and C<debug>

=item $stomp->outgoing_buffer_length()

return the length (in bytes) of the outgoing buffer

=item $stomp->incoming_buffer_reference()

return a reference to the incoming buffer

=back

In these methods, the C<timeout> option can either be C<undef> (meaning
block until it's done) or C<0> (meaning do not block at all) or a positive
number (meaning block at most this number of seconds).

=head1 COMPATIBILITY

This module has been successfully tested against ActiveMQ, Apollo, HornetQ
and RabbitMQ brokers.

See L<Net::STOMP::Client::Version> for the list of supported STOMP protocol
versions.

=head1 SEE ALSO

L<Messaging::Message>,
L<Net::STOMP::Client::Auth>,
L<Net::STOMP::Client::Connection>,
L<Net::STOMP::Client::Frame>,
L<Net::STOMP::Client::HeartBeat>,
L<Net::STOMP::Client::Peer>,
L<Net::STOMP::Client::Receipt>,
L<Net::STOMP::Client::Tutorial>,
L<Net::STOMP::Client::Version>,
L<No::Worries::Log>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2010-2017
