# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/Firebird3/UserGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::Firebird3::UserGroup;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::UserGroup/;
use fields qw/_ego _hash _array/;
# XXX: md5.
use OurNet::BBS::Base (
    '$packstring' => 'Z16LZ16IIZ2Z14Z40Z40Z16Z64ILLZ40Z80Z68ILcCCCiILi',
    '$namestring' => 'Z16',
    '$packsize'   => 448,
    '@packlist'   => [
        qw/userid firstlogin lasthost numlogins numposts flags
	   passwd username ident termtype reginfo userlevel
	   lastlogin stay realname address email nummails
	   lastjustify gender birthyear birthmonth birthday
	   signature userdefine notedate noteline/
    ],
);


sub writeok { 0 };

sub readok {
    my ($self, $user, $op, $param) = @_;

    return ($param->[0] eq $user->id);
}


1;
