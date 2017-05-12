#!perl

use strict;
use warnings;
use Test::More tests => 10;
use Net::CIDR::Set;

{
  ok defined( my $set = Net::CIDR::Set->new ), "set created OK";
  isa_ok $set, 'Net::CIDR::Set';
  $set->add( '127.0.0.1' );
  my @got = $set->as_address_array;
  is_deeply [@got], ['127.0.0.1'], "got address";
}

{
  my $set = Net::CIDR::Set->new;
  $set->add( '192.168.0.0/16' );
  {
    my @got = $set->as_cidr_array;
    is_deeply [@got], ['192.168.0.0/16'], "got cidr";
  }
  $set->remove( '192.168.0.65' );
  {
    my @got = $set->as_range_array;
    is_deeply [@got],
     [ '192.168.0.0-192.168.0.64', '192.168.0.66-192.168.255.255' ],
     "got range";
    my $s2 = Net::CIDR::Set->new( @got );
    ok $set->equals( $s2 ), "can reparse";
  }
  {
    my @got = $set->as_cidr_array;
    is_deeply [@got],
     [
      '192.168.0.0/26',  '192.168.0.64',
      '192.168.0.66/31', '192.168.0.68/30',
      '192.168.0.72/29', '192.168.0.80/28',
      '192.168.0.96/27', '192.168.0.128/25',
      '192.168.1.0/24',  '192.168.2.0/23',
      '192.168.4.0/22',  '192.168.8.0/21',
      '192.168.16.0/20', '192.168.32.0/19',
      '192.168.64.0/18', '192.168.128.0/17'
     ],
     "got cidr";
    my $s2 = Net::CIDR::Set->new( @got );
    ok $set->equals( $s2 ), "can reparse";
  }
}

{
  my @private = map { Net::CIDR::Set->new( $_ ) } '10.0.0.0/8',
   '192.168.0.0/16', '172.16.0.0/12';
  my $all_priv = Net::CIDR::Set->new;
  for my $priv ( @private ) {
    $all_priv = $all_priv->union( $priv );
  }
  my @got = $all_priv->as_cidr_array;
  is_deeply [@got],
   [ '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16', ],
   "union";
}

{
  my $s1  = Net::CIDR::Set->new( '10.0.0.0/9' );
  my $s2  = Net::CIDR::Set->new( '10.128.0.0/9' );
  my $hit = $s1->intersection( $s2 );
  ok $hit->is_empty, "no intersection" or diag "got $hit";
}

# vim:ts=2:sw=2:et:ft=perl
