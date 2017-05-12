# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/CVIC/BBS.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::CVIC::BBS;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              usershmkey maxuser chatport passwd _ego _hash/;
use OurNet::BBS::Base (
    '@GROUPS'   => [qw/bbsroot _ego/], # cheat!
);

1;
