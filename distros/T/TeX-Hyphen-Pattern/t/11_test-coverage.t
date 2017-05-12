# $Id: 11_test-coverage.t 112 2009-07-31 01:53:16Z roland $
# $Revision: 112 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/rhonda/trunk/TeX-Hyphen-Pattern/t/11_test-coverage.t $
# $Date: 2009-07-31 03:53:16 +0200 (Fri, 31 Jul 2009) $

use Test::More;
eval "use Test::TestCoverage 0.08";
plan skip_all => "Test::TestCoverage 0.08 required for testing test coverage"
  if $@;

plan tests => 1;
test_coverage("TeX::Hyphen::Pattern");

my $obj = TeX::Hyphen::Pattern->new();
$obj->label( q{nl} );
$obj->filename();
$obj->DESTROY();

ok_test_coverage('TeX::Hyphen::Pattern');
