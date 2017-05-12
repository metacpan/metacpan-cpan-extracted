# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/Firebird3/BoardGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::Firebird3::BoardGroup;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::BoardGroup/;
use fields qw/_ego _hash/;

use OurNet::BBS::Base (
    '$packstring'    => 'Z80Z20Z60Z1Z79LZ12',
    '$namestring'    => 'Z80',
    '$packsize'      => 256,
    '@packlist'      => [
	qw/id owner bm flag title level accessed/, # XXX
    ],
    '$BRD'           => '.BOARDS',
    '$PATH_BRD'      => 'boards',
    '$PATH_GEM'      => '0Announce/.Search', # XXX: drastically different
);

sub writeok { 0 };
sub readok { 1 };

1;
