#!/usr/bin/perl -w

use strict;

use String::Tagged;

my $CSI = "\e[";

while( my $line = <STDIN> ) {
   my $str = String::Tagged->new( $line );

   # Every capital letter red
   pos $line = 0;
   while( $line =~ m/[A-Z]/g ) {
      $str->apply_tag( $-[0], 1, fg => 1 );
   }

   # Punctuation green
   pos $line = 0;
   while( $line =~ m/[[:punct:]]/g ) {
      $str->apply_tag( $-[0], 1, fg => 2 );
   }

   # Numbers blue
   pos $line = 0;
   while( $line =~ m/\d+/g ) {
      $str->apply_tag( $-[0], $+[0]-$-[0], fg => 4 );
   }

   # Underline whole words
   pos $line = 0;
   while( $line =~ m/\S+/g ) {
      $str->apply_tag( $-[0], $+[0]-$-[0], u => 1 );
   }

   print STDERR $str->debug_sprintf;

   my %pen;

   $str->iter_substr_nooverlap( sub {
      my ( $substr, %tags ) = @_;

      my @SGR;

      if( defined( my $fg = $tags{fg} ) ) {
         push @SGR, $fg+30;
         $pen{fg} = $fg;
      }
      elsif( exists $pen{fg} ) {
         push @SGR, 39;
         delete $pen{fg};
      }

      if( $tags{u} and !$pen{u} ) {
         push @SGR, 4;
         $pen{u} = 1;
      }
      elsif( !$tags{u} and $pen{u} ) {
         push @SGR, 24;
         delete $pen{u};
      }

      print "${CSI}".join(";", @SGR)."m" if @SGR;

      print $substr;
   } );

   print "${CSI}m\n";
}
