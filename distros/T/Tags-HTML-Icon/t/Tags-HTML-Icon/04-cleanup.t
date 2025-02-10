use strict;
use warnings;

use Tags::HTML::Icon;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Icon->new;
my $ret = $obj->cleanup;
is($ret, undef, 'Cleanup returns undef.');
