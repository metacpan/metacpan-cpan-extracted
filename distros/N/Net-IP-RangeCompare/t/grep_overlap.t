
use strict;
use warnings;
use Test::More tests =>3;
use Data::Dumper;
use lib qw(../lib);
use Net::IP::RangeCompare qw(:ALL);
our $p='Net::IP::RangeCompare';

{
my $ref=grep_overlap('10/24',[qw(10 10/32 9/24)]);
my $cmp=join ', ',@$ref;
ok($cmp eq '10, 10/32','grep_overlap 1');
}
{
my $ref=grep_overlap('10/24',[qw(9/24)]);
my $cmp=join ', ',@$ref;
ok($cmp eq '','grep_overlap 2');
}
{
my $ref=grep_non_overlap('10/24',[qw(10 10/32 9/24)]);
my $cmp=join ', ',@$ref;
ok($cmp eq '9/24','grep_non_overlap 1');
}
