# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/External/BBS.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::External::BBS;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS/;
use fields qw/backend article_store article_fetch _ego _hash/;
use OurNet::BBS::Base (
    '@BOARDS'   => [qw/article_store article_fetch/],
);

1;
