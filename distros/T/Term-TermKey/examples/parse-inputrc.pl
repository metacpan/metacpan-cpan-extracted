#!/usr/bin/perl

use v5.14;
use warnings;

use Term::TermKey;

my $tk = Term::TermKey->new( undef );

my $path = shift @ARGV || "/etc/inputrc";
open my $rc, "<", $path or die "Cannot read $path - $!";

my @ifs;
while( <$rc> ) {
   chomp;
   for($_) {
      if( m/^#/ or m/^\s*$/ ) {
         # comment or blank
         say $_
      }
      elsif( m/^\$if ([^=]+)=(.*)$/ ) {
         print "  " x @ifs;
         say "\$if $1=$2";

         push @ifs, "$1=$2";
      }
      elsif( m/^\$endif$/ ) {
         pop @ifs;

         print "  " x @ifs;
         say "\$endif";
      }
      elsif( m/^set (\S+)\s+(.*)$/ ) {
         print "  " x @ifs;
         say "set $1 $2";
      }
      elsif( m/"(.*)": (.*)$/ ) {
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
      else {
         die "Not sure how to parse line $_\n";
      }
   }
}
