#!/usr/bin/perl

package RT::Extension::SMSNotify::Shifts;

use strict;
use warnings;
use 5.10.1;

# Returns true if the passed time is within the shift bounds passed, where all
# arguments are in minutes since midnight.
#
# for timeinrange(t, a, b), if a>b then return true if t between a and b; otherwise return true if a NOT between b and a
#
sub _TimeInShiftRange {
    my ($nowminutes, $shiftstartutcmins, $shiftendutcmins) = @_;
    if ($nowminutes < 0 || $nowminutes >= 24*60) {
        die("now=$nowminutes is outside range 0 <= x < 1440");
    }
    
    my ($a, $b, $negated) = ($shiftstartutcmins, $shiftendutcmins, 0);
    if ($a > $b) {
        # Shfit wraps UTC midnight, so flip start and end and negate the result
        ($a, $b, $negated) = ($b, $a, 1);
    }
    return (($nowminutes >= $a && $nowminutes < $b) xor $negated);
}

# Quick tests for edge cases in _TimeInShiftRange
sub _TimeInShiftRangeTest {
    my @shift = (9*60+30, 17*60+30);
    die unless _TimeInShiftRange(9*60+30, @shift);       # Non UTC wrap, now=start (t)
    die if     _TimeInShiftRange(17*60+30, @shift);      # Non UTC wrap, now=end (f)
    die unless _TimeInShiftRange(12*60, @shift);         # Non UTC wrap, now=mid (t)
    die if     _TimeInShiftRange(9*60, @shift);          # Non UTC wrap, now=beforestart (f)
    die if     _TimeInShiftRange(18*60, @shift);         # Non UTC wrap, now=afterend (f)
    my @wrapshift = (22*60, 4*60);
    die if     _TimeInShiftRange(9*60, @wrapshift);      # UTC wrap, now=mid (f)
    die unless _TimeInShiftRange(2*60, @wrapshift);      # UTC wrap, now=beforestart (t)
    die unless _TimeInShiftRange(23*60, @wrapshift);     # UTC wrap, now=afterend (t)
    die unless _TimeInShiftRange(22*60, @wrapshift);     # UTC wrap, now=start (t)
    die if     _TimeInShiftRange(4*60, @wrapshift);      # UTC wrap, now=end (f)
    die unless _TimeInShiftRange(0, @wrapshift);         # UTC wrap, now=0 (t)
};

1;
