# $Id: 14_kwalitee.t 102 2009-07-30 14:48:55Z roland $
# $Revision: 102 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/rhonda/trunk/TeX-Hyphen-Pattern/t/14_kwalitee.t $
# $Date: 2009-07-30 16:48:55 +0200 (Thu, 30 Jul 2009) $

use Test::More;

eval {
    require Test::Kwalitee;
    Test::Kwalitee->import( tests => [qw( -has_meta_yml)] );
};

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
