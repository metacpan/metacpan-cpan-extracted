#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1262;
use Sort::Packed qw(radixsort_packed mergesort_packed mergesort_packed_custom);

my %can;

for my $format (qw(n v N V i I j J f d F D q Q)) {
    eval { my $ignore = pack $format, 1; $can{$format} = 1 };
}

# here we check how portable negative zeros are!

my $nzero = unpack f => pack f => -1e-300;
ok($nzero == -$nzero, "nzero == -nzero");
ok(($nzero || 1) == 1, "nzero is false");
# is($nzero, '-0');

sub no_neg_zero { map { abs($_) == 0 ? 0 : $_ } @_ }

sub test_sort_packed {
    my ($sorter, $dir, $format, $rep, $data) = @_;
 SKIP: {
        skip "format $format not supported", 1 unless $can{$format};
        my $packed = pack "$format*", ((@$data) x $rep);
        my @data = unpack "$format*", $packed;
        $packed = pack "$format*", @data;
        my @sorted = no_neg_zero( $dir eq '-'
                                  ? (sort { $b <=> $a } @data)
                                  : (sort { $a <=> $b } @data) );
        if ($sorter eq 'radix') {
            radixsort_packed "$dir$format", $packed;
        }
        elsif ($sorter eq 'merge') {
            mergesort_packed "$dir$format", $packed;
        }
        else {
            mergesort_packed_custom { (unpack $format,$a)[0] <=> (unpack $format,$b)[0] } "$dir$format", $packed;
        }
        my @unpacked = no_neg_zero(unpack "$format*", $packed);
        my $r = is_deeply(\@unpacked, \@sorted,
                          "$format ".scalar(@data)." x $rep");
        unless ($r) {
            # print STDERR "n: @sorted\np: @unpacked\n\n";
            if (open my $out, '>>', '/tmp/sort-packed.data') {
                s/(Inf)/'$1'/gi for @data;
                print $out "\$format='$format';\n";
                print $out "\@data=(", join(',', @data), ");\n";
                print $out "test(\$format, \@data);\n\n";
            }
        }
    }
    1;
}

for my $len (1, 2, 4, 20, 100) {
    my @int = map { (2 ** 32) * rand } 1..$len;

    my @double = map {
        my $m = sprintf "%f", 1 - 2 * rand;
        my $e = int(300 - 600 * rand);
        my $v1 = "${m}E${e}";
        0 + $v1
    } 1..$len;

    for my $sorter (qw(radix merge custom)) {
        for my $rep (1, 4) {
            for my $dir ('', '+', '-') {
                test_sort_packed $sorter, $dir, n => $rep, \@int;
                test_sort_packed $sorter, $dir, v => $rep, \@int;
                test_sort_packed $sorter, $dir, N => $rep, \@int;
                test_sort_packed $sorter, $dir, V => $rep, \@int;
                test_sort_packed $sorter, $dir, i => $rep, \@int;
                test_sort_packed $sorter, $dir, I => $rep, \@int;
                test_sort_packed $sorter, $dir, j => $rep, \@int;
                test_sort_packed $sorter, $dir, J => $rep, \@int;
                test_sort_packed $sorter, $dir, q => $rep, \@int;
                test_sort_packed $sorter, $dir, Q => $rep, \@int;
                test_sort_packed $sorter, $dir, f => $rep, \@double;
                test_sort_packed $sorter, $dir, d => $rep, \@double;
                test_sort_packed $sorter, $dir, F => $rep, \@double;
                test_sort_packed $sorter, $dir, D => $rep, \@double;
            }
        }
    }
}
