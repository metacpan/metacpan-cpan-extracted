# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE3/GroupGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::MAPLE3::GroupGroup;

use strict;
no warnings 'deprecated';
use fields qw/_ego _hash/;
use OurNet::BBS::Base;

sub refresh_meta {
    die 'Group for MAPLE3 not implemented.';
}

1;
