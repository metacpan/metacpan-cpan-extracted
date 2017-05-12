# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MELIX/User.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::MELIX::User;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE3::User/;
use fields qw/_ego _hash/;
use subs qw/readok writeok has_perm/;
use OurNet::BBS::Base;

sub writeok { 0 }
sub readok { 1 }

sub has_perm {
    no strict 'refs';
    return $_[0]->{userlevel} & &{$_[1]};
}

1;
