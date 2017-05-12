# ======================================================================
#
# Copyright (C) 2000-2001 Paul Kulchenko (paulclinger@yahoo.com)
# SOAP::Lite is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Id: MQ.pm 353 2010-03-17 21:08:34Z kutterma $
#
# ======================================================================

package SOAP::Transport::MQ;

use strict;
use warnings;
our $VERSION = 0.712;

use MQClient::MQSeries;
use MQSeries::QueueManager;
use MQSeries::Queue;
use MQSeries::Message;

use URI;
use URI::Escape;
use SOAP::Lite;

sub requestqueue {
    my $self = shift;
    $self = $self->new() if not ref $self;
    if (@_) {
        $self->{_requestqueue} = shift;
        return $self;
    }
    return $self->{_requestqueue};
}

sub replyqueue {
    my $self = shift;
    $self = $self->new() if not ref $self;
    if (@_) {
        $self->{_replyqueue} = shift;
        return $self;
    }
    return $self->{_replyqueue};
}

# ======================================================================

package URI::mq;    # ok, lets do 'mq://' scheme
our $VERSION = 0.712;
require URI::_server;
require URI::_userpass;

@URI::mq::ISA = qw(URI::_server URI::_userpass);

# mq://user@host:port?Channel=A;QueueManager=B;RequestQueue=C;ReplyQueue=D
# ^^   ^^^^ ^^^^ ^^^^ ^^^^^^^^^ ^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^ ^^^^^^^^^^^^

# ======================================================================

package SOAP::Transport::MQ::Client;
our $VERSION = 0.712;
use vars qw(@ISA);
@ISA = qw(SOAP::Client SOAP::Transport::MQ);

use MQSeries qw(:constants);

sub DESTROY {
    SOAP::Trace::objects('()');
}

sub new {
    my $class = shift;

    return $class if ref $class;

    my ( @params, @methods );
    while (@_) {
        $class->can( $_[0] )
          ? push( @methods, shift() => shift )
          : push( @params,  shift );
    }
    my $self = bless {@params} => $class;
    while (@methods) {
        my ( $method, $params ) = splice( @methods, 0, 2 );
        $self->$method( ref $params eq 'ARRAY' ? @$params : $params );
    }
    SOAP::Trace::objects('()');

    return $self;
}

sub endpoint {
    my $self = shift;

    return $self->SUPER::endpoint unless @_;

    my $endpoint = shift;

    # nothing to do if new endpoint is the same as the current one
    {
        no warnings qw(uninitialized);
        return $self if $self->SUPER::endpoint eq $endpoint;
    }
    my $uri        = URI->new($endpoint);
    my %parameters = (
        %$self,
        map { URI::Escape::uri_unescape($_) }
          map { split /=/, $_, 2 } split /[&;]/,
        $uri->query || ''
    );

    $ENV{MQSERVER} = sprintf "%s/TCP/%s(%s)", $parameters{Channel},
      $uri->host, $uri->port
      if $uri->host;

    my $qmgr =
      MQSeries::QueueManager->new( QueueManager => $parameters{QueueManager} )
      || die "Unable to connect to queue manager $parameters{QueueManager}\n";

    $self->requestqueue(
        MQSeries::Queue->new(
            QueueManager => $qmgr,
            Queue        => $parameters{RequestQueue},
            Mode         => 'output',
          )
          || die "Unable to open $parameters{RequestQueue}\n"
    );

    $self->replyqueue(
        MQSeries::Queue->new(
            QueueManager => $qmgr,
            Queue        => $parameters{ReplyQueue},
            Mode         => 'input',
          )
          || die "Unable to open $parameters{ReplyQueue}\n"
    );

    return $self->SUPER::endpoint($endpoint);
}

sub send_receive {
    my ( $self,     %parameters ) = @_;
    my ( $envelope, $endpoint )   = @parameters{qw(envelope endpoint)};

    $self->endpoint( $endpoint ||= $self->endpoint );

    %parameters = ( %$self, %parameters );
    my $expiry = $parameters{Expiry} || 60000;

    SOAP::Trace::debug($envelope);

    my $request = MQSeries::Message->new(
        MsgDesc => {
            Format => MQFMT_STRING,
            Expiry => $expiry
        },
        Data => $envelope,
    );

    $self->requestqueue->Put( Message => $request )
      || die "Unable to put message to queue\n";

    my $reply =
      MQSeries::Message->new(
        MsgDesc => {CorrelId => $request->MsgDesc('MsgId')}, );

    my $result = $self->replyqueue->Get(
        Message => $reply,
        Wait    => $expiry,
    );

    my $msg = $reply->Data if $result > 0;

    SOAP::Trace::debug($msg);

    my $code =
        $result > 0 ? undef
      : $result < 0 ? 'Timeout'
      :               'Error occured while waiting for response';

    $self->code($code);
    $self->message($code);
    $self->is_success( !defined $code || $code eq '' );
    $self->status($code);

    return $msg;
}

# ======================================================================

package SOAP::Transport::MQ::Server;
our $VERSION = 0.712;
use Carp ();
use vars qw(@ISA $AUTOLOAD);
@ISA = qw(SOAP::Server SOAP::Transport::MQ);

use MQSeries qw(:constants);

sub new {
    my $class = shift;

    return $class if ref $class;

    die "missing parameter (uri)" if not @_;

    my $uri  = URI->new(shift);
    my $self = $class->SUPER::new(@_);

    my %parameters = (
        %$self,
        map { URI::Escape::uri_unescape($_) }
          map { split /=/, $_, 2 } split /[&;]/,
        $uri->query || ''
    );

    $ENV{MQSERVER} = sprintf "%s/TCP/%s(%s)", $parameters{Channel},
      $uri->host, $uri->port
      if $uri->host;

    my $qmgr =
      MQSeries::QueueManager->new( QueueManager => $parameters{QueueManager} )
      || Carp::croak
      "Unable to connect to queue manager $parameters{QueueManager}";

    $self->requestqueue(
        MQSeries::Queue->new(
            QueueManager => $qmgr,
            Queue        => $parameters{RequestQueue},
            Mode         => 'input',
          )
          || Carp::croak "Unable to open $parameters{RequestQueue}"
    );

    $self->replyqueue(
        MQSeries::Queue->new(
            QueueManager => $qmgr,
            Queue        => $parameters{ReplyQueue},
            Mode         => 'output',
          )
          || Carp::croak "Unable to open $parameters{ReplyQueue}"
    );

    return $self;
}

sub handle {
    my $self = shift->new;

    my $msg = 0;
    while (1) {
        my $request = MQSeries::Message->new;

        # nonblock waiting
        $self->requestqueue->Get( Message => $request, )
          || die "Error occured while waiting for requests\n";

        return $msg if $self->requestqueue->Reason == MQRC_NO_MSG_AVAILABLE;

        my $reply = MQSeries::Message->new(
            MsgDesc => {
                CorrelId => $request->MsgDesc('MsgId'),
                Expiry   => $request->MsgDesc('Expiry'),
            },
            Data => $self->SUPER::handle( $request->Data ),
        );

        $self->replyqueue->Put( Message => $reply, )
          || die "Unable to put reply message\n";

        $msg++;
    }
}

# ======================================================================

1;

__END__

=head1 SOAP::Transport::MQ

MQSeries Transport backend for SOAP::Lite

This class provides implementations of both client and server frameworks built
on IBM's Message Queue set of classes. The SOAP objects encapsulate additional
objects from these classes, creating and using them behind the scenes as
needed.

=head3 SOAP::Transport::MQ::Client

Inherits from: L<SOAP::Client>.

The client class provides two methods specific to it, as well as specialized
versions of the endpoint and send_receive methods. It also provides a
localized new method, but the interface isn't changed from the superclass
method. The new methods are:

=over

=item requestqueue

    $client->requestqueue->Put(message => $request);

Manages the MQSeries::Queue object the client uses for enqueuing requests to
the server. In general, an application shouldn't need to directly access this
attribute, let alone set it. If setting it, the new value should be an object
of (or derived from) the MQSeries::Queue class.

=item replyqueue

    $client->replyqueue(MQSeries::Queue->new(%args));

Manages the queue object used for receiving messages back from the designated
server (endpoint). It is also primarily for internal use, though if the
application needs to set it explicitly, the new value should be an object of
(or derived from) the MQSeries::Queue class.

=back

The two previous methods are mainly used by the localized versions of the
methods:

=over

=item endpoint

This accessor method has the same interface as other similar classes but is
worth noting for the internal actions that take place. When the endpoint is
set or changed, the method creates a queue-manager object (from the
MQSeries::QueueManager class) and references this object when creating queues
for replies and requests using the methods described earlier. The URI
structure used with these classes (strings beginning with the characters
mq://user@host:port) contains the information needed for these operations.

=item send_receive

This method uses the same interface as other classes, but makes use of only
the endpoint and envelope keys in the hash-table input data. The endpoint key
is needed only if the client wishes to switch endpoints prior to sending the
message. The message (the value of the envelope key) is inserted into the
queue stored in the requestqueue attribute. The client then waits for a reply
to the message to appear in the queue stored in the replyqueue attribute.

=back

=head3 SOAP::Transport::MQ::Server

Inherits from: L<SOAP::Server>.

The server class also defines requestqueue and replyqueue methods under the
same terms as the client class. Of course, the server reads from the request
queue and writes to the reply queue, the opposite of the client's behavior.
The methods whose functionality are worth noting are:

=over

=item new(URI, optional parameters)

When called, the constructor creates the MQSeries::QueueManager object and
the two MQSeries::Queue objects, similar to what the client does inside its
endpoint method. Like the Jabber server described earlier, the first argument
to this constructor is expected to be the URI that describes the server
itself. The remainder of the arguments are treated as key/value pairs, as
with other class constructors previously described.

=item handle

When this method is called, it attempts to read a pending message from the
request-queue stored on the requestqueue attribute. The message itself is
passed to the handle method of the superclass, and the result from that
operation is enqueued to the replyqueue object. This process loops until
no more messages are present in the request queue. The return value is the
number of messages processed. The reads from the request queue are done in a
nonblocking fashion, so if there is no message pending, the method
immediately returns with a value of zero.

=back

=head1 BUGS

This module is currently unmaintained, so if you find a bug, it's yours -
you probably have to fix it yourself. You could also become maintainer -
just send an email to mkutter@cpan.org

=head1 AUTHORS

Paul Kulchenko (paulclinger@yahoo.com)

Randy J. Ray (rjray@blackperl.com)

Byrne Reese (byrne@majordojo.com)

Martin Kutter (martin.kutter@fen-net.de)

=cut
