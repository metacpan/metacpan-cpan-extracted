use strict;
use warnings;

use Tags::HTML::Footer;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Footer->new;
my $ret = $obj->cleanup;
is($ret, undef, 'Cleanup returns undef.');
