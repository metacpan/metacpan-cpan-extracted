use Test::More tests => 9;

require_ok('SSN::Validate');

my $ssn = new SSN::Validate;

my %ssns = (
    '666'   => [ 0, '' ], 
    '756'   => [ 0, '' ],
    '652'   => [ 0, '' ],
    '000'   => [ 0, '' ],
);

for my $num ( sort { $a cmp $b } keys %ssns ) {
    ok( $ssn->valid_area($num) == $ssns{$num}->[0], "valid_ssn($num)" );
    ok( $ssn->get_state($num) eq $ssns{$num}->[1], "get_state($num)" );
}
