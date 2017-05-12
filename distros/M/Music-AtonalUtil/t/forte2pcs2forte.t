#!perl
#
# Audits conversion of table of forte numbers into prime form and then
# back into forte numbers. This ensures that the tables in the module
# (taken from "Basic Atonal Theory" by John Rahn) are in agreement with
# the prime_form code. (Or, at least locks whatever bugs there are in
# amber, minus the three typos in the Rahn book...)

use strict;
use warnings;

use Test::Most;    # plan is down at bottom
my $deeply = \&eq_or_diff;

use Music::AtonalUtil;
my $atu = Music::AtonalUtil->new;

# first listed forte number in Rahn taken as name for the pitch set
# class, so these complementary ones cannot be looked up in the reverse
# table (TODO alternative might be to return a list of two names in such
# a case).
my %complementary;
@complementary{
    "6-Z3",  "6-Z4",  "6-Z11", "6-Z12", "6-Z13", "6-Z6",  "6-Z24", "6-Z43",
    "6-Z25", "6-Z19", "6-Z26", "6-Z39", "6-Z28", "6-Z50", "6-Z23"
} = ();

my $num_forte_nums     = 208;
my $num_fnums_lesscomp = 193;

is( scalar keys %Music::AtonalUtil::FORTE2PCS,
    $num_forte_nums, 'expected number of forte numbers' );
# TODO have full 208 in reverse thing, need to revew prime_form calc against
# other sources to see why mine differs from what Rahn tabulated.
is( scalar keys %Music::AtonalUtil::PCS2FORTE,
    208, 'expected number of unique pitch classes' );

for my $fortenum ( keys %Music::AtonalUtil::FORTE2PCS ) {
    my $forte_pcs = $Music::AtonalUtil::FORTE2PCS{$fortenum};
    my $prime_pcs = $atu->prime_form($forte_pcs);
    $deeply->( $forte_pcs, $prime_pcs, "FORTE2PCS prime_form $fortenum" );

    # and the reverse lookup (less the complements)
    next if exists $complementary{$fortenum};

    is( $Music::AtonalUtil::PCS2FORTE{ join( ',', @$forte_pcs ) },
        $fortenum, "PCS2FORTE $fortenum" );
}

plan tests => 2 + $num_forte_nums + $num_fnums_lesscomp;
