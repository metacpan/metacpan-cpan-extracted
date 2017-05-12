#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;

use POE qw( Wheel::TermKey );

POE::Session->create(
   inline_states => {
      _start => sub {
         my $wheel = POE::Wheel::TermKey->new(
            InputEvent => 'got_key',
         );

         defined $wheel or die "Cannot create termkey instance";

         # We know 'Space' ought to exist
         my $sym = $wheel->keyname2sym( 'Space' );

         ok( defined $sym, "defined keyname2sym('Space')" );

         is( $wheel->get_keyname( $sym ), 'Space', "get_keyname eq Space" );

         my $key;

         ok( defined( $key = $wheel->parse_key( "A", 0 ) ), '->parse_key "A" defined' );

         ok( $key->type_is_unicode,     '$key->type_is_unicode' );
         is( $key->codepoint, ord("A"), '$key->codepoint' );
         is( $key->modifiers, 0,        '$key->modifiers' );

         is( $wheel->format_key( $key, 0 ), "A", '->format_key yields "A"' );

         undef $wheel;
      },
   },
);

POE::Kernel->run;
