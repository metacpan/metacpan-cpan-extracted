# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/Cola/UserGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::Cola::UserGroup;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::UserGroup/;
use fields qw/_ego _hash _array/;

use OurNet::BBS::Base;

sub writeok { 0 };

sub readok {
    my ($self, $user, $op, $param) = @_;

    return ($param->[0] eq $user->id);
}


1;
