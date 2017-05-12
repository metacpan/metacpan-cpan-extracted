# $Id: 12_manifest.t 102 2009-07-30 14:48:55Z roland $
# $Revision: 102 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/rhonda/trunk/TeX-Hyphen-Pattern/t/12_manifest.t $
# $Date: 2009-07-30 16:48:55 +0200 (Thu, 30 Jul 2009) $

use Test::More;
eval "use Test::CheckManifest 1.01";
plan skip_all => "Test::CheckManifest 1.01 required for testing test coverage"
  if $@;
ok_manifest( { filter => [qr/(Debian_CPANTS.txt|\.(svn|bak))/] } );
