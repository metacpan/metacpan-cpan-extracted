use Test::More tests => 17;

require_ok('SSN::Validate');

my $ssn = new SSN::Validate;

my %ssns = (
    '550-19-1234' => [ 0, 'CA' ], # Bad Combo
    '586191234'   => [ 0, '??' ], # Bad combo
    '586291234'   => [ 0, '??' ], # Bad combo
    '586591234'   => [ 0, '??' ], # Bad combo
    '586791234'   => [ 0, '??' ], # Bad combo
    '586801234'   => [ 0, '??' ], # Bad combo
    '586831234'   => [ 0, '??' ], # Bad combo
    '586991234'   => [ 0, '??' ], # Bad combo
);

for my $num ( sort { $a cmp $b } keys %ssns ) {
    ok( $ssn->valid_ssn($num) == $ssns{$num}->[0], "valid_ssn($num)" );
    ok( $ssn->get_state($num) eq $ssns{$num}->[1], "get_state($num)" );
}
