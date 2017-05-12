#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2017 -- leonerd@leonerd.org.uk

package Net::Async::Matrix::Room::State;

use strict;
use warnings;

use List::Util qw( pairmap );

use Struct::Dumb;

struct Member => [qw( user displayname membership )];

our $VERSION = '0.19';
$VERSION = eval $VERSION;

=head1 NAME

C<Net::Async::Matrix::Room::State> - represents the state events in a matrix room

=head1 DESCRIPTION

Instances of this class represent all of the known state events in a
L<Net::Async::Matrix::Room> at some instant in time. These objects are mutable
so a "live" state object obtained from a room will change to keep track of
newly received state events.

=cut

sub new
{
   my $class = shift;
   my ( $room ) = @_;

   return bless {
      events => {},
      matrix => $room->{matrix},
   }, $class;
}

sub handle_event
{
   my $self = shift;
   my ( $event ) = @_;

   defined $event->{state_key} or return;

   my $type      = $event->{type};
   my $state_key = $event->{state_key} // "";

   $self->{events}{$type}{$state_key} = $event;
}

=head1 METHODS

=cut

=head2 get_event

   $event = $state->get_event( $type, $state_key )

Returns a HASH reference containing the raw event stored for the given type
name and optional state key.

=cut

sub get_event
{
   my $self = shift;
   my ( $type, $state_key ) = @_;

   $state_key //= "";
   return $self->{events}{$type}{$state_key};
}

=head2 get_events

   $events = $state->get_events( $type )

Returns a multi-level HASH reference mapping all of the known state keys for a
given event type name to their raw stored events. Typically this is useful for
C<m.room.member> events as the state keys will be user IDs.

=cut

sub get_events
{
   my $self = shift;
   my ( $type ) = @_;

   return $self->{events}{$type} // {};
}

=head1 CONVENIENCE ACCESSORS

The following accessors all fetch single values out of certain events, as they
are commonly used.

=cut

=head2 name

   $name = $state->name

Returns the C<name> field of the C<m.room.name> event, if it exists.

=cut

sub name
{
   my $self = shift;
   my $event = $self->get_event( "m.room.name" ) or return undef;
   return $event->{content}{name};
}

=head2 join_rule

   $join_rule = $state->join_rule

Returns the C<join_rule> field of the C<m.room.join_rules> event, if it
exists.

=cut

sub join_rule
{
   my $self = shift;
   my $event = $self->get_event( "m.room.join_rules" ) or return undef;
   return $event->{content}{join_rule};
}

=head2 topic

   $topic = $state->topic

Returns the C<topic> field of the C<m.room.topic> event, if it exists.

=cut

sub topic
{
   my $self = shift;
   my $event = $self->get_event( "m.room.topic" ) or return undef;
   return $event->{content}{topic};
}

=head2 aliases

   @aliases = $state->aliases

Returns a list of the room alias from all the C<m.room.aliases> events, in no
particular order.

=cut

sub aliases
{
   my $self = shift;
   return map { @{ $_->{content}{aliases} } }
          values %{ $self->get_events( "m.room.aliases" ) };
}

=head2 members

   @members = $state->members

Returns a list of Member instances representing all of the members of the room
from the C<m.room.member> events whose membership state is not C<leave>.

=cut

sub members
{
   my $self = shift;
   my ( $with_leaves ) = @_;

   return pairmap {
      my ( $user_id, $event ) = ( $a, $b );
      my $content = $event->{content};

      return () if $content->{membership} eq "leave" and !$with_leaves;

      my $user = $self->{matrix}->_get_or_make_user( $user_id );
      Member( $user, $content->{displayname}, $content->{membership} );
   } %{ $self->get_events( "m.room.member" ) };
}

=head2 all_members

   @members = $state->members

Similar to L</members> but even includes members in C<leave> state. This is
not normally what you want.

=cut

sub all_members
{
   my $self = shift;
   return $self->members( 1 );
}

=head2 member

   $member = $state->member( $user_id )

Returns a Member instance representing a room member of the given user ID, or
C<undef> if none exists.

=cut

sub member
{
   my $self = shift;
   my ( $user_id ) = @_;

   my $event = $self->get_event( "m.room.member", $user_id ) or return undef;

   my $user = $self->{matrix}->_get_or_make_user( $user_id );
   my $content = $event->{content};
   return Member( $user, $content->{displayname}, $content->{membership} );
}

=head2 member_level

   $level = $state->member_level( $user_id )

Returns a number indicating the power level that the given user ID would have
according to room state, taken from the C<m.room.power_levels> event. This
takes into account the C<users_default> field, if no specific level exists for
the given user ID.

=cut

sub member_level
{
   my $self = shift;
   my ( $user_id ) = @_;

   my $event = $self->get_event( "m.room.power_levels" ) or return undef;
   my $levels = $event->{content};
   return $levels->{users}{$user_id} // $levels->{users_default};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
