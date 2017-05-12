#!perl

use strict;
use warnings;
use Test::More tests => 4;
use Net::CIDR::Set;
use Data::Dumper;

{
  my $s1 = Net::CIDR::Set->new( '0.0.0.0-0.0.0.255',
    '0.0.2.0-255.255.255.255' );
  my $s2 = Net::CIDR::Set->new( '0.0.1.0-0.0.1.255' );
  my $s3 = $s1->union( $s2 );
  is_deeply [ $s3->as_cidr_array ], ['0.0.0.0/0'], 'union';
  my $s4 = $s1->intersection( $s2 );
  is_deeply [ $s4->as_cidr_array ], [], 'intersection';
  my $s5 = $s1->complement->union( $s2->complement->union );
  is_deeply [ $s5->as_cidr_array ], ['0.0.0.0/0'], 'complement + union';
  my $s6 = $s1->complement->intersection( $s2->complement );
  is_deeply [ $s6->as_cidr_array ], [], 'complement + intersection';
}

# vim:ts=2:sw=2:et:ft=perl

