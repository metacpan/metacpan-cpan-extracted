#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Async::HTTP 0.02; # ->GET

use lib ".";
use t::Util;

use IO::Async::Loop;
use Net::Async::Matrix;
use Future;

my $matrix = Net::Async::Matrix->new(
   ua => my $ua = Test::Async::HTTP->new,
   server => "localserver.test",

   make_delay => sub { Future->new },
);

IO::Async::Loop->new->add( $matrix ); # for ->loop->new_future
matrix_login( $matrix, $ua );

use constant {
   ROOM_ID => "!room:localserver.test",
   USER_ID => '@sender:localserver.test',
};

sub _mksync
{
   my ( $event ) = @_;

   return (
      rooms => {
         join => {
            ROOM_ID() => {
               timeline => {
                  events => [
                     { %$event,
                        sender => USER_ID,
                     },
                  ]
               }
            }
         }
      }
   );
}

my $room = matrix_join_room( $matrix, $ua,
   {  type       => "m.room.member",
      room_id    => ROOM_ID,
      state_key  => USER_ID,
      content    => {
         membership => "join",
      },
      sender    => USER_ID,
   },
   {  type      => "m.room.name",
      content   => { name => "Initial name" },
      room_id   => ROOM_ID,
      state_key => "",
      sender    => USER_ID,
   },
   {  type      => "m.room.aliases",
      content   => { aliases => [ '#room1:localserver.test' ] },
      room_id   => ROOM_ID,
      state_key => "localserver.test",
      sender    => USER_ID,
   },
   {  type      => "m.room.join_rules",
      content   => { join_rule => "private" },
      room_id   => ROOM_ID,
      state_key => "",
      sender    => USER_ID,
   },
   {  type      => "m.room.topic",
      content   => { topic => "Initial topic" },
      room_id   => ROOM_ID,
      state_key => "",
      sender    => USER_ID,
   },
   {  type      => "m.room.power_levels",
      content   => {
         users => {
            USER_ID() => 100,
         },
         users_default => 50,
      },
      room_id   => ROOM_ID,
      state_key => "",
      sender    => USER_ID,
   },
);

my @state_changes;
my @member_changes;

$room->configure(
   on_state_changed => sub {
      shift;
      push @state_changes, [ @_ ];
   },
   on_membership => sub {
      shift;
      push @member_changes, [ @_ ];
   },
);

# room name
{
   is( $room->name, "Initial name", '$room->name initially' );

   send_sync( $ua, _mksync
      {
         type => "m.room.name",
         state_key => "",
         content => {
            name => "A new name",
         },
      },
   );

   is( $room->name, "A new name", '$room->name after event' );

   ok( my $ch = shift @state_changes, 'on_state_changed invoked' );
   my ( $member, $event, %changes ) = @$ch;

   is( $member->user->user_id, USER_ID, '[0] is $member' );
   is( $event->{type}, "m.room.name", '[1] is $event' );
   is_deeply( \%changes,
      { name => [ "Initial name", "A new name" ] },
      '[2..] is %changes' );
}

# aliases
{
   is_deeply( [ $room->aliases ], [ '#room1:localserver.test' ],
      '$room->aliases initially' );

   send_sync( $ua, _mksync
      {
         type => "m.room.aliases",
         state_key => "localserver.test",
         content => {
            aliases => [ '#room1:localserver.test', '#room2:localserver.test' ],
         },
      },
   );

   is_deeply( [ $room->aliases ], [ '#room1:localserver.test', '#room2:localserver.test' ],
      '$room->aliases after event' );

   ok( my $ch = shift @state_changes, 'on_state_changed invoked' );
   my ( $member, $event, %changes ) = @$ch;

   is( $member->user->user_id, USER_ID, '[0] is $member' );
   is( $event->{type}, "m.room.aliases", '[1] is $event' );
   is_deeply( \%changes,
      { aliases => [
            [ '#room1:localserver.test' ], [ '#room1:localserver.test', '#room2:localserver.test' ], []
         ]
      },
      '[2..] is %changes' );
}

# join rule
{
   is( $room->join_rule, "private", '$room->join_rule initially' );

   send_sync( $ua, _mksync
      {
         type => "m.room.join_rules", # sic
         state_key => "",
         content => {
            join_rule => "public",
         },
      },
   );

   is( $room->join_rule, "public", '$room->join_rule after event' );

   ok( my $ch = shift @state_changes, 'on_state_changed invoked' );
   my ( $member, $event, %changes ) = @$ch;

   is( $member->user->user_id, USER_ID, '[0] is $member' );
   is( $event->{type}, "m.room.join_rules", '[1] is $event' );
   is_deeply( \%changes,
      { join_rule => [ "private", "public" ] },
      '[2..] is %changes' );
}

# topic
{
   is( $room->topic, "Initial topic", '$room->topic initially' );

   send_sync( $ua, _mksync
      {
         type => "m.room.topic",
         state_key => "",
         content => {
            topic => "A new topic",
         },
      },
   );

   is( $room->topic, "A new topic", '$room->topic after event' );

   ok( my $ch = shift @state_changes, 'on_state_changed invoked' );
   my ( $member, $event, %changes ) = @$ch;

   is( $member->user->user_id, USER_ID, '[0] is $member' );
   is( $event->{type}, "m.room.topic", '[1] is $event' );
   is_deeply( \%changes,
      { topic => [ "Initial topic", "A new topic" ] },
      '[2..] is %changes' );
}

# members - joining
{
   is_deeply( [ map { $_->user->user_id } $room->members ], [ USER_ID ],
      'user ID of $room->members initially' );

   send_sync( $ua, _mksync
      {
         type => "m.room.member",
         state_key => '@new-user:localserver.test',
         content => {
            membership => "join",
         },
      },
   );

   is_deeply( [ sort map { $_->user->user_id } $room->members ],
      [ '@new-user:localserver.test', USER_ID ],
      'user ID of $room->members after event' );

   ok( my $ch = shift @member_changes, 'on_membership invoked' );
   my ( $member, $event, $subject, %changes ) = @$ch;

   is( $member->user->user_id, USER_ID, '[0] is $member' );
   is( $event->{type}, "m.room.member", '[1] is $event' );
   is( $subject->user->user_id, '@new-user:localserver.test', '[2] is $subject' );
   is_deeply( \%changes,
      { membership => [ undef, "join" ] },
      '[3..] is %changes' );
}

# members - changing name
{
   send_sync( $ua, _mksync
      {
         type => "m.room.member",
         state_key => '@new-user:localserver.test',
         content => {
            membership => "join",
            displayname => "Your Name Here",
         },
      },
   );

   is_deeply( [ grep { defined } map { $_->displayname } $room->members ],
      [ "Your Name Here" ],
      'displayname of $room->members after event' );

   ok( my $ch = shift @member_changes, 'on_membership invoked' );
   my ( $member, $event, $subject, %changes ) = @$ch;

   is( $member->user->user_id, USER_ID, '[0] is $member' );
   is( $event->{type}, "m.room.member", '[1] is $event' );
   is( $subject->user->user_id, '@new-user:localserver.test', '[2] is $subject' );
   is_deeply( \%changes,
      {
         displayname => [ undef, "Your Name Here" ],
      },
      '[3..] is %changes' );
}

# member levels
{
   is( $room->member_level( USER_ID ), 100, 'member_level initially' );

   send_sync( $ua, _mksync
      {
         type      => "m.room.power_levels",
         content   => {
            users => {
               USER_ID() => 80,
            },
            users_default => 50,
         },
         state_key => "",
      }
   );

   is( $room->member_level( USER_ID ), 80, 'member_level after event' );

   ok( my $ch = shift @member_changes, 'on_membership invoked' );
   my ( $member, $event, $subject, %changes ) = @$ch;

   is( $member->user->user_id, USER_ID, '[0] is $member' );
   is( $event->{type}, "m.room.power_levels", '[1] is $event' );
   is( $subject->user->user_id, USER_ID, '[2] is $subject' );
   is_deeply( \%changes,
      { level => [ 100, 80 ] },
      '[3..] is %changes' );
}

done_testing;
