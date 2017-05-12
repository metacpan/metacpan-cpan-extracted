use Test::More tests => 19;

require_ok('SSN::Validate');

my $ssn = new SSN::Validate;

my %ssns = (
    '999'   => [ 1, '??' ], 
    '044'   => [ 1, 'CT' ],
    '529'   => [ 1, 'UT' ],
    '530'   => [ 1, 'NV' ],
    '523'   => [ 1, 'CO' ],
    '520'   => [ 1, 'WY' ],
    '518'   => [ 1, 'ID' ],
    '586'   => [ 1, '??' ],
    '701'   => [ 1, 'RB' ],
);

for my $num ( sort { $a cmp $b } keys %ssns ) {
    ok( $ssn->valid_area($num) == $ssns{$num}->[0], "valid_ssn($num)" );
    ok( $ssn->get_state($num) eq $ssns{$num}->[1], "get_state($num)" );
}
