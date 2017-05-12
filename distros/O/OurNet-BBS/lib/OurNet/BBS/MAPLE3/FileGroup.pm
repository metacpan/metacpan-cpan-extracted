# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE3/FileGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::MAPLE3::FileGroup;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::FileGroup/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base (
    '$PATH_ETC' => 'gem/@',
);

1;
