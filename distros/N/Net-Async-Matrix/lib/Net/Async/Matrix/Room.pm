#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2016 -- leonerd@leonerd.org.uk

package Net::Async::Matrix::Room;

use strict;
use warnings;

# Not really a Notifier but we like the ->maybe_invoke_event style
use base qw( IO::Async::Notifier );

our $VERSION = '0.19';
$VERSION = eval $VERSION;

use Carp;

use Future;
use Future::Utils qw( repeat );

use List::Util qw( pairmap );
use Time::HiRes qw( time );

use Net::Async::Matrix::Room::State;
# TEMPORARY hack
*Member = \&Net::Async::Matrix::Room::State::Member;

use Data::Dump 'pp';

use constant TYPING_RESEND_SECONDS => 30;

=head1 NAME

C<Net::Async::Matrix::Room> - a single Matrix room

=head1 DESCRIPTION

An instances in this class are used by L<Net::Async::Matrix> to represent a
single Matrix room.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or C<CODE>
references in parameters:

=head2 on_synced_state

Invoked after the initial sync of the room has been completed as far as the
state.

=head2 on_message $member, $content, $event

=head2 on_back_message $member, $content, $event

Invoked on receipt of a new message from the given member, either "live" from
the event stream, or from backward pagination.

=head2 on_membership $member, $event, $subject_member, %changes

=head2 on_back_membership $member, $event, $subject_member, %changes

Invoked on receipt of a membership change event for the given member, either
"live" from the event stream, or from backward pagination. C<%changes> will be
a key/value list of state field names that were changed, whose values are
2-element ARRAY references containing the before/after values of those fields.

 on_membership:      $field_name => [ $old_value, $new_value ]
 on_back_membership: $field_name => [ $new_value, $old_value ]

Note carefully that the second value in each array gives the "updated" value,
in the direction of the change - that is, for C<on_membership> it gives the
new value after the change but for C<on_back_message> it gives the old value
before. Fields whose values did not change are not present in the C<%changes>
list; the values of these can be inspected on the C<$member> object.

It is unspecified what values the C<$member> object has for fields present in
the change list - client code should not rely on these fields.

In most cases when users change their own membership status (such as normal
join or leave), the C<$member> and C<$subject_member> parameters refer to the
same object. In other cases, such as invites or kicks, the C<$member>
parameter refers to the member performing the change, and the
C<$subject_member> refers to member that the change is about.

=head2 on_state_changed $member, $event, %changes

=head2 on_back_state_changed $member, $event, %changes

Invoked on receipt of a change of room state (such as name or topic).

In the special case of room aliases, because they are considered "state" but
are stored per-homeserver, the changes value will consist of three fields; the
old and new values I<from that home server>, and a list of the known aliases
from all the other servers:

 on_state_changed:      aliases => [ $old, $new, $other ]
 on_back_state_changed: aliases => [ $new, $old, $other ]

This allows a client to detect deletions and additions by comparing the before
and after lists, while still having access to the full set of before or after
aliases, should it require it.

=head2 on_presence $member, %changes

Invoked when a member of the room changes membership or presence state. The
C<$member> object will already be in the new state. C<%changes> will be a
key/value list of state fields names that were changed, and references to
2-element ARRAYs containing the old and new values for this field.

=head2 on_typing $member, $is_typing

Invoked on receipt of a typing notification change, when the given member
either starts or stops typing.

=head2 on_members_typing @members

Invoked on receipt of a typing notification change to give the full set of
currently-typing members. This is invoked after the individual C<on_typing>
events.

=head2 on_read_receipt $member, $event_id, $content

Invoked on receipt of a C<m.read> type of receipt message.

=cut

sub _init
{
   my $self = shift;
   my ( $params ) = @_;
   $self->SUPER::_init( $params );

   $self->{matrix}  = delete $params->{matrix};
   $self->{room_id} = delete $params->{room_id};

   # Server gives us entire sets of typing user_ids all at once. We have to
   # remember state
   $self->{typing_members} = {};

   $self->{live_state} = Net::Async::Matrix::Room::State->new( $self );
}

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( on_message on_back_message on_membership on_back_membership
         on_presence on_synced_state on_state_changed on_back_state_changed
         on_typing on_members_typing on_read_receipt )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   $self->SUPER::configure( %params );
}

=head1 METHODS

=cut

# FUNCTION
sub _delete_null_changes
{
   my ( $changes ) = @_;

   foreach ( keys %$changes ) {
      my ( $old, $new ) = @{ $changes->{$_} };

      delete $changes->{$_} if !defined $old and !defined $new or
                               defined $old and defined $new and $old eq $new;
   }
}

# FUNCTION
sub _pushdown_changes
{
   my ( $ch ) = @_;
   my ( $oldhash, $newhash ) = @$ch;

   my %changes;

   foreach ( keys %$oldhash ) {
      my $old = $oldhash->{$_};
      if( !exists $newhash->{$_} ) {
         $changes{$_} = [ $old, undef ] if defined $old;
         next;
      }

      my $new = $newhash->{$_};

      $changes{$_} = [ $old, $new ] unless !defined $old and !defined $new or
                                           defined $old and defined $new and $old eq $new;
   }

   foreach ( keys %$newhash ) {
      my $new = $newhash->{$_};
      next if exists $oldhash->{$_};

      $changes{$_} = [ undef, $new ] if defined $new;
   }

   return keys %changes ? \%changes : undef;
}

sub _do_GET_json
{
   my $self = shift;
   my ( $path, @args ) = @_;

   $self->{matrix}->_do_GET_json( "/rooms/$self->{room_id}" . $path, @args );
}

sub _do_PUT_json
{
   my $self = shift;
   my ( $path, $content ) = @_;

   $self->{matrix}->_do_PUT_json( "/rooms/$self->{room_id}" . $path, $content );
}

sub _do_POST_json
{
   my $self = shift;
   my ( $path, $content ) = @_;

   $self->{matrix}->_do_POST_json( "/rooms/$self->{room_id}" . $path, $content );
}

=head2 await_synced

   $f = $room->await_synced

Returns a L<Future> stored within the room that will complete (with no value)
once the room initial state sync has been completed. This completes just
I<before> the C<on_synced_state> event.

=cut

sub _reset_for_sync
{
   my $self = shift;

   undef $self->{synced_future};
}

sub _incoming_sync_invite
{
   my $self = shift;
   my ( $sync ) = @_;
   warn "TODO handle incoming sync data in invite state";
}

sub _incoming_sync_join
{
   my $self = shift;
   my ( $sync ) = @_;

   my $initial = not $self->await_synced->is_done;

   # Toplevel fields for now I'm ignoring
   #   account_data
   #   unread_notifications

   my $live_state = $self->live_state;

   if( $sync->{state} and $sync->{state}{events} and @{ $sync->{state}{events} } ) {
      foreach my $event ( @{ $sync->{state}{events} } ) {
         $live_state->handle_event( $event );
      }
   }

   foreach my $event ( @{ $sync->{timeline}{events} } ) {
      if( defined $event->{state_key} ) {
         my $old_event = $live_state->get_event( $event->{type}, $event->{state_key} );
         $live_state->handle_event( $event );
         $self->_handle_state_event( $old_event, $event, $live_state );
      }
      else {
         $self->_handle_event( forward => $event );
      }
   }

   foreach my $event ( @{ $sync->{ephemeral}{events} } ) {
      $self->_handle_event( ephemeral => $event );
   }

   if( $initial ) {
      $self->await_synced->done;
      $self->maybe_invoke_event( on_synced_state => );
   }
}

sub _incoming_sync_leave
{
   my $self = shift;
   my ( $sync ) = @_;
   # don't care for now
}

sub await_synced
{
   my $self = shift;
   return $self->{synced_future} //= $self->loop->new_future;
}

=head2 live_state

   $state = $room->live_state

Returns a L<Net::Async::Matrix::Room::State> instance representing the current
live-tracking state of the room.

This instance will mutate and change as new state events are received.

=cut

sub live_state
{
   my $self = shift;
   return $self->{live_state};
}

sub _handle_state_event
{
   my $self = shift;
   my ( $old_event, $new_event, $state ) = @_;

   my $old_content = $old_event->{content};
   my $new_content = $new_event->{content};

   my %changes;
   $changes{$_}->[0] = $old_content->{$_} for keys %$old_content;
   $changes{$_}->[1] = $new_content->{$_} for keys %$new_content;

   $_->[1] //= undef for values %changes; # Ensure deleted key values become undef

   _delete_null_changes \%changes;

   my $member = $state->member( $new_event->{sender} );

   my $type = $new_event->{type};

   $type =~ m/^m\.room\.(.*)$/;
   my $method = $1 ? "_handle_state_event_" . join( "_", split m/\./, $1 ) : undef;

   if( $method and my $code = $self->can( $method ) ) {
      $self->$code( $member, $new_event, $state, %changes );
   }
   else {
      $self->maybe_invoke_event( on_state_changed =>
         $member, $new_event, %changes
      );
   }
}

sub _handle_event
{
   my $self = shift;
   my ( $direction, $event ) = @_;

   $event->{type} =~ m/^(m\.room\.)?(.*)$/ or return;

   my $base = $1 ? "_handle_roomevent_" : "_handle_event_";
   my $method = $base . join( "_", split( m/\./, $2 ), $direction );

   if( my $code = $self->can( $method ) ) {
      $code->( $self, $event );
   }
   else {
      warn "TODO: $direction event $event->{type}\n";
   }
}

sub _handle_state_backward
{
   my $self = shift;
   my ( $field, $event ) = @_;

   my $newvalue = $event->{content}{$field};
   my $oldvalue = $event->{prev_content}{$field};

   $self->maybe_invoke_event( on_back_state_changed =>
      $self->{back_members_by_userid}{$event->{user_id}}, $event,
      $field => [ $newvalue, $oldvalue ]
   );
}

=head2 room_id

   $id = $room->room_id

Returns the opaque room ID string for the room. Usually this would not be
required, except for long-term persistence uniqueness purposes, or for
inclusion in direct protocol URLs.

=cut

sub room_id
{
   my $self = shift;
   return $self->{room_id};
}

=head2 name

   $name = $room->name

Returns the room name, if defined, otherwise the opaque room ID.

=cut

sub _handle_roomevent_name_backward
{
   my $self = shift;
   my ( $event ) = @_;
   $self->_handle_state_backward( name => $event );
}

sub name
{
   my $self = shift;
   return $self->live_state->name || $self->room_id;
}

=head2 set_name

   $room->set_name( $name )->get

Requests to set a new room name.

=cut

sub set_name
{
   my $self = shift;
   my ( $name ) = @_;

   $self->_do_PUT_json( "/state/m.room.name", { name => $name } )
      ->then_done();
}

=head2 aliases

   @aliases = $room->aliases

Returns a list of all the known room alias names taken from the
C<m.room.alias> events. Note that these are simply names I<claimed> to have
aliases from the alias events; a client ought to still check that these are
valid before presenting them to the user as such, or in other ways relying on
their values.

=cut

sub _handle_state_event_aliases
{
   my $self = shift;
   my ( $member, $event, $state, %changes ) = @_;

   my $homeserver = $event->{state_key};

   my @others = map { $_->{content}{aliases} }
                grep { $_->{state_key} ne $homeserver }
                values %{ $state->get_events( "m.room.aliases" ) };

   $changes{aliases}[2] = \@others;

   $self->maybe_invoke_event( on_state_changed =>
      $member, $event, %changes
   );
}

sub _handle_roomevent_aliases_backward
{
   my $self = shift;
   my ( $event ) = @_;

   my $homeserver = $event->{state_key};

   my $new = $event->{prev_content}{aliases} // [];
   my $old = $event->{content}{aliases} // [];

   $self->{back_aliases_by_hs}{$homeserver} = [ @$new ];

   my @others = map { @{ $self->{back_aliases_by_hs}{$_} } }
                grep { $_ ne $homeserver }
                keys %{ $self->{back_aliases_by_hs} };

   $self->maybe_invoke_event( on_back_state_changed =>
      $self->{back_members_by_userid}{$event->{user_id}}, $event,
      aliases => [ $old, $new, \@others ]
   );
}

sub aliases
{
   my $self = shift;
   return $self->live_state->aliases;
}

=head2 join_rule

   $rule = $room->join_rule

Returns the current C<join_rule> for the room; a string giving the type of
access new members may get:

=over 4

=item * public

Any user may join without further permission

=item * invite

Users may only join if explicitly invited

=item * knock

Any user may send a knock message to request access; may only join if invited

=item * private

No new users may join the room

=back

=cut

sub _handle_roomevent_join_rules_backward
{
   my $self = shift;
   my ( $event ) = @_;
   $self->_handle_state_backward( join_rule => $event );
}

sub join_rule
{
   my $self = shift;
   return $self->live_state->join_rule;
}

=head2 topic

   $topic = $room->topic

Returns the room topic, if defined

=cut

sub _handle_roomevent_topic_backward
{
   my $self = shift;
   my ( $event ) = @_;
   $self->_handle_state_backward( topic => $event );
}

sub topic
{
   my $self = shift;
   return $self->live_state->topic;
}

=head2 set_topic

   $room->set_topic( $topic )->get

Requests to set a new room topic.

=cut

sub set_topic
{
   my $self = shift;
   my ( $topic ) = @_;

   $self->_do_PUT_json( "/state/m.room.topic", { topic => $topic } )
      ->then_done();
}

=head2 levels

   %levels = $room->levels

Returns a key/value list of the room levels; that is, the member power level
required to perform each of the named actions.

=cut

sub _handle_generic_level
{
   my $self = shift;
   my ( $phase, $level, $convert, $event ) = @_;

   foreach my $k (qw( content prev_content )) {
      next unless my $levels = $event->{$k};

      $event->{$k} = {
         map { $convert->{$_} => $levels->{$_} } keys %$convert
      };
   }

   if( $phase eq "initial" ) {
      my $levels = $event->{content};

      $self->{levels}{$_} = $levels->{$_} for keys %$levels;
   }
   elsif( $phase eq "forward" ) {
      my $newlevels = $event->{content};
      my $oldlevels = $event->{prev_content};

      my %changes;
      foreach ( keys %$newlevels ) {
         $self->{levels}{$_} = $newlevels->{$_};

         $changes{"level.$_"} = [ $oldlevels->{$_}, $newlevels->{$_} ]
            if !defined $oldlevels->{$_} or $oldlevels->{$_} != $newlevels->{$_};
      }

      my $member = $self->member( $event->{sender} );
      $self->maybe_invoke_event( on_state_changed =>
         $member, $event, %changes
      );
   }
   elsif( $phase eq "backward" ) {
      my $newlevels = $event->{content};
      my $oldlevels = $event->{prev_content};

      my %changes;
      foreach ( keys %$newlevels ) {
         $changes{"level.$_"} = [ $newlevels->{$_}, $oldlevels->{$_} ]
            if !defined $oldlevels->{$_} or $oldlevels->{$_} != $newlevels->{$_};
      }

      my $member = $self->{back_members_by_userid}{$event->{user_id}};
      $self->maybe_invoke_event( on_back_state_changed =>
         $member, $event, %changes
      );
   }
}

sub levels
{
   my $self = shift;
   return %{ $self->{levels} };
}

=head2 change_levels

   $room->change_levels( %levels )->get

Performs a room levels change, submitting new values for the given keys while
leaving other keys unchanged.

=cut

sub change_levels
{
   my $self = shift;
   my %levels = @_;

   # Delete null changes
   foreach ( keys %levels ) {
      delete $levels{$_} if $self->{levels}{$_} == $levels{$_};
   }

   my %events;

   # These go in their own event with the content key 'level'
   foreach (qw( send_event add_state )) {
      $events{"${_}_level"} = { level => $levels{$_} } if exists $levels{$_};
   }

   # These go in an 'ops_levels' event
   foreach (qw( ban kick redact )) {
      $events{ops_levels}{"${_}_level"} = $levels{$_} if exists $levels{$_};
   }

   # Fill in remaining 'ops_levels' keys
   if( $events{ops_levels} ) {
      $events{ops_levels}{"${_}_level"} //= $self->{levels}{$_} for qw( ban kick redact );
   }

   Future->needs_all(
      map { $self->_do_PUT_json( "/state/m.room.$_", $events{$_} ) } keys %events
   )->then_done();
}

=head2 members

   @members = $room->members

Returns a list of member structs containing the currently known members of the
room, in no particular order. This list will include users who are not yet
members of the room, but simply have been invited.

=cut

sub _handle_roomevent_member_backward
{
   my $self = shift;
   my ( $event ) = @_;

   # $self->_handle_roomevent_member( on_back_membership => $event,
   #    $self->{back_members_by_userid}, $event->{content}, $event->{prev_content} );
}

sub _handle_state_event_member
{
   my $self = shift;
   my ( $member, $event, $state, %changes ) = @_;

   # Currently, the server "deletes" users from the room by setting their
   # membership to "leave". It's neater if we consider an empty content in
   # that case.
   foreach my $idx ( 0, 1 ) {
      next unless ( $changes{membership}[$idx] // "" ) eq "leave";

      undef $changes{$_}[$idx] for keys %changes;
   }

   my $user_id = $event->{state_key}; # == user the change applies to

   my $target_member = $state->member( $user_id ) or
      warn "ARGH: roomevent_member with unknown user id '$user_id'" and return;

   _delete_null_changes \%changes;

   $self->maybe_invoke_event( on_membership => $member, $event, $target_member, %changes );
}

sub members
{
   my $self = shift;
   return $self->live_state->members;
}

sub member
{
   my $self = shift;
   my ( $user_id ) = @_;
   return $self->live_state->member( $user_id );
}

=head2 joined_members

   @members = $room->joined_members

Returns the subset of C<all_members> who actually in the C<"join"> state -
i.e. are not invitees, or have left.

=cut

sub joined_members
{
   my $self = shift;
   return grep { ( $_->membership // "" ) eq "join" } $self->members;
}

=head2 member_level

   $level = $room->member_level( $user_id )

Returns the current cached value for the power level of the given user ID, or
the default value if no specific value exists for the given ID.

=cut

sub _handle_roomevent_power_levels_backward
{
   my $self = shift;
   my ( $event ) = @_;

   # $self->_handle_roomevent_power_levels( on_back_membership =>
   #    $event, $self->{back_members_by_userid}, $event->{content}, $event->{prev_content}
   # );
}

sub _handle_state_event_power_levels
{
   my $self = shift;
   my ( $member, $event, $state, %changes ) = @_;

   # Before we go any further we should also clean up null changes in 'users'
   # and 'events' hashes by pushing the 'old+new' diff ARRAYrefs down into the
   # hashes
   $_ and $_ = _pushdown_changes $_ for $changes{users}, $changes{events};

   if( my $users = $changes{users} ) {
      # TODO: handle default changes
      my $default = $event->{content}{user_default};

      foreach my $user_id ( keys %$users ) {
         my $target = $state->member( $user_id ) or next;
         my ( $oldlevel, $newlevel ) = @{ $users->{$user_id} };

         $oldlevel //= $default;
         $newlevel //= $default;

         $self->maybe_invoke_event( on_membership =>
            $member, $event, $target, level => [ $oldlevel, $newlevel ]
         );
      }
   }
}

sub member_level
{
   my $self = shift;
   my ( $user_id ) = @_;
   return $self->live_state->member_level( $user_id );
}

=head2 change_member_levels

   $room->change_member_levels( %levels )->get

Performs a member power level change, submitting new values for user IDs to
the home server. As there is no server API to make individual mutations, this
is done by taking the currently cached values, applying the changes given by
the C<%levels> key/value list, and submitting the resulting whole as the new
value for the C<m.room.power_levels> room state.

The C<%levels> key/value list should provide new values for keys giving user
IDs, or the special user ID of C<default> to change the overall default value
for users not otherwise mentioned. Setting the special value of C<undef> for a
user ID will remove that ID from the set, reverting them to the default.

=cut

sub change_member_levels
{
   my $self = shift;

   # Can't just edit the local cache as maybe the server will reject it. Clone
   # it and if the server accepts our modification the cache will be updated
   # on the incoming event.

   my %user_levels = %{ $self->{powerlevels}{users} };

   while( @_ ) {
      my $user_id = shift;
      my $value   = shift;

      if( defined $value ) {
         $user_levels{$user_id} = $value;
      }
      else {
         delete $user_levels{$user_id};
      }
   }

   $self->_do_PUT_json( "/state/m.room.power_levels",
      { %{ $self->{powerlevels} }, users => \%user_levels }
   )->then_done();
}

=head2 leave

   $room->leave->get

Requests to leave the room. After this completes, the user will no longer be
a member of the room.

=cut

sub leave
{
   my $self = shift;
   $self->_do_POST_json( "/leave", {} );
}

=head2 invite

   $room->invite( $user_id )->get

Sends an invitation for the user with the given User ID to join the room.

=cut

sub invite
{
   my $self = shift;
   my ( $user_id ) = @_;

   $self->_do_POST_json( "/invite", { user_id => $user_id } )
      ->then_done();
}

=head2 kick

   $room->kick( $user_id, $reason )->get

Requests to remove the user with the given User ID from the room.

Optionally, a textual description reason can also be provided.

=cut

sub kick
{
   my $self = shift;
   my ( $user_id, $reason ) = @_;

   $self->_do_POST_json( "/kick", { user_id => $user_id, reason => $reason } )
      ->then_done();
}

=head2 send_message

   $event_id = $room->send_message( %args )->get

Sends a new message to the room. Requires a C<type> named argument giving the
message type. Depending on the type, further keys will be required that
specify the message contents:

=over 4

=item m.text, m.emote, m.notice

Require C<body>

=item m.image, m.audio, m.video, m.file

Require C<url>

=item m.location

Require C<geo_uri>

=back

If an additional argument called C<txn_id> is provided, this is used as the
transaction ID for the message, which is then sent as a C<PUT> request instead
of a C<POST>.

   $event_id = $room->send_message( $text )->get

A convenient shortcut to sending an C<text> message with a body string and
no additional content.

=cut

my %MSG_REQUIRED_FIELDS = (
   'm.text'     => [qw( body )],
   'm.emote'    => [qw( body )],
   'm.notice'   => [qw( body )],
   'm.image'    => [qw( url )],
   'm.audio'    => [qw( url )],
   'm.video'    => [qw( url )],
   'm.file'     => [qw( url )],
   'm.location' => [qw( geo_uri )],
);

sub send_message
{
   my $self = shift;
   my %args = ( @_ == 1 ) ? ( type => "m.text", body => shift ) : @_;

   my $type = $args{msgtype} = delete $args{type} or
      croak "Require a 'type' field";

   $MSG_REQUIRED_FIELDS{$type} or
      croak "Unrecognised message type '$type'";

   foreach (@{ $MSG_REQUIRED_FIELDS{$type} } ) {
      $args{$_} or croak "'$type' messages require a '$_' field";
   }

   if( defined( my $txn_id = $args{txn_id} ) ) {
      $self->_do_PUT_json( "/send/m.room.message/$txn_id", \%args )->then( sub {
         my ( $response ) = @_;
         Future->done( $response->{event_id} );
      });
   }
   else {
      $self->_do_POST_json( "/send/m.room.message", \%args )->then( sub {
         my ( $response ) = @_;
         Future->done( $response->{event_id} );
      });
   }
}

=head2 paginate_messages

   $room->paginate_messages( limit => $n )->get

Requests more messages of back-pagination history.

There is no need to maintain a reference on the returned C<Future>; it will be
adopted by the room object.

=cut

sub paginate_messages
{
   my $self = shift;
   my %args = @_;

   my $limit = $args{limit} // 20;
   my $from  = $self->{pagination_token} // "END";

   croak "Cannot paginate_messages any further since we're already at the start"
      if $from eq "START";

   # Since we're now doing pagination, we'll need a second set of member
   # objects
   $self->{back_members_by_userid} //= {
      pairmap { $a => Member( $b->user, $b->displayname, $b->membership ) } %{ $self->{members_by_userid} }
   };
   $self->{back_aliases_by_hs} //= {
      pairmap { $a => [ @$b ] } %{ $self->{aliases_by_hs} }
   };

   my $f = $self->_do_GET_json( "/messages",
      from  => $from,
      dir   => "b",
      limit => $limit,
   )->then( sub {
      my ( $response ) = @_;

      foreach my $event ( @{ $response->{chunk} } ) {
         next unless my ( $subtype ) = ( $event->{type} =~ m/^m\.room\.(.*)$/ );
         $subtype =~ s/\./_/g;

         if( my $code = $self->can( "_handle_roomevent_${subtype}_backward" ) ) {
            $code->( $self, $event );
         }
         else {
            $self->{matrix}->log( "TODO: Handle room pagination event $subtype" );
         }
      }

      $self->{pagination_token} = $response->{end};
      Future->done( $self );
   });
   $self->adopt_future( $f );
}

=head2 typing_start

   $room->typing_start

Sends a typing notification that the user is currently typing in this room.
This notification will periodically be re-sent as required by the protocol
until the C<typing_stop> method is called.

=cut

sub typing_start
{
   my $self = shift;

   return if $self->{typing_timer};

   my $user_id = $self->{matrix}->myself->user_id;

   my $f = $self->{typing_timer} = repeat {
      $self->_do_PUT_json( "/typing/$user_id", {
         typing  => 1,
         timeout => ( TYPING_RESEND_SECONDS + 5 ) * 1000, # msec
      })->then( sub {
         $self->{matrix}->{make_delay}->( TYPING_RESEND_SECONDS );
      });
   } while => sub { !shift->failure };

   $f->on_fail( $self->_capture_weakself( sub {
      my $self = shift;
      $self->invoke_error( @_ );
   }));
}

=head2 typing_stop

   $room->typing_stop

Sends a typing notification that the user is no longer typing in this room.
This method also cancels the repeating re-send behaviour created by
C<typing_start>.

=cut

sub typing_stop
{
   my $self = shift;

   return unless my $f = $self->{typing_timer};

   $f->cancel;
   undef $self->{typing_timer};

   my $user_id = $self->{matrix}->myself->user_id;

   $self->adopt_future(
      $self->_do_PUT_json( "/typing/$user_id", {
         typing => 0,
      })
   );
}

=head2 send_read_receipt

   $room->send_read_receipt( event_id => $event_id, ... )->get

Sends a C<m.read> receipt to the given room for the given event ID.

=cut

sub send_read_receipt
{
   my $self = shift;
   my %args = @_;

   my $event_id = $args{event_id} or croak "Require event_id";

   $self->_do_POST_json( "/receipt/m.read/$event_id", {} );
}

sub _handle_roomevent_create_forward
{
   my $self = shift;
   my ( $event ) = @_;

   # Nothing interesting here...
}
*_handle_roomevent_create_initial = \&_handle_roomevent_create_forward;

sub _handle_roomevent_create_backward
{
   my $self = shift;

   # Stop now
   $self->{pagination_token} = "START";
}

sub _handle_roomevent_message_forward
{
   my $self = shift;
   my ( $event ) = @_;

   my $user_id = $event->{sender};
   my $member = $self->member( $user_id ) or
      warn "TODO: Unknown member '$user_id' for forward message" and return;

   $self->maybe_invoke_event( on_message => $member, $event->{content}, $event );
}

sub _handle_roomevent_message_backward
{
   my $self = shift;
   my ( $event ) = @_;

   my $user_id = $event->{user_id};
   my $member = $self->{back_members_by_userid}{$user_id} or
      warn "TODO: Unknown member '$user_id' for backward message" and return;

   $self->maybe_invoke_event( on_back_message => $member, $event->{content}, $event );
}

sub _handle_event_m_presence
{
   my $self = shift;
   my ( $user, %changes ) = @_;
   my $member = $self->member( $user->user_id ) or return;

   $changes{$_} and $member->$_ = $changes{$_}[1]
      for qw( displayname );

   $self->maybe_invoke_event( on_presence => $member, %changes );
}

sub _handle_event_m_typing_ephemeral
{
   my $self = shift;
   my ( $event ) = @_;

   my $typing = $self->{typing_members};
   my %not_typing = %$typing;

   foreach my $user_id ( @{ $event->{content}{user_ids} } ) {
      delete $not_typing{$user_id};
      next if $typing->{$user_id};

      $typing->{$user_id}++;
      my $member = $self->member( $user_id ) or next;
      $self->maybe_invoke_event( on_typing => $member, 1 );
   }

   foreach my $user_id ( keys %not_typing ) {
      my $member = $self->member( $user_id ) or next;
      $self->maybe_invoke_event( on_typing => $member, 0 );
      delete $typing->{$user_id};
   }

   my @members = map { $self->member( $_ ) } keys %$typing;
   $self->maybe_invoke_event( on_members_typing => grep { defined } @members );
}

sub _handle_event_m_receipt_ephemeral
{
   my $self = shift;
   my ( $event ) = @_;

   my $content = $event->{content};
   foreach my $event_id ( keys %$content ) {
      my $receipt = $content->{$event_id};
      my $read_receipt = $receipt->{"m.read"} or next;

      foreach my $user_id ( keys %$read_receipt ) {
         my $content = $read_receipt->{$user_id};
         my $member = $self->member( $user_id ) or next;

         $self->maybe_invoke_event( on_read_receipt => $member, $event_id, $content );
      }
   }
}

=head1 MEMBERSHIP STRUCTURES

Parameters documented as C<$member> receive a membership struct, which
supports the following methods:

=head2 $user = $member->user

User object of the member.

=head2 $displayname = $member->displayname

Profile displayname of the user.

=head2 $membership = $member->membership

Membership state. One of C<invite> or C<join>.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
