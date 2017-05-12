# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/CVIC/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::CVIC::ArticleGroup;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::ArticleGroup/;
use fields qw/_ego _hash _array/;
use OurNet::BBS::Base;

sub writeok { 0 };
sub readok { 1 };

1;
