use strict;
use warnings;
use utf8;

use Test::Tester;
use Test::More 0.98;
use Test::Deep;
use Test::Deep::ArrayEachNotEmpty;

my $empty = [];
my $array = [{ foo => 1 }];

my $array_each           = array_each({ foo => 1 });
my $array_each_not_empty = array_each_not_empty({ foo => 1 });

check_test(sub { cmp_deeply $empty, $array_each           }, { ok => 1 });
check_test(sub { cmp_deeply $array, $array_each           }, { ok => 1 });
check_test(sub { cmp_deeply $empty, $array_each_not_empty }, { ok => 0 });
check_test(sub { cmp_deeply $array, $array_each_not_empty }, { ok => 1 });

done_testing;

