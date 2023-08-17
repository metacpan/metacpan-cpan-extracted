# Testing Random::Skew

use strict;
use warnings;

use Random::Skew;

use Test::More;

use constant {
    ITERATIONS => 1_000_000,
};

my %config = (
    Ginormous => 777_777,
    Lots      =>  98_765,
    Some      =>   2_468,
    Unusual   =>     611,
    Rare      =>       4,
);



# Check structure of Random::Skew with a GRAIN of 12
Random::Skew::GRAIN( 12 );
my $rs12 = Random::Skew->new(
    %config
);
my $size = @{ $rs12->{_set} };
my $diff = abs( $size - $Random::Skew::GRAIN );
ok( $diff < 2, "Grain 12: set [$size] closely matches grain" );
ok($rs12->{_fraction} > 0,"Grain 12 has a fraction");



# Check structure of Random::Skew with a GRAIN of 187 (same %config)
Random::Skew::GRAIN( 187 );
my $rs187 = Random::Skew->new(
    %config
);
$size = @{ $rs187->{_set} };
$diff = abs( $size - $Random::Skew::GRAIN );
ok( $diff < 2, "Grain 187: set [$size] closely matches grain" );
ok( $rs187->{_fraction} > 0,"Grain 187, fraction is good");
# _fraction>0 means there's a Random::Skew subset at _set->[0]



my %s12;
my %s187;
for ( my $ct = ITERATIONS ; $ct > 0 ; $ct-- ) {
	$s12{ $rs12->item }++;
	$s187{ $rs187->item }++;
}
# Here we sort the results by numer of instances returned by the randomizer
# (should also be alpha order, the way we set up the weightings)
my @s12  = sort { $s12{ $b} <=> $s12{ $a} } keys %s12;
my @s187 = sort { $s187{$b} <=> $s187{$a} } keys %s187;



# Now let's see if the results are significantly different between the two grains
my %pct;
my $variation = 0;
my $max = 0;
foreach my $item ( keys %s187 ) {
    no warnings 'uninitialized';
    my $p2k  = $s12{$item} / ITERATIONS;
    my $p187 = $s187{$item} / ITERATIONS;
    $pct{$item} = abs( $p2k - $p187 );
    $variation += $pct{$item};
    $max = $pct{$item} if $pct{$item} > $max;
}
ok( $variation < 0.07, "Variation Sum [$variation] between Grains 187 and 12 is small" );
ok( $max       < 0.04, "Max variation [$max] between Grains 187 and 12 is tiny"        );

done_testing( );
