use strict;
use warnings;

use Tags::HTML::Element::Option;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Element::Option->new;
my $ret = $obj->cleanup;
is($ret, undef, 'Cleanup returns undef.');
