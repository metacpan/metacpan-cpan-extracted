# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MELIX/BBS.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::MELIX::BBS;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              chatport passwd _ego _hash/;
use subs qw/readok writeok/;

use OurNet::BBS::Base (
    '@USERS' => [qw/bbsroot/],
);

sub writeok { 0 }

sub readok {
    my ($self, $user) = @_;

    return 1 if $user->has_perm('PERM_SYSOP');
    
    return if (
	$user->has_perm('PERM_DENYLOGIN') or $user->has_perm('PERM_PURGE')
    );

    return 1;
}

1;
