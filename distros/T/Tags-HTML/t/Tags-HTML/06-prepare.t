use strict;
use warnings;

use Tags::HTML;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML->new;
my $ret = $obj->prepare;
is($ret, undef, 'Prepare returns undef.');
