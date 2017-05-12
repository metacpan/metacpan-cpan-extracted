# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/Cola/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::Cola::ArticleGroup;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::ArticleGroup/;
use fields qw/_ego _hash _array/;
use subs qw/FETCHSIZE/;

use OurNet::BBS::Base (
    '$packstring'    => 'Z78Z1Z1Z80Z96Z0',
    '$namestring'    => 'Z78',
    '$packsize'      => 256,
    '@packlist'      => [qw/id savemode filemode author title date/],
);

sub writeok { 0 };
sub readok { 1 };

sub FETCHSIZE {
    my $self = $_[0]->ego;

    no warnings 'uninitialized';
    return int((stat(
	join('/', @{$self}{qw/bbsroot basepath board dir name/}, '.DIR')
    ))[7] / $packsize);
}

1;
