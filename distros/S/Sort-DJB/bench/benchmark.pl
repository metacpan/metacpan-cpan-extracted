#!/usr/bin/perl
#
# Benchmark: djbsort C (via XS) vs CPAN sorting modules vs Perl builtin sort
#
# Compares:
#   XS_      - Sort::DJB C library via XS (AVX2 bitonic sorting network)
#   Pure_    - Sort::DJB Pure Perl (bitonic sorting network in Perl)
#   Perl_    - Perl builtin sort { $a <=> $b }
#   SKey_    - Sort::Key (XS mergesort with C-level key caching)
#   Radix_   - Sort::Key::Radix (XS O(n) radix sort)
#   Packed_  - Sort::Packed (pack + sort_packed + unpack full pipeline)
#   PackedR_ - Sort::Packed (raw pre-packed buffer, sort only)
#

use strict;
use warnings;
use Benchmark qw(:all);
use FindBin qw($Bin);
use lib "$Bin/../blib/lib", "$Bin/../blib/arch", "$Bin/../lib",
        "$ENV{HOME}/perl5/lib/perl5";

use Sort::DJB;
use Sort::DJB::Pure;

# Optional CPAN modules -- detect availability
my $have_sort_key = eval { require Sort::Key; 1 };
my $have_radix    = eval { require Sort::Key::Radix; 1 };
my $have_packed   = eval { require Sort::Packed; Sort::Packed->import('sort_packed'); 1 };

print "=" x 72, "\n";
print "Sort::DJB Benchmark: C (XS) vs CPAN modules vs Perl builtin sort\n";
print "=" x 72, "\n\n";

# Library info
printf "djbsort version       : %s\n", Sort::DJB::version();
printf "djbsort arch          : %s\n", Sort::DJB::arch();
printf "int32 implementation  : %s\n", Sort::DJB::int32_implementation();
printf "int32 compiler        : %s\n", Sort::DJB::int32_compiler();
printf "int64 implementation  : %s\n", Sort::DJB::int64_implementation();
printf "int64 compiler        : %s\n", Sort::DJB::int64_compiler();
printf "Perl version          : %s\n", $^V;
printf "Sort::Key             : %s\n", $have_sort_key ? "v$Sort::Key::VERSION" : "not installed";
printf "Sort::Key::Radix      : %s\n", $have_radix ? "v$Sort::Key::Radix::VERSION" : "not installed";
printf "Sort::Packed          : %s\n", $have_packed ? "v$Sort::Packed::VERSION" : "not installed";
print "\n";

my @sizes = (10, 100, 1_000, 10_000, 100_000);
my $bench_time = -3;  # negative = run for 3 CPU seconds per benchmark

# Generate test data
sub gen_int32_data {
    my ($n) = @_;
    return [map { int(rand(2_000_000_000)) - 1_000_000_000 } 1 .. $n];
}

sub gen_uint32_data {
    my ($n) = @_;
    return [map { int(rand(4_000_000_000)) } 1 .. $n];
}

sub gen_int64_data {
    my ($n) = @_;
    return [map { int(rand(2_000_000_000_000)) - 1_000_000_000_000 } 1 .. $n];
}

sub gen_float64_data {
    my ($n) = @_;
    return [map { rand(2000.0) - 1000.0 } 1 .. $n];
}

# ============================================================
# Sanity check: verify all sorters produce correct results
# ============================================================
{
    my @test = (42, -7, 100, 0, -999, 55, 3);
    my @expected = sort { $a <=> $b } @test;

    my $xs = Sort::DJB::sort_int32([@test]);
    die "Sort::DJB XS sanity check failed" unless "@$xs" eq "@expected";

    my $pp = Sort::DJB::Pure::sort_int32([@test]);
    die "Sort::DJB Pure sanity check failed" unless "@$pp" eq "@expected";

    if ($have_sort_key) {
        my @sk = Sort::Key::nsort(@test);
        die "Sort::Key sanity check failed" unless "@sk" eq "@expected";
    }

    if ($have_radix) {
        my @rx = Sort::Key::Radix::isort(@test);
        die "Sort::Key::Radix sanity check failed" unless "@rx" eq "@expected";
    }

    if ($have_packed) {
        my $buf = pack("l*", @test);
        sort_packed('l', $buf);
        my @pk = unpack("l*", $buf);
        die "Sort::Packed sanity check failed" unless "@pk" eq "@expected";
    }

    print "Sanity check: all sorters produce correct results.\n\n";
}

# ============================================================
# Benchmark: int32 sorting
# ============================================================
print "-" x 72, "\n";
print "BENCHMARK: int32 sorting (signed 32-bit integers)\n";
print "-" x 72, "\n\n";

for my $n (@sizes) {
    my $data = gen_int32_data($n);

    printf "  n = %7d elements:\n", $n;

    my $bench = {
        "XS_int32"  => sub { Sort::DJB::sort_int32($data) },
        "Perl_sort" => sub { my @sorted = sort { $a <=> $b } @$data },
    };

    # Include Pure Perl only for sizes <= 10,000 (too slow at 100k)
    $bench->{"Pure_int32"} = sub { Sort::DJB::Pure::sort_int32($data) }
        if $n <= 10_000;

    $bench->{"SKey_nsort"} = sub { my @sorted = Sort::Key::nsort(@$data) }
        if $have_sort_key;

    $bench->{"Radix_isort"} = sub { my @sorted = Sort::Key::Radix::isort(@$data) }
        if $have_radix;

    $bench->{"Packed_int32"} = sub {
        my $buf = pack("l*", @$data);
        sort_packed('l', $buf);
        my @sorted = unpack("l*", $buf);
    } if $have_packed;

    my $results = timethese($bench_time, $bench, 'none');
    cmpthese($results);
    print "\n";
}

# ============================================================
# Benchmark: int32 descending sort
# ============================================================
print "-" x 72, "\n";
print "BENCHMARK: int32down sorting (signed 32-bit integers, descending)\n";
print "-" x 72, "\n\n";

for my $n (100, 10_000, 100_000) {
    my $data = gen_int32_data($n);

    printf "  n = %7d elements:\n", $n;

    my $bench = {
        "XS_int32dn"   => sub { Sort::DJB::sort_int32down($data) },
        "Perl_sort_rv" => sub { my @sorted = sort { $b <=> $a } @$data },
    };

    $bench->{"Pure_int32dn"} = sub { Sort::DJB::Pure::sort_int32down($data) }
        if $n <= 10_000;

    $bench->{"SKey_rnsort"} = sub { my @sorted = Sort::Key::rnsort(@$data) }
        if $have_sort_key;

    $bench->{"Radix_risrt"} = sub { my @sorted = Sort::Key::Radix::risort(@$data) }
        if $have_radix;

    my $results = timethese($bench_time, $bench, 'none');
    cmpthese($results);
    print "\n";
}

# ============================================================
# Benchmark: uint32 sorting
# ============================================================
print "-" x 72, "\n";
print "BENCHMARK: uint32 sorting (unsigned 32-bit integers)\n";
print "-" x 72, "\n\n";

for my $n (100, 10_000, 100_000) {
    my $data = gen_uint32_data($n);

    printf "  n = %7d elements:\n", $n;

    my $bench = {
        "XS_uint32" => sub { Sort::DJB::sort_uint32($data) },
        "Perl_sort" => sub { my @sorted = sort { $a <=> $b } @$data },
    };

    $bench->{"Pure_uint32"} = sub { Sort::DJB::Pure::sort_uint32($data) }
        if $n <= 10_000;

    $bench->{"SKey_nsort"} = sub { my @sorted = Sort::Key::nsort(@$data) }
        if $have_sort_key;

    $bench->{"Radix_usort"} = sub { my @sorted = Sort::Key::Radix::usort(@$data) }
        if $have_radix;

    $bench->{"Packed_u32"} = sub {
        my $buf = pack("L*", @$data);
        sort_packed('L', $buf);
        my @sorted = unpack("L*", $buf);
    } if $have_packed;

    my $results = timethese($bench_time, $bench, 'none');
    cmpthese($results);
    print "\n";
}

# ============================================================
# Benchmark: int64 sorting
# ============================================================
print "-" x 72, "\n";
print "BENCHMARK: int64 sorting (signed 64-bit integers)\n";
print "-" x 72, "\n\n";

for my $n (100, 10_000, 100_000) {
    my $data = gen_int64_data($n);

    printf "  n = %7d elements:\n", $n;

    my $bench = {
        "XS_int64"  => sub { Sort::DJB::sort_int64($data) },
        "Perl_sort" => sub { my @sorted = sort { $a <=> $b } @$data },
    };

    $bench->{"Pure_int64"} = sub { Sort::DJB::Pure::sort_int64($data) }
        if $n <= 10_000;

    $bench->{"SKey_nsort"} = sub { my @sorted = Sort::Key::nsort(@$data) }
        if $have_sort_key;

    $bench->{"Radix_isort"} = sub { my @sorted = Sort::Key::Radix::isort(@$data) }
        if $have_radix;

    $bench->{"Packed_i64"} = sub {
        my $buf = pack("q*", @$data);
        sort_packed('q', $buf);
        my @sorted = unpack("q*", $buf);
    } if $have_packed;

    my $results = timethese($bench_time, $bench, 'none');
    cmpthese($results);
    print "\n";
}

# ============================================================
# Benchmark: float64 sorting
# ============================================================
print "-" x 72, "\n";
print "BENCHMARK: float64 sorting (64-bit doubles)\n";
print "-" x 72, "\n\n";

for my $n (100, 10_000, 100_000) {
    my $data = gen_float64_data($n);

    printf "  n = %7d elements:\n", $n;

    my $bench = {
        "XS_float64" => sub { Sort::DJB::sort_float64($data) },
        "Perl_sort"  => sub { my @sorted = sort { $a <=> $b } @$data },
    };

    $bench->{"Pure_flt64"} = sub { Sort::DJB::Pure::sort_float64($data) }
        if $n <= 10_000;

    $bench->{"SKey_nsort"} = sub { my @sorted = Sort::Key::nsort(@$data) }
        if $have_sort_key;

    $bench->{"Radix_fsort"} = sub { my @sorted = Sort::Key::Radix::fsort(@$data) }
        if $have_radix;

    $bench->{"Packed_f64"} = sub {
        my $buf = pack("d*", @$data);
        sort_packed('d', $buf);
        my @sorted = unpack("d*", $buf);
    } if $have_packed;

    my $results = timethese($bench_time, $bench, 'none');
    cmpthese($results);
    print "\n";
}

# ============================================================
# Summary: All implementations at n=100,000 (int32)
# ============================================================
print "=" x 72, "\n";
print "SUMMARY: All implementations at n=100,000 (int32)\n";
print "=" x 72, "\n\n";

{
    my $data = gen_int32_data(100_000);

    my $bench = {
        "XS_int32"  => sub { Sort::DJB::sort_int32($data) },
        "Perl_sort" => sub { my @s = sort { $a <=> $b } @$data },
    };

    $bench->{"SKey_nsort"} = sub { my @s = Sort::Key::nsort(@$data) }
        if $have_sort_key;

    $bench->{"Radix_isort"} = sub { my @s = Sort::Key::Radix::isort(@$data) }
        if $have_radix;

    $bench->{"Packed_int32"} = sub {
        my $buf = pack("l*", @$data);
        sort_packed('l', $buf);
        my @s = unpack("l*", $buf);
    } if $have_packed;

    my $results = timethese($bench_time, $bench, 'none');
    cmpthese($results);
    print "\n";
}

# ============================================================
# Summary: XS vs best CPAN at n=100,000 across all types
# ============================================================
print "=" x 72, "\n";
print "SUMMARY: Sort::DJB XS vs best CPAN sorters at n=100,000 (all types)\n";
print "=" x 72, "\n\n";

{
    my $int32_data   = gen_int32_data(100_000);
    my $uint32_data  = gen_uint32_data(100_000);
    my $int64_data   = gen_int64_data(100_000);
    my $float64_data = gen_float64_data(100_000);

    my $bench = {
        "XS_int32"   => sub { Sort::DJB::sort_int32($int32_data) },
        "XS_uint32"  => sub { Sort::DJB::sort_uint32($uint32_data) },
        "XS_int64"   => sub { Sort::DJB::sort_int64($int64_data) },
        "XS_float64" => sub { Sort::DJB::sort_float64($float64_data) },
        "Perl_int"   => sub { my @s = sort { $a <=> $b } @$int32_data },
        "Perl_float" => sub { my @s = sort { $a <=> $b } @$float64_data },
    };

    if ($have_sort_key) {
        $bench->{"SKey_int"}   = sub { my @s = Sort::Key::nsort(@$int32_data) };
        $bench->{"SKey_float"} = sub { my @s = Sort::Key::nsort(@$float64_data) };
    }

    if ($have_radix) {
        $bench->{"Radix_int"}   = sub { my @s = Sort::Key::Radix::isort(@$int32_data) };
        $bench->{"Radix_float"} = sub { my @s = Sort::Key::Radix::fsort(@$float64_data) };
    }

    my $results = timethese($bench_time, $bench, 'none');
    cmpthese($results);
    print "\n";
}

# ============================================================
# Overhead measurement: small arrays
# ============================================================
print "=" x 72, "\n";
print "OVERHEAD: Call overhead for small arrays (n=5, n=10)\n";
print "=" x 72, "\n\n";

for my $n (5, 10) {
    my $data = gen_int32_data($n);

    printf "  n = %d elements:\n", $n;

    my $bench = {
        "XS_int32"   => sub { Sort::DJB::sort_int32($data) },
        "Pure_int32" => sub { Sort::DJB::Pure::sort_int32($data) },
        "Perl_sort"  => sub { my @sorted = sort { $a <=> $b } @$data },
    };

    $bench->{"SKey_nsort"} = sub { my @sorted = Sort::Key::nsort(@$data) }
        if $have_sort_key;

    $bench->{"Radix_isort"} = sub { my @sorted = Sort::Key::Radix::isort(@$data) }
        if $have_radix;

    my $results = timethese($bench_time, $bench, 'none');
    cmpthese($results);
    print "\n";
}

# ============================================================
# Raw packed buffer sorting (no SV conversion overhead)
# ============================================================
if ($have_packed) {
    print "=" x 72, "\n";
    print "PACKED BUFFER: Sort::Packed raw sort (pre-packed, no pack/unpack)\n";
    print "(Measures raw binary sort speed only, not comparable to SV-based sorts)\n";
    print "=" x 72, "\n\n";

    for my $n (1_000, 10_000, 100_000) {
        printf "  n = %7d elements:\n", $n;

        my $int32_data  = gen_int32_data($n);
        my $int64_data  = gen_int64_data($n);
        my $float64_data = gen_float64_data($n);

        my $pre_int32  = pack("l*", @$int32_data);
        my $pre_int64  = pack("q*", @$int64_data);
        my $pre_float64 = pack("d*", @$float64_data);

        my $results = timethese($bench_time, {
            "PackedR_i32" => sub {
                my $buf = $pre_int32;
                sort_packed('l', $buf);
            },
            "PackedR_i64" => sub {
                my $buf = $pre_int64;
                sort_packed('q', $buf);
            },
            "PackedR_f64" => sub {
                my $buf = $pre_float64;
                sort_packed('d', $buf);
            },
        }, 'none');

        cmpthese($results);
        print "\n";
    }
}

print "=" x 72, "\n";
print "Benchmark complete.\n";
print "=" x 72, "\n";
