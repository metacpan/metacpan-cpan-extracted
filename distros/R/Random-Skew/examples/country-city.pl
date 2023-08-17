#!/usr/bin/perl -w

# This example shows one way to approach hierarchical data.
# Countries are chosen first, with their own skewed weightings,
# and then within the chosen country we choose a city, again with
# skewed weightings specific to that set of cities.

use Random::Skew;

# Explore different values for $iterations and $grain:
my $iterations = shift // 1_000_000;
my $grain      = shift // 47;

# Configure:
Random::Skew::GRAIN( $grain ); # frob at your leisure



# Set up Random::Skew objects:
my $countries = Random::Skew->new(
    # Country weights are population, from Wikipedia 2023
    France        => 68_042_591,
    UnitedKingdom => 67_026_292,
    Spain         => 48_196_693,
    Germany       => 84_270_625,
    Monaco        =>     39_150,
    Vatican       =>        825, # really, really unlikely
);

# If you single-step thru the code, 
# check out what $countries looks like at this point.

my %cities = (
    # City weights are population rounded to nearest 100k, from Wikipedia 2022
    France        => Random::Skew->new(
        # try a GRAIN of 30 and examine $cities{France}, compare
        # with a GRAIN of 40
        Amiens      =>  1,
        Marseille   =>  8,
        Nice        =>  3,
        Paris       => 21,
    ),
    UnitedKingdom => Random::Skew->new(
        Birmingham  => 1100, # 1.1m
        Glasgow     =>  593, # 593k
        Leeds       =>  751, # 751k
        London      => 9000, # 9m
        Dover       =>   31, # 31k
    ),
    Spain         => Random::Skew->new(
        Barcelona   => 16,
        Madrid      => 33,
        Valencia    =>  8,
    ),
    Germany       => Random::Skew->new(
        Berlin      => 36,
        Cologne     => 11,
        Hamburg     => 18,
        Munich      => 14,
    ),
    Monaco        => Random::Skew->new( # from Wikipedia, 2022
        MonteCarlo  => 15_200,
        Fontieveille=>  3_600,
        Moneghetti  =>  3_100,
    ),
    # Just for consistency:
    Vatican       => Random::Skew->new(
        VaticanCity => 1,
    )
);

# Single stepping? Try 'x \%cities' now.

# Here we go:
my %city;
my %country;

for ( my $ct = $iterations ; $ct > 0 ; $ct -- ) {

    # Using Random::Skew, pick a country at random (in proportion
    # to their skew weights)
    my $ctry = $countries->item;
    # Pick a city from that country at random (in proportion to
    # its skew weight, within that country)
    my $city = $cities{$ctry}->item;

    # Could generate insert statements for example, or output to
    # CSV, etc print "$ctry\t$city\n";
    $country{$ctry}++;
    $city{"$ctry/$city"}++;

}

# Now show what we've got. The higher $iterations, the closer the
# results are to the originally-requested proportions (with a bit
# of fudging, due to rounding).
print "\nOverall counts:                   Count   Ctry% Overall%\n";
foreach my $ctry ( sort keys %country ) {

    my $pct = 100 * $country{$ctry} / $iterations;
    printf "\n%-30s%7d            %5.2f%%\n",
		$ctry,
        $country{$ctry},
        $pct;

    foreach my $city ( sort grep m{^$ctry/}, keys %city ) {

        $pct = 100 * $city{$city} / $iterations;
        my $cpct = 100 * $city{$city} / $country{$ctry};

        printf " %-29s  %7d %6.2f%% (%5.2f%%)\n",
            $city,
            $city{$city},
            $cpct,
            $pct;

    }

}

