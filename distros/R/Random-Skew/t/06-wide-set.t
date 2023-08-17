# Testing Random::Skew

use strict;
use warnings;

use Random::Skew;

use Test::More;

use constant {
    ITERATIONS => 1_000_000,
};

# We will run Random::Skew <ITERATIONS> times, for two different
# GRAIN settings, with the same structure. Results should be
# similar enough that the %variation is minimal.

my @letter = 'A'..'Z';
my $skew = 100;
my %config = (
    # 'A' => 1191.81765377272
    # 'B' => 1083.47059433884
    # 'C' => 984.973267580763
	# ...
    # 'X' => 133.1
    # 'Y' => 121
    # 'Z' => 110
    map { $_, $skew *= 1.1 } reverse @letter
);



# Check structure of Random::Skew with a GRAIN of 2000
Random::Skew::GRAIN( 2000 );
my $rs2000 = Random::Skew->new(
    %config
);
is($rs2000->{_fraction},0,"Grain 2000, has no fraction");



# Check structure of Random::Skew with a GRAIN of 25 (same %config)
Random::Skew::GRAIN( 25 );
my $rs25 = Random::Skew->new(
    %config
);
my $size = @{ $rs25->{_set} };
my $diff = abs( $size - $Random::Skew::GRAIN );
ok( $diff < 2, "Grain 25: set closely matches grain" );
ok( $rs25->{_fraction} > 0,"Grain 25, fraction is good");
# _fraction>0 means there's a Random::Skew subset at _set->[0]



my %s2000;
my %s25;
for ( my $ct = ITERATIONS ; $ct > 0 ; $ct-- ) {
	$s2000{ $rs2000->item }++;
	$s25{   $rs25->item   }++;
}
# Here we sort the results by numer of instances returned by the randomizer
# (should also be alpha order, the way we set up the weightings)
my @s2000 = sort { $s2000{$b} <=> $s2000{$a} } keys %s2000;
my @s25   = sort { $s25{$b}   <=> $s25{$a}   } keys %s25;



is( scalar(@s2000), 26, "Grain 2000: All distinct buckets populated" );
is( scalar(@s25  ), 26, "Grain 25: All distinct buckets populated" );



my $bad = 0;
foreach ( 0..23 ) {
    $bad++ unless $s2000[$_] lt $s2000[$_ + 2];
}
# Rounding can lead to a few switch-ups
ok( $bad < 2, "Grain 2000: [${bad}x] Numerical sort basically matches lexical sort" );

$bad = 0;
foreach ( 0..20 ) {
    $bad++ unless $s25[$_] lt $s25[$_ + 5];
}
# Rounding can lead to a few switch-ups, moreso for coarse grain
ok( $bad < 4, "Grain 25: [${bad}x] Numerical sort basically matches lexical sort" );



# Now let's see if the results are significantly different between the two grains
my %pct;
my $variation = 0;
my $max = 0;
foreach my $item ( keys %s25 ) {
    my $p2000 = $s2000{$item} / ITERATIONS;
    my $p25   = $s25{$item}   / ITERATIONS;
    $pct{$item} = abs( $p2000 - $p25 );
    $variation += $pct{$item};
    $max = $pct{$item} if $pct{$item} > $max;
}
ok( $variation < 0.2, "Variation sum [$variation] between Grains 25 and 2000 is small");
ok( $max       < 0.1, "Max variation ok [$max] between Grains 25 and 2000 is tiny"    );

done_testing( );

