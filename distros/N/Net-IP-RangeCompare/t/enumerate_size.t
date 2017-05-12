

use strict;
use warnings;
use lib qw(../lib lib);
use Test::More tests =>8;
use Data::Dumper;
use Net::IP::RangeCompare qw(:ALL);
my $p='Net::IP::RangeCompare';
  my $obj=Net::IP::RangeCompare->parse_new_range('10.0.0.0 - 10.0.0.6');

  my $sub=$obj->enumerate_size;
  ok($sub->() eq '10.0.0.0 - 10.0.0.1','enumerate by 1 check 1');
  ok($sub->() eq '10.0.0.2 - 10.0.0.3','enumerate by 1 check 2');
  ok($sub->() eq '10.0.0.4 - 10.0.0.5','enumerate by 1 check 3');
  ok($sub->() eq '10.0.0.6 - 10.0.0.6','enumerate by 1 check 4');
  ok(!$sub->(),'enumerate end check');



  $sub=$obj->enumerate_size(3);
  ok($sub->() eq '10.0.0.0 - 10.0.0.3','enumerate by 3 check 1');
  ok($sub->() eq '10.0.0.4 - 10.0.0.6','enumerate by 3 check 2');
  ok(!$sub->(),'enumerate end check');

