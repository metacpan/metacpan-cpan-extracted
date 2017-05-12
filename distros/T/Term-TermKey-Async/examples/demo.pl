#!/usr/bin/perl

use strict;
use warnings;

use Term::TermKey::Async qw( FORMAT_VIM KEYMOD_CTRL FLAG_NOINTERPRET );
use IO::Async::Loop;

my $loop = IO::Async::Loop->new();

my $no_int = 0;

my $tka = Term::TermKey::Async->new(
   on_key => sub {
      my ( $self, $key ) = @_;

      print "Got key: ".$self->format_key( $key, FORMAT_VIM )."\n";

      $loop->loop_stop if $key->type_is_unicode && 
                          lc $key->utf8 eq "c" &&
                          $key->modifiers & KEYMOD_CTRL;

      if( $key->type_is_unicode and lc $key->utf8 eq "n" and $key->modifiers & KEYMOD_CTRL ) {
         $no_int ^= 1;
         $self->configure( flags => ( $no_int ? FLAG_NOINTERPRET : 0 ) );
      }
   },
);

$loop->add( $tka );

$loop->loop_forever;
