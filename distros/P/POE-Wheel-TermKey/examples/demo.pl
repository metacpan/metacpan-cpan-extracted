#!/usr/bin/perl

use strict;
use warnings;

use Term::TermKey qw( FORMAT_VIM KEYMOD_CTRL );
use POE qw(Wheel::TermKey);

POE::Session->create(
   inline_states => {
      _start => sub {
         $_[HEAP]{termkey} = POE::Wheel::TermKey->new(
            InputEvent => 'got_key',
         );
      },
      got_key => sub {
         my $key     = $_[ARG0];
         my $termkey = $_[HEAP]{termkey};

         print "Got key: ".$termkey->format_key( $key, FORMAT_VIM )."\n";

         # Gotta exit somehow.
         delete $_[HEAP]{termkey} if $key->type_is_unicode and
                                     $key->utf8 eq "C" and
                                     $key->modifiers & KEYMOD_CTRL;
      },
   }
);

POE::Kernel->run;
