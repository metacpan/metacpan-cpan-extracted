use strict;
use warnings;

use Tags::HTML::Container;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Container->new;
my $ret = $obj->prepare;
is($ret, undef, 'Run of prepare (without cleanup).');

# Test.
$obj = Tags::HTML::Container->new;
my $i = 0;
my $cb = sub { $i++ };
$ret = $obj->prepare($cb);
is($ret, undef, 'Run of prepare (with callback).');
is($i, 1, 'Get i value after call of callback (1).');
