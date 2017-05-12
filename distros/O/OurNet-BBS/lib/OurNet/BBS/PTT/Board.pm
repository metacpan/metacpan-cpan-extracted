# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/PTT/Board.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::PTT::Board;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::Board/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base;

1;
