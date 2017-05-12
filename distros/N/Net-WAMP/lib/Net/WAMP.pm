package Net::WAMP;

our $VERSION = '0.01';

=encoding utf-8

=head1 NAME

Net::WAMP - Support for Web Application Messaging Protocol (“WAMP”)

=head1 SYNOPSIS

A simple client:

    package My_Client;

    use strict; use warnings;

    #Your client can implement any or all of the following role classes:
    use parent (
        #“Producer” roles:
        'Net::WAMP::Role::Publisher',
        'Net::WAMP::Role::Callee',

        #“Consumer” roles:
        'Net::WAMP::Role::Subscriber',
        'Net::WAMP::Role::Caller',
    );

    #for the Subscriber class
    sub on_EVENT {
        my ($self, $msg_obj, $topic) = @_;
        ...
    }

    #for the Callee class
    sub on_INVOCATION {
        my ($self, $msg_obj, $procedure, $worker_obj) = @_;
        ...
    }

    #----------------------------------------------------------------------

    package main;

    my $client = My_Client->new(
        serialization => 'json',

        #Output this way:
        on_send => sub {
            my $serialized_bytes = shift;
            _send_serialized($serialized_bytes);
        },
    );

    $client->send_HELLO( 'my-realm' );

    #Input this way:
    my $msg = $client->handle_message( _read_from_transport() );

    #Do some sort of validation of the WELCOME message here …

    $client->send_PUBLISH(
        {},
        'com.haha.demo.chat',
        [ 'This is a message.' ],
    );

=head1 DESCRIPTION

This distribution provides support in Perl for the
L<Web Application Messaging Protocol (WAMP)|http://wamp-proto.org/>.

=head1 ALPHA STATUS

B<CAVEAT EMPTOR!>

The WAMP standard itself is not yet finalized, so any implementations are
by definition subject to change.
(L<The current specification|http://wamp-proto.org/spec/> is itself a
significant revision
of an earlier proposed standard.) That said, the details of it should be
pretty stable by this point, so changes should be relatively minor.

Net::WAMP will attempt to accommodate any future updates to the protocol
with backward compatibility; however, at this point there are NO guarantees,
and you should absolutely check the changelog before updating.

Several of the specification’s “Advanced” features are marked as
being in less-than-stable states. This implementation will probably hold
off on implementing those as a result; however, pull requests will be
considered.

Net::WAMP’s design aims to implement only WAMP and to be agnostic about
anything else: which way you do transport, what you do with your messages,
etc. As a consequence, its footprint is pretty light, though you’ll likely
want for other modules (e.g., L<Net::WebSocket>) to implement transport.
This distribution does include an implementation of
L<WAMP’s RawSocket protocol|http://wamp-proto.org/static/rfc/draft-oberstet-hybi-crossbar-wamp.html#rfc.section.14.5.3.1>;
however, nothing compels you to use this particular implementation.
If you wanted to use your own (maybe using XS?), nothing prevents you, and
you should have minimal, if any, unused code loaded.

You may get a better sense of how to use Net::WAMP by looking at the
distribution’s example scripts; however, for the sake of completeness,
here is the formal documentation. The following assumes that you are already
familiar with WAMP; consult the specification for more background if you
need it.

There have been several internal design changes over the course of
development, some of which the documentation may not reflect.
Please L<open tasks|https://github.com/FGasper/p5-Net-WAMP> for any
inconsistencies you note between the documentation and the actual code.

=head1 WORKFLOW

The basic workflow is:

=over

=item 0) Define your WAMP role class.

=item 1) Set up your transport layer (e.g., WebSocket).

=item 2) Instantiate your WAMP role class, with the appropriate
serialization and C<on_send> callback.

=item 3) WAMP handshake (HELLO/WELCOME)

=back

… then just sending and receiving messages.

=head1 ROLE CLASSES

The role classes contain the role-specific logic for packaging and parsing
WAMP messages. These are the centerpiece of your WAMP interactions.

Your application should create a subclass of one or more of the provided roles.
Use multiple inheritance to govern which roles your subclass
will execute.
An instance of that subclass defines your application’s WAMP activity.
Such a subclass must implement either client or router roles, but NOT both:

=head3 Client Roles:

=over

=item * L<Net::WAMP::Role::Publisher>

=item * L<Net::WAMP::Role::Subscriber>

=item * L<Net::WAMP::Role::Caller>

=item * L<Net::WAMP::Role::Callee>

=back

=head3 Router Roles:

=over

=item * L<Net::WAMP::Role::Broker>

=item * L<Net::WAMP::Role::Dealer>

=back

=head1 COMMON METHODS: CLIENTS

Each client class implements the following methods:

=head2 I<CLASS>->new( %OPTS )

… with %OPTS being:

=over

=item * C<on_send> (required): A coderef that gets called for each message
the client will send. This coderef must send this message to whatever transport
layer (e.g., WebSocket, RawSocket, …) you’re using.

=item * C<serialization> (optional): C<json> is the default; C<msgpack>
is also an option.

=back

=head2 I<OBJ>->send_HELLO( REALM, AUXILIARY_HR )

Sends a HELLO message to the given REALM. AUXILIARY_HR is optional and,
if given, will be merged with the features data for this framework.

=head2 I<OBJ>->send_GOODBYE( AUXILIARY_HR, REASON )

=head2 I<OBJ>->send_ABORT( AUXILIARY_HR, REASON )

See the WAMP specification for what these do.

=head2 I<OBJ>->handle_message( SERIALIZED_MESSAGE )

For each message you receive from your transport layer, send the message
payload into this method. For example, if you’re using WebSocket, the WebSocket
message’s payload is what this function should receive. This method will
convert this raw payload into a message object (i.e., an instance of a
subclass of L<Net::WAMP::Message>), which will be handled internally and
send to whatever handler your role class might define for that message.

=head1 CLIENT SUBCLASS INTERFACE

=head2 I<OBJ>->REQUIRE_STRICT_PEER_ROLES()

This method governs whether Net::WAMP will require a peer to disclose its
role correctly in order to send a message to it. Not all WAMP implementations
advertise roles according to the WAMP specification in their HELLO/WELCOME,
so this can be useful for accommodating such libraries.

=head1 WRITING A ROUTER

The bad news is: WAMP Routers are more complicated than Clients. They all
but guarantee a
requirement for multiplexed I/O, and they have to maintain state, manage
access control, etc.

The good news is: Net::WAMP takes care of lots of that for you! So once
you’ve got your transport set up, Router behavior becomes reasonably
straightforward.

Net::WAMP does NOT implement everything you need to build a Router; instead,
it implements just the WAMP parts. You can decide for yourself how you want
to do things like I/O.

The router workflow is:

=over

=item 1) Accept a new connection.

=item 2) Set up transport with this new connection.

=item 3) Create a L<Net::WAMP::Session> object with the new connection.
(The client should have told you by now which serialization it wants.)

=item 4) Now C<handle_message()>, essentially the same as with the Client.

=head1 COMMON METHODS: ROUTER

Router methods mirror their client counterparts, but generally with the
addition of a L<Net::WAMP::Session> object:

=head2 I<CLASS>->new()

Currently this takes no parameters.

=head2 I<OBJ>->handle_message( SESSION_OBJ, SERIALIZED_MESSAGE )

Just like its client counterpart, but the SESSION_OBJ tells the Router
where the message came from.

=head2 I<OBJ>->send_GOODBYE( SESSION_OBJ, AUXILIARY_HR, REASON )

=head2 I<OBJ>->send_ABORT( SESSION_OBJ, AUXILIARY_HR, REASON )

See the WAMP specification for what these do.

=head2 I<OBJ>->forget_session( SESSION_OBJ )

“Forget”s a session object by removing all traces of it from the
Router object internals. You’ll probably only do this when a WAMP
session has ended.

=head1 ROLE MESSAGE HANDLERS

Each role has specific message types that it receives; for
example, a Subscriber receives EVENT messages. If you write a Subscriber
application, you’ll probably need to consume these messages. To do this,
define an C<on_EVENT()> method. Likewise, a Caller class will probably
define an C<on_RESULT()> method, just as a Callee will define
C<on_INVOCATION>.

B<ERROR messages> are special: use methods C<on_ERROR_CALL()>, etc.

Most handlers just receive the appropriate
Message object (more on these later); see the individual modules’
documentation for variances from that pattern.

Note that Router classes (Dealer and Broker) have a special C<get_session()>
method that returns the Session object for the current message.

=head1 I/O

To maximize flexibility, Net::WAMP does not read or write directly to
filehandles; instead, it accepts serialized messages (via the
C<handle_message()> method) and sends serialized messaged to a callback
function (C<on_send>).

For example, if you’re doing WAMP over WebSocket, you’ll feed each
WebSocket message’s payload into C<handle_message()> and set
C<on_send> to write its passed payload to WebSocket.

The expectation is that whatever transport layer you have underneath
WAMP—WebSocket, “L<RawSocket|Net::WAMP::RawSocket>”, or what have
you—receives data in the appropriate message chunks already
(see L<IO::Framed> for an example) and can “do the needful” with a
serialized message to send. This makes it possible to nest WAMP within
some other transport mechanism—even another messaging protocol!

=head2 WAMP “RawSocket”

Net::WAMP includes a full implementation of WAMP’s “RawSocket” protocol
in L<Net::WAMP::RawSocket>. This protocol is simpler than
WebSocket and is probably a better choice for communication between any
two WAMP nodes that can speak raw TCP.

=head1 SERIALIZATIONS

WAMP defines two serializations officially: L<JSON|http://json.org>
(C<json>)
and L<MessagePack|http://msgpack.org> (C<msgpack>).

Note that MessagePack is a bit
inefficient for now owing to some hackery that works around
Data::MessagePack’s proprietary boolean logic; hopefully that can go away
after
L<a certain pull request|https://github.com/msgpack/msgpack-perl/issues/17>.
is merged.

=head1 BOOLEAN VALUES

Net::WAMP uses L<Types::Serialiser> to represent boolean values. You’ll
need to do likewise to interact with Net::WAMP. (Sorry.)

=head1 MESSAGE CLASSES

Each message type has its own class. Each class has the following methods:

=head2 I<OBJ>->get_type()

e.g., C<HELLO>, C<PUBLISHED>, …

=head2 I<OBJ>->get( KEY )

Returns the value of the given key from the message. For all but one case,
the key should correspond to a value as given in the message type
definition in the protocol specification: for example,
C<HELLO> messages’s C<Realm> attribute.

The one exception to this correlation is the C<Details>/C<Options>
dictionaries.
You’ll notice that the WAMP specification defines either a C<Details> or
C<Options>
parameter for almost every message type. The logic behind this naming duality
is not
consistently applied, and the duality serves no practical purpose since no
message can have
both C<Options> and C<Details>. In my opinion, this is just two names for the
same thing, which is just extra terminology to keep track of.
For these reasons, Net::WAMP
generalizes these names to C<Auxiliary>. If you like, you can still
use either of the other names for any of the message types that contains
either (i.e., you can use C<Options> with C<HELLO> just the same as
C<Details>).

(NB: L<This may become a permanent change in the protocol specification.|https://github.com/wamp-proto/wamp-proto/issues/279>)

=head1 SPECIFIC MESSAGE CLASSES

=over

=head2 Net::WebSocket::Message::PUBLISH

This class has methods C<publisher_wants_acknowledgement()> and
C<publisher_wants_to_be_excluded()> to indicate whether the given message
expresses
these desires. See the WAMP specification’s discussion of this message type
and the Publisher Exclusion feature for more details.

=head2 Net::WebSocket::Message::CALL

=head2 Net::WebSocket::Message::INVOCATION

Both of these have a C<caller_can_receive_progress()> method that returns a
boolean to indicate whether the caller indicated a willingness to receive
a progressive response to this specific remote procedure call. See L<the
WAMP specification’s discussion of the Progressive Call Results feature|http://wamp-proto.org/static/rfc/draft-oberstet-hybi-crossbar-wamp.html#rfc.section.14.3.1> feature
for more information.

=head2 Net::WebSocket::Message::YIELD

=head2 Net::WebSocket::Message::RESULT

Both of these have an C<is_progress()> method that returns a
boolean to indicate whether this message will be followed by others for the
same CALL/INVOCATION. See L<the
WAMP specification’s discussion of the Progressive Call Results feature|http://wamp-proto.org/static/rfc/draft-oberstet-hybi-crossbar-wamp.html#rfc.section.14.3.1>
for more information.

=back

=head1 ADVANCED PROFILE FEATURES

Net::WAMP supports a few of L<WAMP’s Advanced Profile features|http://wamp-proto.org/static/rfc/draft-oberstet-hybi-crossbar-wamp.html#rfc.section.14>. More may be
added at a later date; patches for at least the B<reasonably> stable features
are welcome. :)

=over

=item * L<publisher_exclusion|http://wamp-proto.org/static/rfc/draft-oberstet-hybi-crossbar-wamp.html#rfc.section.14.4.2> (publisher/broker feature)

=item * L<progressive_call_results|http://wamp-proto.org/static/rfc/draft-oberstet-hybi-crossbar-wamp.html#rfc.section.14.3.1> (RPC feature)

=item * L<call_canceling|http://wamp-proto.org/static/rfc/draft-oberstet-hybi-crossbar-wamp.html#rfc.section.14.3.4> (RPC feature)

=back

=head1 TODO

Support more Advanced Profile features, especially:

=over

=item * L<subscriber_blackwhite_listing|http://wamp-proto.org/static/rfc/draft-oberstet-hybi-crossbar-wamp.html#rfc.section.14.4.1>

=back

=head1 REPOSITORY

L<https://github.com/FGasper/p5-Net-WAMP>

=head1 AUTHOR

Felipe Gasper (FELIPE)

=head1 COPYRIGHT

Copyright 2017 by L<Gasper Software Consulting, LLC|http://gaspersoftware.com>

=head1 LICENSE

This distribution is released under the same license as Perl.

=cut

1;
