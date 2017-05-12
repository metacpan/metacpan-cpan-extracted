# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/CVIC/SessionGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::CVIC::SessionGroup;

use strict;
no warnings 'deprecated';
use base   qw/OurNet::BBS::MAPLE2::SessionGroup/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base (
    '$packstring' => 
        'LLLLLCCCx1LCCCCZ13Z11Z20Z24Z29Z11a256a64Lx13Cx2a1000LL',
    '$packsize'   => 1488,
);

sub writeok { 0 };
sub readok { 1 };

1;
