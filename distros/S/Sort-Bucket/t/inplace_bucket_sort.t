# Check that inplace_bucket_sort sorts the same way as CORE::sort

use strict;
use warnings;

use Devel::Refcount qw(refcount);
use Digest::MD5 qw(md5_hex);
use List::Util qw(shuffle);
use Test::Group;
use Test::Group::Foreach;
use Test::More;

use Sort::Bucket qw(inplace_bucket_sort);

test_sort([], 'empty array');

{
    my @byte_strings = (
        empty => '',
        0     => '0',
        x     => 'x',
        X     => 'X',
        foo   => 'foo',
        longx => "qwertyuiop9991x",
        longy => "qwertyuiop9991y",
        127   => chr(127),
        128   => chr(128),
        129   => chr(129),
        190   => chr(190),
        191   => chr(191),
        192   => chr(192),
        254   => chr(254),
        255   => chr(255),
        allch => join('', map {chr($_)} (0 .. 255)),
    );
    my @extra;
    for ( my $i=0 ; $i<$#byte_strings ; $i+=2 ) {
        push @extra, $byte_strings[$i]."NULL" => $byte_strings[$i+1]."\0";
    }
    push @byte_strings, @extra;

    next_test_foreach my $x, 'x', \@byte_strings;
    test_sort([\$x], "one elt", 18, 1);

    next_test_foreach my $y, 'y', \@byte_strings;
    next_test_foreach my $z, 'z', \@byte_strings;
    test_sort([\$y, \$z], "two elts", 10, 1);
}

test_sort([split //, 'qwertyuiop'], 'qwerty');

{
    my @many_strings = (
        '',
        map({chr $_} 0..255), 
        map({pack 'n', $_} 0..2**16-1),
        map({chr($_) x 3} 0..255), 
        map({chr($_) x 4} 0..255), 
        qw(123 1234 12345 123456 12345678 123456789),
        qw(zzz zzzz zzzzz zzzzzz zzzzzzz zzzzzzzz),
        "\xFF"x3, "\xFF"x4, "\xFF"x5, "\xFF"x6, "\xFF"x7, "\xFF"x8,
        "\x00"x3, "\x00"x4, "\x00"x5, "\x00"x6, "\x00"x7, "\x00"x8,
        map({md5_hex($_)} 1..1000), 
    );
    test_sort(\@many_strings, "many");
    test_sort([reverse @many_strings], "revmany");
    test_sort([shuffle @many_strings], "shufmany");
}
         
done_testing;

sub test_sort {
    my ($array, $name, $max_bits, $dereference_elts) = @_;
    defined $max_bits or $max_bits = 18;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    # Check that inplace_bucket_sort sorts in cmp() order and is stable,
    # and that it re-arranges the SVs in the array rather than creating
    # new SVs, and that it preserves the values of the SVs.

    # Try it for various numbers of major bits
    next_test_foreach my $bits, 'b', 0 .. $max_bits;

    # Try it with and without converting the byte strings to char strings.
    next_test_foreach my $use_char_strings, 'c', 0, 1;

    test $name => sub {
        my @a = @$array;
        if ($dereference_elts) {
            @a = map {$$_} @a;
        }
        if ($use_char_strings) {
            @a = map {defined($_) ? $_.chr(256) : $_} @a;
        }

        my @want;
        foreach my $i (0 .. $#a) {
            my $ref = \$a[$i];
            push @want, [$a[$i], $i, "$ref,$a[$i]"];
        }

        @want = map {$_->[2]}
                sort { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] } @want;

        inplace_bucket_sort @a, $bits;

        is scalar(@a), scalar(@want), "len correct after sort" or return;
        foreach my $i (0 .. $#a) {
            my $ref = \$a[$i];
            my $got = "$ref,$a[$i]";
            if ($got ne $want[$i]) {
                is $got, $want[$i], "elt $i same";
                return;
            }
            if (refcount($ref) != 2) {
                # 1 for the array, 1 for $ref
                is refcount($ref), 2, "elt $i refcount";
                return;
            }
        }
        ok 1, "array as expected";
    };
}

