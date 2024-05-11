use strict;
use warnings;

use Tags::HTML::Navigation::Grid;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Navigation::Grid->new;
my $ret = $obj->cleanup;
is($ret, undef, 'Run of cleanup (without callback).');
