package Ryu::Async::Client;

use strict;
use warnings;

our $VERSION = '0.010'; # VERSION

=head1 NAME

Ryu::Async::Client - abstraction for stream or packet-based I/O clients

=cut

sub new { bless { @_[1..$#_] }, $_[0] }

=head2 incoming

A L<Ryu::Sink> which expects an event whenever there is a new packet received from the
remote.

=cut

sub incoming { shift->{incoming} }

=head2 outgoing

A L<Ryu::Source> which can be used to L<Ryu::Source/emit> an event for each outgoing packet.

=cut

sub outgoing { shift->{outgoing} }

1;

