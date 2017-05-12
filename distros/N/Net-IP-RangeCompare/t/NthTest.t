

use strict;
use warnings;
use lib qw(../lib lib);
use Test::More tests =>3;
use Data::Dumper;
use Net::IP::RangeCompare qw(:ALL);
my $p='Net::IP::RangeCompare';

my $obj=Net::IP::RangeCompare->parse_new_range('10/24');
my $base=$obj->nth(0);
my $broadcast=$obj->nth(255);

#print $base,"\n";
#print $broadcast,"\n";
ok($base eq '10.0.0.0','base check');
ok($broadcast eq '10.0.0.255','broadcast check');
ok(!$obj->nth(256),'undef check');
