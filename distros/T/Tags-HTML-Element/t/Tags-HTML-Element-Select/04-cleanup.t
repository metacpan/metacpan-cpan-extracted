use strict;
use warnings;

use Tags::HTML::Element::Select;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Element::Select->new;
my $ret = $obj->cleanup;
is($ret, undef, 'Cleanup returns undef.');
