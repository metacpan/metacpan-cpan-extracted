# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MailBox/ArticleGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::MailBox::ArticleGroup;

use strict;
no warnings 'deprecated';
use fields qw/mgr board folder _ego _array/;
use OurNet::BBS::Base;

# FIXME: use first/last update to determine refresh result

sub refresh_meta {
    my ($self, $key) = @_;

    die "$key out of range" if $key >= $self->{folder}->messages;

    $self->{_array}[$key] = $self->module('Article')->new({
	mgr	=> $self->{mgr},
	board	=> $self->{board},
	folder	=> $self->{folder},
	recno	=> $key,
    });
}

1;
