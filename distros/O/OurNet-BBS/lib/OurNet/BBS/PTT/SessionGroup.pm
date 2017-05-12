# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/PTT/SessionGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::PTT::SessionGroup;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::SessionGroup/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base;

sub refresh_meta {
    die "Session support at PTT now broken"; 
    # XXX ... and we're not going to fix it.
}

1;
