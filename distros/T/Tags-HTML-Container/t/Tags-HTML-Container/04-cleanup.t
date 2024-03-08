use strict;
use warnings;

use Tags::HTML::Container;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Container->new;
my $ret = $obj->cleanup;
is($ret, undef, 'Run of cleanup (without callback).');

# Test.
$obj = Tags::HTML::Container->new;
my $i = 0;
my $cb = sub { $i++ };
$ret = $obj->cleanup($cb);
is($ret, undef, 'Run of cleanup (with callback).');
is($i, 1, 'Get i value after call of callback (1).');
