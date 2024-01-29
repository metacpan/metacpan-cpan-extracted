use strict;
use warnings;

use Tags::HTML::Element::Form;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Element::Form->new;
my $ret = $obj->cleanup;
is($ret, undef, 'Cleanup returns undef.');
