# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE3/SessionGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::MAPLE3::SessionGroup;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::SessionGroup/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base (
    '$packstring'	=> 'LLLSSLLLa36Z13Z13Z24Z34',
    '$packsize'		=> 152,
    '@packlist'		=> [ qw(
        pid uid idle_time mode ufo sockaddr sockport destuip msgs 
        userid mateid username from
    ) ],
);

1;
