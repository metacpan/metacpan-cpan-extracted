#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Protocol::Matrix qw( redact_event redacted_event );

# Basic events
{
   is_deeply(
      redacted_event( {
        type => "A",
      } ),
      { type       => "A",
        content    => {} },
     'redact_event adds content' );

   is_deeply(
      redacted_event( {
        type => "A",
        room_id  => '!1:domain',
        sender   => '@2:domain',
        event_id => '$3:domain',
        origin   => 'domain',
      } ),
      { type       => "A",
        room_id    => '!1:domain',
        sender     => '@2:domain',
        event_id   => '$3:domain',
        origin     => 'domain',
        content    => {}, },
     'redact_event preserves basic keys' );

   my %event = (
      type      => "A",
      other_key => "here",
   );
   redacted_event( \%event );
   ok( exists $event{other_key}, 'redacted_event leaves original unmodified' );

   redact_event( \%event );
   ok( !exists $event{other_key}, 'redact_event modifies inplace' );
}

# unsigned.age_ts
{
   is_deeply(
      redacted_event( {
         type     => "B",
         unsigned => { age_ts => 20 },
      } ),
      {
         type     => "B",
         content  => {},
         unsigned => { age_ts => 20 },
      },
      'redact_event preserves unsigned.age_ts' );

   is_deeply(
      redacted_event( {
         type     => "B",
         unsigned => { other_key => "here" },
      } ),
      {
         type     => "B",
         content  => {},
      },
      'redact_event removes other unsigned keys' );
}

# content keys
{
   is_deeply(
      redacted_event( {
         type    => "C",
         content => { things => "here" },
      } ),
      {
         type    => "C",
         content => {},
      },
      'redact_event removes content keys of unrecognised events' );

   is_deeply(
      redacted_event( {
         type    => "m.room.create",
         content => { creator => '@2:domain', other_field => "here" },
      } ),
      {
         type    => "m.room.create",
         content => { creator => '@2:domain' },
      },
      'redact_event preserves required keys of recognised events' );
}

done_testing;
