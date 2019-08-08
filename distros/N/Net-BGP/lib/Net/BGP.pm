#!/usr/bin/perl

package Net::BGP;

use strict;
use vars qw( $VERSION );

## Inheritance and Versioning ##

$VERSION = '0.17';

## End Code Section ##

=pod

=head1 NAME

Net::BGP - Border Gateway Protocol version 4 speaker/listener library

=head1 SYNOPSIS

    use Net::BGP::Process;
    use Net::BGP::Peer;

    $bgp  = Net::BGP::Process->new();
    $peer = Net::BGP::Peer->new(
        Start    => 1,
        ThisID   => '10.0.0.1',
        ThisAS   => 64512,
        PeerID   => '10.0.0.2',
        PeerAS   => 64513
    );

    $bgp->add_peer($peer);
    $peer->add_timer(\&my_timer_callback, 60);
    $bgp->event_loop();

=head1 DESCRIPTION

This module is an implementation of the BGP-4 inter-domain routing protocol.
It encapsulates all of the functionality needed to establish and maintain a
BGP peering session and exchange routing update information with the peer.
It aims to provide a simple API to the BGP protocol for the purposes of
automation, logging, monitoring, testing, and similar tasks using the power
and flexibility of perl. The module does not implement the functionality of
a RIB (Routing Information Base) nor does it modify the kernel routing table
of the host system. However, such operations could be implemented using the
API provided by the module.

The module takes an object-oriented approach to abstracting the operations
of the BGP protocol. It supports multiple peering sessions and each peer
corresponds to one instance of a B<Net::BGP::Peer> object. The details of
maintaining each peering session are handled and coordinated by an instance
of a B<Net::BGP::Process> object. BGP UPDATE messages and the routing
information they represent are encapsulated by B<Net::BGP::Update> objects.
Whenever protocol errors occur and a BGP NOTIFICATION is sent or received,
programs can determine the details of the error via B<Net::BGP::Notification>
objects.

The module interacts with client programs through the paradigm of callback
functions. Whenever interesting protocol events occur, a callback function
supplied by the user is called and information pertaining to the event is
passed to the function for examination or action. For instance, whenever an
UPDATE message is received from a peer, the module handles the details of
decoding the message, validating it, and encapsulating it in an object and
passing the object to the specific callback function supplied by the user
for UPDATE message handling. The callback function is free to do whatever
with the object - it might send a Net::BGP::Update object to other peers
as UPDATE messages, perhaps after modifying some of the UPDATE attributes,
log the routing information to a file, or do nothing at all. The
possibilities for implementing routing policy via such a mechanism are
limited only by the expressive capabilities of the perl language. It should
be noted however that the module is intended for the uses stated above and
probably would not scale well for very large BGP meshes or routing tables.

The module must maintain periodic protocol keep-alive and other processes,
so once control is passed to the module's main event loop, control flow
only passes back to user code whenever one of the callback functions is
invoked. To provide more interaction with user programs, the module allows
user timers to be established and called periodically to perform further
processing. Multiple timers may be established, and each is associated with
a single peer. Whenever the timers expire, a user supplied function is called
and the timer is reset. The timer callback functions can perform whatever
actions are necessary - sending UPDATEs, modifying the state of the peering
session, house-keeping, etc.

=head1 BUGS

The connection collision resolution code is broken. As currently implemented,
whenever a connection is received from a peer, the B<Net::BGP::Peer> object
is cloned and each peer object proceeds through the session establishment
process until the collision resolution procedure is reached. At this point, if
the cloned object is chosen by the collison resolution procedure, the original
peer object is destroyed, leaving the cloned object. Unfortunately, a user
program will only have a reference to the original peer object it created and
will have no way of accessing the cloned object. It is therefore recommended
that B<Net::BGP::Peer> objects be instantiated with the B<Listen> parameter
set to a false value. This prevents the peer object from receiving connections
from its BGP peer, although it will continue actively attempting to establish
sessions. This problem will be addressed in a future revision of B<Net::BGP>.

As an initial revision, the code has not been subjected to a thorough security
audit. It is possible and likely that exploitable code exists in the packet
decoding routines. Therefore, it is recommended that the module only be used
to establish peering sessions with trusted peers, particularly if programs
using the module will be run with root priviliges (which is necessary if
programs want to modify the kernel routing table or bind to the well-known
BGP port 179).

=head1 SEE ALSO

RFC 1771, and the perldocs for Net::BGP::Process, Net::BGP::Peer, Net::BGP::Update,
and Net::BGP::Notification

=head1 AUTHOR

Stephen J. Scheck <sscheck@cpan.org>

=cut

## End Package Net::BGP ##

1;
