use Test::More tests => 17;

require_ok('SSN::Validate');

my $ssn = SSN::Validate->new({'ignore_bad_combo' => 1});

my %ssns = (
    '550-19-1234' => [ 1, 'CA' ], # Bad Combo
    '586191234'   => [ 1, '??' ], # Bad combo
    '586291234'   => [ 1, '??' ], # Bad combo
    '586591234'   => [ 1, '??' ], # Bad combo
    '586791234'   => [ 1, '??' ], # Bad combo
    '586801234'   => [ 1, '??' ], # Bad combo
    '586831234'   => [ 1, '??' ], # Bad combo
    '586991234'   => [ 1, '??' ], # Bad combo
);

for my $num ( sort { $a cmp $b } keys %ssns ) {
    ok( $ssn->valid_ssn($num) == $ssns{$num}->[0], "valid_ssn($num)" );
    ok( $ssn->get_state($num) eq $ssns{$num}->[1], "get_state($num)" );
}
