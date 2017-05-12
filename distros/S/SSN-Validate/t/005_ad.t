use Test::More tests => 21;

require_ok('SSN::Validate');

my $ssn = new SSN::Validate;

my %ssns = (
    '987654320'   => [ 0, '??' ], # Ad
    '987654321'   => [ 0, '??' ], # Ad
    '987654322'   => [ 0, '??' ], # Ad
    '987654323'   => [ 0, '??' ], # Ad
    '987654324'   => [ 0, '??' ], # Ad
    '987654325'   => [ 0, '??' ], # Ad
    '987654326'   => [ 0, '??' ], # Ad
    '987654327'   => [ 0, '??' ], # Ad
    '987654328'   => [ 0, '??' ], # Ad
    '987654329'   => [ 0, '??' ], # Ad
);

for my $num ( sort { $a cmp $b } keys %ssns ) {
    ok( $ssn->valid_ssn($num) == $ssns{$num}->[0], "valid_ssn($num)" );
    ok( $ssn->get_state($num) eq $ssns{$num}->[1], "get_state($num)" );
}
