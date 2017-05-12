#!/usr/bin/perl

use strict;

use Test::More tests => 6;

use POE qw( Wheel::TermKey );

# Sanitise this just in case
$ENV{TERM} = "vt100";

my $wheel;

POE::Session->create(
   inline_states => {
      _start => sub {
         pipe( my ( $rd, $wr ) ) or die "Cannot pipe() - $!";

         $wheel = POE::Wheel::TermKey->new(
            Term       => $rd,
            InputEvent => 'got_key',
         );
         $wr->syswrite( "h" );
      },
      got_key => sub {
         my $key = $_[ARG0];

         is( $key->termkey, $wheel->termkey, '$key->termkey after h' );

         ok( $key->type_is_unicode,     '$key->type_is_unicode after h' );
         is( $key->codepoint, ord("h"), '$key->codepoint after h' );
         is( $key->modifiers, 0,        '$key->modifiers after h' );

         is( $key->utf8, "h", '$key->utf8 after h' );

         is( $key->format( 0 ), "h", '$key->format after h' );

         # And we're done
         undef $wheel;
      },
   },
);

POE::Kernel->run;
