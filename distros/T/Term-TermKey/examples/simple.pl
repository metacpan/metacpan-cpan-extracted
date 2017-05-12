#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Term::TermKey qw( FLAG_UTF8 RES_EOF FORMAT_VIM FORMAT_MOUSE_POS );

my $mouse;
GetOptions(
   'm|mouse=i' => \$mouse
) or exit(1);

$|++;

if( $mouse ) {
   print "\e[?${mouse}h";
}

$SIG{WINCH} = sub { print "Window resize\n" };

my $tk = Term::TermKey->new(\*STDIN);

# ensure perl and libtermkey agree on Unicode handling
binmode( STDOUT, ":encoding(UTF-8)" ) if $tk->get_flags & FLAG_UTF8;

while( ( my $ret = $tk->waitkey( my $key ) ) != RES_EOF ) {
   if( $key->type_is_mouse ) {
      printf "Got mouse: %s(%d) at (%d,%d)\n", [qw( * press drag release )]->[$key->mouseev],
         $key->button, $key->line, $key->col;
   }
   elsif( $key->type_is_position ) {
      printf "Got position report: at (%d,%d)\n", $key->line, $key->col;
   }
   else {
      print "Got key: ".$tk->format_key( $key, FORMAT_VIM )."\n";

      if( $key->type_is_unicode && !$key->modifiers && $key->utf8 eq "?" ) {
         print "\e[6n";
      }
   }
}

if( $mouse ) {
   print "\e[?${mouse}l";
}
