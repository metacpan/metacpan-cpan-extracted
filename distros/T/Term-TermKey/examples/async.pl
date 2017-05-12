#!/usr/bin/perl -w

use strict;
use warnings;

use IO::Select;
use Term::TermKey qw(
   FLAG_UTF8 RES_KEY RES_AGAIN RES_EOF FORMAT_VIM
);

my $select = IO::Select->new();

my $tk = Term::TermKey->new(\*STDIN);
$select->add(\*STDIN);

# ensure perl and libtermkey agree on Unicode handling
binmode( STDOUT, ":encoding(UTF-8)" ) if $tk->get_flags & FLAG_UTF8;

sub on_key
{
   my ( $tk, $key ) = @_;

   print "You pressed " . $tk->format_key( $key, FORMAT_VIM ) . "\n";
}

my $again = 0;

while(1) {
   my $timeout = $again ? $tk->get_waittime/1000 : undef;
   my @ready = $select->can_read($timeout);

   if( !@ready ) {
      my $ret;
      while( ( $ret = $tk->getkey_force( my $key ) ) == RES_KEY ) {
         on_key( $tk, $key );
      }
   }

   while( my $fh = shift @ready ) {
      if( $fh == \*STDIN ) {
         $tk->advisereadable;
         my $ret;
         while( ( $ret = $tk->getkey( my $key ) ) == RES_KEY ) {
            on_key( $tk, $key );
         }

         $again = ( $ret == RES_AGAIN );
         exit if $ret == RES_EOF;
      }
      # Deal with other filehandles here
   }
}
