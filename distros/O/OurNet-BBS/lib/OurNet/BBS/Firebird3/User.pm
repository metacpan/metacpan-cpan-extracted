# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/Firebird3/User.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::Firebird3::User;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::User/;
use fields qw/_ego _hash/;
use subs qw/refresh_mailbox/;
use OurNet::BBS::Base;

sub writeok { 0 };
sub readok { 1 };

sub refresh_mailbox {
    my $self = shift;

    $self->{_hash}{mailbox} ||= $self->module('ArticleGroup')->new(
	$self->{bbsroot},
	$self->{id},
	"mail/".uc(substr($self->{id}, 0, 1)),
    );
}


1;
