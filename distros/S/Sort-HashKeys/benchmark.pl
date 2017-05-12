use strict;
use warnings;
use Benchmark qw/cmpthese timethese/;
use Sort::HashKeys;
use constant HASH_SLICE => $] ge "5.020";

my (@perl, @expr, @slce, @xs, %hash, %hash1, %hash2, %hash3, %hash4);

my @chars = ("A".."Z", "a".."z", "0".."9");
for (1..1000) {
    my $string;
    $string .= $chars[rand @chars] for 1..6;

    $hash{$string} = $_;
}

sub cv { eval "sub { $_[0] }" or die }

# Different data sets to avoid cache effects
%hash1 = %hash;
%hash2 = %hash;
%hash3 = %hash;
%hash4 = %hash;

cmpthese(-10, {
        xs_sort    => sub { @xs   = Sort::HashKeys::sort(%hash1) },
        perl_sort  => sub { @perl = map { ($_, $hash2{$_}) } sort keys %hash2 },
        expr_sort  => sub { @expr = map  +($_, $hash3{$_}),  sort keys %hash3 },
        HASH_SLICE ?
        (slce_sort => cv q{ @slce = %hash4{ sort keys %hash4 } } ) : (),
});

@perl == @xs or die "Functions didn't return the same output";
@expr == @xs or die "Functions didn't return the same output";
@slce == @xs or die "Functions didn't return the same output" if HASH_SLICE;
for (0..$#perl) {
    $perl[$_] eq $xs[$_] or die "Functions didn't return the same output";
    $expr[$_] eq $xs[$_] or die "Functions didn't return the same output";
    $slce[$_] eq $xs[$_] or die "Functions didn't return the same output" if HASH_SLICE;
}
