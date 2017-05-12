use Test::Simple tests => 2;

use Parse::Lotus123::WK4;

ok( defined $Parse::Lotus123::WK4::VERSION );

ok( ( open X, 't/Workbook1.wk4' or ( warn 'Workbook1.wk4 test file not found', 0) )
      and Parse::Lotus123::WK4::parse(*X)
      and close X );

=head1 APOLOGY ABOUT LACK OF TESTS

These test are nearly pointless.

=cut

