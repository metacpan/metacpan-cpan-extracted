#!/usr/bin/perl -w

use strict;
use warnings;

use Term::TermKey qw( FLAG_UTF8 RES_EOF FORMAT_LONGMOD );

my $tk = Term::TermKey->new(\*STDIN);

# ensure perl and libtermkey agree on Unicode handling
binmode( STDOUT, ":encoding(UTF-8)" ) if $tk->get_flags & FLAG_UTF8;

my $line = "";

$| = 1;

my %key_handlers = (
   "Enter"  => sub { 
     print "\nThe line is: $line\n";
     $line = "";
  },

   "Backspace" => sub {
      return unless length $line;
      substr( $line, -1, 1 ) = "";
      print "\cH \cH"; # erase it
   },

   # other handlers ...
);

while( ( my $ret = $tk->waitkey( my $key ) ) != RES_EOF ) {
   my $handler = $key_handlers{ $tk->format_key( $key, FORMAT_LONGMOD ) };
   if( $handler ) {
      $handler->( $key );
   }
   elsif( $key->type_is_unicode and !$key->modifiers ) {
      my $char = $key->utf8;

      $line .= $char;
      print $char;
   }
}
