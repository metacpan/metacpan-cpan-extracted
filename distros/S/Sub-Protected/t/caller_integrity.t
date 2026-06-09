use strict;
use warnings;
use Test::Most;
use Sub::Protected;

# Test 9: caller() inside a protected sub body returns the real caller,
# not the Sub::Protected wrapper frame (validates goto &$coderef).

local $ENV{HARNESS_ACTIVE}    = 0;
local $Sub::Protected::BYPASS = 0;

{
    package CIFoo;
    use Sub::Protected;

    my @captured;
    sub new            { bless {}, shift }
    sub _capture       :Protected { @captured = (caller(0))[0..2]; 1 }
    sub invoke_capture { (shift)->_capture }
    sub get_captured   { @captured }
}

my $obj = CIFoo->new;
$obj->invoke_capture;

my @info = CIFoo::get_captured();

# If goto is working, the wrapper frame vanishes: caller(0) inside _capture
# should show CIFoo (invoke_capture), not Sub::Protected.
is   $info[0], 'CIFoo',          'caller(0) package is CIFoo, not Sub::Protected';
isnt $info[0], 'Sub::Protected', 'Sub::Protected wrapper is invisible in caller()';

done_testing;
