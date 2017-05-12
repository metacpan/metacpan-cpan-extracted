use Test::More tests => 7;

require_ok('SSN::Validate');

my $ssn = new SSN::Validate;

my %ssns = (
    '900-44-1234' => [ 0, '??' ], # Tax range
    '900-71-1234' => [ 1, '??' ], # Tax range
    '900-93-1234' => [ 1, '??' ], # Tax range
);

for my $num ( sort { $a cmp $b } keys %ssns ) {
    ok( $ssn->valid_ssn($num) == $ssns{$num}->[0], "valid_ssn($num)" );
    ok( $ssn->get_state($num) eq $ssns{$num}->[1], "get_state($num)" );
}
