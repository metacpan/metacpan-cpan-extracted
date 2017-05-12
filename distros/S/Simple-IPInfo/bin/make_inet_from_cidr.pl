#!/usr/bin/perl
use strict;
use warnings;

use Net::CIDR qw/cidr2range/;
use Socket qw/inet_aton/;
use Data::Dumper;

my ( $src, $dst, $h ) = @ARGV;
exit unless ( -f $src );

$dst //= "$src.inet";

open my $fh,  '<', $src;
open my $fhw, '>', $dst;

if(!$h){
    chomp( $h = <$fh> );
}
my @head = split ',', $h;
shift @head;

print $fhw join( ",", 's', 'e', @head ), "\n";
while ( <$fh> ) {
  chomp;
  my @d = m#("[^"]*",|[^,]*,|[^,]+$)#g;
  push @d, '' if(/,$/);
  s/,$//  for @d;
  s/"//g  for @d;
  s/,/ /g for @d;

  my @inf = cidr2range( "$d[0]" );
  my ( $s_ip, $e_ip ) = split '-', $inf[0], -1;
  my $s_inet = unpack( 'N', inet_aton( $s_ip ) ) ;
  my $e_inet = $e_ip ? unpack( 'N', inet_aton( $e_ip ) ) : ($s_inet+255);
  shift @d;
  print $fhw join( ",", $s_inet, $e_inet, @d ), "\n";
}
close $fhw;
close $fh;
