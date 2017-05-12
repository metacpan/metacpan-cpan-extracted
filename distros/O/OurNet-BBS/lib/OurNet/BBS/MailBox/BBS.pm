# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MailBox/BBS.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::MailBox::BBS;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot _ego _hash/;
use OurNet::BBS::Base (
    '@BOARDS'   => [qw/bbsroot/],
);

1;
