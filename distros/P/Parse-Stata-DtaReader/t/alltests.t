use Test::Simple tests => 4;

use Parse::Stata::DtaReader;

ok($Parse::Stata::DtaReader::byteOrder == 1 || $Parse::Stata::DtaReader::byteOrder == 2);
ok((open X, 't/t1.dta' or warn 't1.dta test file not found') and $dta = Parse::Stata::DtaReader->new(*X) and $dta->{nvar} == 3 and close X);
ok((open X, 't/t2.dta' or warn 't2.dta test file not found') and $dta = Parse::Stata::DtaReader->new(*X) and $dta->{nvar} == 3 and close X);
ok((open X, 't/t3.dta' or warn 't3.dta test file not found') and $dta = Parse::Stata::DtaReader->new(*X) and $dta->{nvar} == 3 and close X);

=head1 APOLOGY ABOUT POOR TESTS

Very basic tests of the integrity of the package.
No real test of functionality.
These tests have failed to catch major bugs.

=cut
