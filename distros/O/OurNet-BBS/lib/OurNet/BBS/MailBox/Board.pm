# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MailBox/Board.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::MailBox::Board;

use strict;
no warnings 'deprecated';
use fields qw/bbsroot mgr board folder _ego _hash/;
use OurNet::BBS::Base;

sub refresh_articles {
    my $self = shift;

    $self->refresh unless $self->{folder};

    return $self->{_hash}{articles} ||=
	$self->module('ArticleGroup')->new({
	    mgr		=> $self->{mgr},
	    board	=> $self->{board},
	    folder	=> $self->{folder},
	});
}

sub refresh_archives {
    die 'no refresh_archives';
}

sub refresh_meta {
    my $self = shift;

    return if $self->{folder};

    my $file = "$self->{bbsroot}/$self->{board}";

    $self->{folder} = $self->{mgr}->open(folder => $file);
    $self->{_hash}{title} = $self->{folder}->name;
    $self->{_hash}{id}    = $self->{folder}->filename;
    $self->{_hash}{bm}    = getpwuid((stat($file))[4])
	if $^O ne 'MSWin32';
}

1;

