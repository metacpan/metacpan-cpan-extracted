use strict;
use warnings;

use Tags::HTML::InfoBox;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::InfoBox->new;
my $ret = $obj->cleanup;
is($ret, undef, 'Cleanup returns undef.');
