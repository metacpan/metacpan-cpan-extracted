use Test::Most tests => 2;

use_ok "String::Substitute", qw(get_all_substitutes);

my @results = get_all_substitutes(
    string => "DO11WHA",
    substitutions => {
        D => 'DO',
        O => 'OD',
        H => 'HW',
        W => 'WH',
    },
);

my @expected = (qw[
    DO11WHA DO11WWA DO11HHA DO11HWA
    DD11WHA DD11WWA DD11HHA DD11HWA
    OO11WHA OO11WWA OO11HHA OO11HWA
    OD11WHA OD11WWA OD11HHA OD11HWA
]);
cmp_set(\@results, \@expected, "We have the full set of possible substitutions");
