

use strict;
use warnings;
use lib qw(../lib lib);
use Test::More tests =>16;
use Data::Dumper;
use Net::IP::RangeCompare qw(:ALL);
my $p='Net::IP::RangeCompare';

my $obj=Net::IP::RangeCompare->parse_new_range('0.0.0.0 - 0.0.0.6');

my ($first,$second,$third,$bad)=$obj->base_list_int;
ok($first==0,'1 int base check');
ok($second==4,'2 int base check');
ok($third==6,'3 int base check');
ok(!$bad,'$bad should be undef');
($first,$second,$third,$bad)=$obj->broadcast_list_int;
ok($first==3,'1 int broadcast check');
ok($second==5,'2 int broadcast check');
ok($third==6,'3 int broadcast check');
ok(!$bad,'$bad should be undef');

($first,$second,$third,$bad)=$obj->base_list_ip;
ok($first eq '0.0.0.0','1 int base check');
ok($second eq '0.0.0.4','2 int base check');
ok($third eq '0.0.0.6','3 int base check');
ok(!$bad,'$bad should be undef');
($first,$second,$third,$bad)=$obj->broadcast_list_ip;
ok($first eq '0.0.0.3','1 int broadcast check');
ok($second eq '0.0.0.5','2 int broadcast check');
ok($third eq '0.0.0.6','3 int broadcast check');
ok(!$bad,'$bad should be undef');
