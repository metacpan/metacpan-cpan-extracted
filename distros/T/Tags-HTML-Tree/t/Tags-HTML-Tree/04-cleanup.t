use strict;
use warnings;

use Tags::HTML::Tree;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Tree->new;
my $ret = $obj->cleanup;
is($ret, undef, 'Cleanup returns undef.');
