# $Id: 10_pod-coverage.t 102 2009-07-30 14:48:55Z roland $
# $Revision: 102 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/rhonda/trunk/TeX-Hyphen-Pattern/t/10_pod-coverage.t $
# $Date: 2009-07-30 16:48:55 +0200 (Thu, 30 Jul 2009) $

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
  if $@;
all_pod_coverage_ok();
