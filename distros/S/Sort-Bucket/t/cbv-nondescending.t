# Testing src/calculate-bucket-values.c
# Check that the bucket values for a sorted list of strings form a
# non-descending sequence.

use strict;
use warnings;

use Test::More tests => 2;
use Test::Group;
use Test::Group::Foreach;
use Sort::Bucket;

# The bucket value sequence should remain non-descending if the same prefix
# is applied to each of the sorted strings, since they remain in sorted
# order.  We'll try it with a range of prefixes.
my $prefix_set = [
    empty => '',
    null1 => "\0",
    x     => "x",
    FF    => "\xFF",
    null2 => "\0\0",
    FF2   => "\xFF\xFF",
    3     => "\0\x80\xFF",
    null4 => "\0\0\0\0",
    5     => "\xFF\0\xFF\0\xFF",
    6     => "abcdef",
    FF7   => ("\xFF" x 7),
    null8 => ("\0" x 8),
    9     => ("9" x 9),
];

# Some byte strings to test with.
my @byte_strings = sort
    '',
    map({chr $_} 0 .. 255),
    map({pack 'n', $_} 0 .. 2**16-1),
    map({"\0" x $_} 3 .. 8),
    map({"\xFF" x $_} 3 .. 8),
    qw(foo bar baz 123 1234 12345 123456 1234567 12345678 123456789),
    qw(zzz zzzz zzzzz zzzzzz zzzzzzz zzzzzzzz zzzzzzzzz),
;
bucket_values_nondescending_ok("bytes", \@byte_strings, $prefix_set);


# It should also work with char strings, so long as we don't mix char
# strings and byte strings in a single input set.
my @char_strings = sort 
    map({$_ . chr(256)} @byte_strings),
    chr(512),
    "\x{07FF}",
    "\x{227A}",
    "\x{227B}",
    "\x{0800}",
    "\x{10000}",
;
bucket_values_nondescending_ok("chars", \@char_strings, $prefix_set);

###########################################################################

sub bucket_values_nondescending_ok {
    my ($name, $sorted, $prefix_set) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    # Check that bucket values are non-descending for the specified
    # sorted list, repeating the check for each prefix and for each
    # valid major bit count.

    next_test_foreach my $bits,   'b', 1 .. 31;
    next_test_foreach my $prefix, 'p', $prefix_set;

    test $name => sub {
        my $disorder_at = 
          Sort::Bucket::_cbv_testharness_check_for_descending(@$sorted, $bits);
        if ($disorder_at) {
            ok 0, "descending at $disorder_at";
        } else {
            ok 1, "non-descending";
        }
    };
}

