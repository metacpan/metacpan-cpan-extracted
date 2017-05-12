use Test::Most tests => 2;

use_ok "String::Substitute", qw(get_all_substitutes);

note "Testing the SYNOPSIS - as that changes or you add more, alter this test suite";

my @results = get_all_substitutes(
    string => 'ABC',
    substitutions => {
        A => 'Aa',
        B => 'Bb',
    },
);


my @expected = (qw[
    ABC
    aBC
    AbC
    abC
]);

cmp_set(\@results, \@expected, "We have the full set of possible substitutions");
