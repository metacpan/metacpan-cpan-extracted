# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/PTT/BoardGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::PTT::BoardGroup;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::BoardGroup/;
use fields qw/_ego _hash _shm _shmid/;
use OurNet::BBS::Base (
    '$packstring' => 'Z13Z49Z39LZ3LZ3CLLLLZ120',
    '$packsize'   => 120,
    '@packlist'   => [
        qw/id title bm brdattr pad bupdate pad2 bvote vtime
           level uid gid pad3/
     ],
);

1;
