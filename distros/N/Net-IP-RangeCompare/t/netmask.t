
use strict;
use warnings;
use Test::More tests =>5;
use Data::Dumper;
use lib qw(../lib);
use Net::IP::RangeCompare qw(:ALL);
our $p='Net::IP::RangeCompare';

{
  my $range=Net::IP::RangeCompare->parse_new_range('10/24');
  my @masks=$range->netmask_int_list;
  ok($#masks==0,'netmask_int_list 1');
  ok($masks[0]==0xffffff00,'netmask_int_list 2');
}

{
  my $range=Net::IP::RangeCompare->new(0,4);
  my @masks=$range->netmask_list;
  ok($#masks==1,'netmask_int_list 3');
  ok($masks[0] eq '255.255.255.252','netmask_int_list 4');
  ok($masks[1] eq '255.255.255.255','netmask_int_list 5');
}
