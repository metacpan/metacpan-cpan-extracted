#!/usr/bin/perl

use strict;

use Test::More tests => 5;

use POE qw( Wheel::TermKey );

pipe( my ( $rd, $wr ) ) or die "Cannot pipe() - $!";

# Sanitise this just in case
$ENV{TERM} = "vt100";

my $key;
my $wheel;
my $timedout;

POE::Session->create(
   inline_states => {
      _start => sub {
         pipe( my ( $rd, $wr ) ) or die "Cannot pipe() - $!";

         $wheel = POE::Wheel::TermKey->new(
            Term       => $rd,
            InputEvent => 'got_key',
         );
         $wr->syswrite( "\e" );

         $_[KERNEL]->delay( halfwait => $wheel->get_waittime / 2000 );
         $_[KERNEL]->delay( abort    => $wheel->get_waittime /  500 );
      },
      halfwait => sub {
         ok( !defined $key, '$key still not defined after 1/2 waittime' );
         $timedout = 1;
      },
      got_key => sub {
         my $key = $_[ARG0];

         is( $timedout, 1, '$timedout already when recieved key' );

         ok( $key->type_is_keysym,                     '$key->type_is_keysym after Escape timeout' );
         is( $key->sym, $wheel->keyname2sym("Escape"), '$key->keysym after Escape timeout' );
         is( $key->modifiers, 0,                       '$key->modifiers after Escape timeout' );

         # And we're done
         $_[KERNEL]->alarm( abort => undef );
         undef $wheel;
      },

      abort => sub {
         die "Expected to receive a key by now but we didn't";
      },
   },
);

POE::Kernel->run;
