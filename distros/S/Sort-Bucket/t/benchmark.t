# This is primarily here as a very rough benchmark, but it also has some
# value as part of the test suite since it's checking that various large
# random arrays are sorted into the same order as CORE::sort(). 

use strict;
use warnings;

use Sort::Bucket qw(inplace_bucket_sort);
use Test::More;
use Time::HiRes;

our @timings;

foreach my $type (qw(digits binary)) {
    foreach my $len (10_000, 100_000, 200_000, 500_000, 1_000_000) {
        my $name = "$len $type";
        $name =~ s/000000 /M /;
        $name =~ s/000 /k /;

        my @array;
        if ($type eq 'digits') {
            for ( my $i=0 ; $i<$len ; $i++ ) {
                push @array, "" . int rand(1_000_000);
            }
        } else {
            for ( my $i=0 ; $i<$len ; $i++ ) {
                push @array, pack 'NN', rand(2**32), rand(2**32);
            }
        }

        compare_sorts(\@array, $name);
    }
}

diag "
  Benchmark  | CORE::sort() | Sort::Bucket |   Ratio\n" . join("\n", @timings);

done_testing;

sub compare_sorts {
    my ($array, $name, $bits) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @a = @$array;
    my $perl_took = timeit(sub{ @a = sort @a });
    my @perl_sorted = @a;

    @a = @$array;
    my $bucket_took = timeit(sub{
        inplace_bucket_sort(@a, $bits||0);
    });

    foreach my $i (0 .. $#perl_sorted) {
        unless ($a[$i] eq $perl_sorted[$i]) {
            ok 0, "$name disorder at elt $i";
            return;
        }
    }
    ok 1, "$name sorted order same as perl";

    push @timings, sprintf "%12s |%12.4gs |%12.4gs |%10.4g",
                 $name, $perl_took, $bucket_took, $perl_took/$bucket_took;
}

sub timeit {
    my $code = shift;

    my $start = Time::HiRes::time();
    $code->();
    my $end = Time::HiRes::time();

    return $end - $start;
}

