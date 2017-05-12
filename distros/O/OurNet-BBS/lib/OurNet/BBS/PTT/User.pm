# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/PTT/User.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::PTT::User;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::User/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base;

1;
