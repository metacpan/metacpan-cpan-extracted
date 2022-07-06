use Test::Simple tests => 4;
use StandupGenerator::Helper;

my %basic_ids = StandupGenerator::Helper::extract_identifiers("s1d03.txt");
my %tricky_ids = StandupGenerator::Helper::extract_identifiers("s2d10.txt");

print("*** EXTRACT IDENTIFIERS:\n");
 
ok( $basic_ids{'sprint'} eq 1, 'should return sprint of 1 if file begins with s1d' );
ok( $basic_ids{'day'} eq 3, 'should return day of 3 if file ends with d03' );
ok( $tricky_ids{'sprint'} eq 2, 'should return sprint of 2 if file begins with s2d' );
ok( $tricky_ids{'day'} eq 0, 'should return day of 0 if it is actually the 10th day' );

# Execute tests from directory root with:
# perl -Ilib t/routines/extract_identifiers.t

1;