#!/usr/bin/perl -w

# This example script shows a possible approach for multi-layered
# data where one layer is affected by another. In this case we
# are looking at college majors, and how attendance is skewed
# towards men for some majors, and towards women for others.

use Random::Skew;

# Explore different values for $iterations and $grain:
my $iterations = shift // 1_000_000;
my $grain      = shift // 71;

# Configure:
Random::Skew::GRAIN( $grain ); # frob at your leisure

# Make our main Random::Skew object for majors:
my $random_major = Random::Skew->new(
    Engineering => 5000,
    Drama       => 2100,
    Nursing     => 7250,
    CompScience => 1075,
);

# This is a hash where each value is a Random::Skew object:
my %sexes = (
    # Relative skew weights is what matters, doesn't have to total 100% or anything in particular
    Engineering => Random::Skew->new( Male => 120, Female =>  47, Other => 2 ),
    Drama       => Random::Skew->new( Male =>  94, Female => 140, Other => 9 ),
    Nursing     => Random::Skew->new( Male => 100, Female => 512, Other => 1 ),
    CompScience => Random::Skew->new( Male =>  58, Female =>  23, Other => 4 ),
);

my %student;
for ( my $ct = $iterations ; $ct > 0 ; $ct -- ) {
    my $major = $random_major->item;
    my $sex   = $sexes{ $major }->item;

    $student{ $major }{ $sex }++;
    $student{ $major }{ _ }++;
}

print "\nOverall counts:      Count  Maj% Overall%\n";
foreach my $major ( sort keys %student ) {

    my $mtot = $student{ $major }{ _ };
    my $pct = 100 * $mtot / $iterations;
    printf "\n%-15s %7d           %6.2f%%\n", "\U$major", $mtot, $pct;

    foreach my $sex ( sort keys %{ $student{ $major } } ) {
        next if $sex eq '_';

        $pct = 100 * $student{ $major }{ $sex } / $mtot;
        my $mpct = 100 * $student{ $major }{ $sex } / $iterations;

        printf "  %-15s %7d %6.2f%% %6.2f%%\n", $sex, $student{ $major }{ $sex }, $pct, $mpct;
    }
}

# vim:ft=perl nowrap ts=4 sw=4 et
