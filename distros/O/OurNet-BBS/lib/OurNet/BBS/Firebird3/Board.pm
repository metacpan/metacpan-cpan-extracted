# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/Firebird3/Board.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::Firebird3::Board;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::Board/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base;

sub writeok { 0 };

sub readok {
    my ($self, $user, $op, $param) = @_;
    my $id = quotemeta($user->id);

    return ($self->{bm} =~ /\b$id\b/s) if $param->[0] eq 'archives';

    return 1;
}

1;
