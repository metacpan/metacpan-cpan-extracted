# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/CVIC/FileGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::CVIC::FileGroup;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::FileGroup/;
use fields qw/_ego _hash/;
use subs qw/writeok readok/;
use OurNet::BBS::Base;

sub writeok { 0 };
sub readok { 1 };

1;
