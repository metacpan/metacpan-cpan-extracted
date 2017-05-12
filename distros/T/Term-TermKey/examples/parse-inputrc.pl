#!/usr/bin/perl

use strict;
use warnings;
use feature qw( say switch );

use Term::TermKey;

my $tk = Term::TermKey->new( undef );

my $path = shift @ARGV || "/etc/inputrc";
open my $rc, "<", $path or die "Cannot read $path - $!";

my @ifs;
while( <$rc> ) {
   chomp;
   given($_) {
      when( m/^#/ or m/^\s*$/ ) {
         # comment or blank
         say $_
      }
      when( m/^\$if ([^=]+)=(.*)$/ ) {
         print "  " x @ifs;
         say "\$if $1=$2";

         push @ifs, "$1=$2";
      }
      when( m/^\$endif$/ ) {
         pop @ifs;

         print "  " x @ifs;
         say "\$endif";
      }
      when( m/^set (\S+)\s+(.*)$/ ) {
         print "  " x @ifs;
         say "set $1 $2";
      }
      when( m/"(.*)": (.*)$/ ) {
         my ( $bytes, $binding ) = ( $1, $2 );

         # TODO: This probably needs a lot more work
         $bytes =~ s/\\e/\e/g;
         $bytes =~ s{\\C-(.)}{chr( 0x1f & ord $1)}eg;

         print "  " x @ifs;

         $tk->push_bytes( $bytes );
         while( $tk->getkey( my $key ) ) {
            print $tk->format_key( $key, Term::TermKey::FORMAT_VIM );
         }

         say ": $binding";
      }
      default {
         die "Not sure how to parse line $_\n";
      }
   }
}
