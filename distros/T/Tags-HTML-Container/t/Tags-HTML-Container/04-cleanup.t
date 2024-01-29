use strict;
use warnings;

use Tags::HTML::Container;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Container->new;
my $ret = $obj->cleanup;
is($ret, undef, 'Run of cleanup (without callback).');
