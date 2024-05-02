use strict;
use warnings;

use Tags::HTML::Tree;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Tree->new;
my $script_js_ar = $obj->script_js;
is(scalar @{$script_js_ar}, 0, 'No one JavaScript.');
my $ret = $obj->prepare;
is($ret, undef, 'Prepare returns undef.');
$script_js_ar = $obj->script_js;
is(scalar @{$script_js_ar}, 1, 'One JavaScript code prepared.');
