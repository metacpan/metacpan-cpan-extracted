use Test::More tests => 10;

require_ok('SSN::Validate');

my $ssn = new SSN::Validate;

my %ssns = (
    '04456'       => 1,
    '044-56'      => 1,
    '56'          => 1,
    '044-58-8829' => 1,
    '19'          => 1,
    '00'          => 0,
    '12100'       => 0,
    '044-57'      => 0,
    '550-19-8829' => 0,
);

for my $num ( sort { $a cmp $b } keys %ssns ) {
    ok( $ssn->valid_group($num) == $ssns{$num}, "valid_group($num)" );
}
