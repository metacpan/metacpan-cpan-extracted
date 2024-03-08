use strict;
use warnings;

use Tags::HTML::Container;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Container->new;
my $ret = $obj->init;
is($ret, undef, 'Run of init (without callback).');

# Test.
$obj = Tags::HTML::Container->new;
my $i = 0;
my $cb = sub { $i++ };
$ret = $obj->init($cb);
is($ret, undef, 'Run of init (with callback).');
is($i, 1, 'Get i value after call of callback (1).');
