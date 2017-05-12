# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MailBox/BoardGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::MailBox::BoardGroup;

use strict;
no warnings 'deprecated';

use Mail::Box::Manager;
use fields qw/bbsroot mgr _ego _hash/;
use OurNet::BBS::Base;

sub refresh_meta {
    my ($self, $key) = @_;

    die "no list board yet" unless defined $key;

    $self->{mgr} ||= Mail::Box::Manager->new or die $!;

    return $self->{_hash}{$key} ||= $self->module('Board')->new({
	bbsroot	=> $self->{bbsroot},
	mgr		=> $self->{mgr},
	board	=> $key,
    });
}

1;
