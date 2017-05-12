# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE3/Board.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::MAPLE3::Board;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::Board/;
use fields qw/_ego _hash/;
use subs qw/post_new_board refresh_articles refresh_archives 
            shmtouch readok writeok/;
use OurNet::BBS::Base;

sub writeok { 0 }

sub readok {
    my ($self, $user, $op) = @_;

    my $readlevel = $self->{readlevel};

    return (
	!$readlevel
	or $readlevel & $user->{userlevel}
	or $user->id eq $self->bm
	or $user->has_perm('PERM_SYSOP')
    );
}

sub post_new_board {
    my $self = shift;

    foreach my $dir (
        "$self->{bbsroot}/$PATH_BRD/$self->{board}/",
        "$self->{bbsroot}/$PATH_GEM/$self->{board}/",
    ) {
        mkdir $dir;

        foreach my $subdir (0 .. 9, 'A' .. 'V', '@') {
            mkdir "$dir$subdir";
        }
    }
}

sub refresh_articles {
    my $self = shift;

    return $self->{_hash}{articles} ||= $self->module('ArticleGroup')->new({
	basepath	=> "$self->{bbsroot}/$PATH_BRD",
	board		=> $self->{board},
	idxfile	 	=> '.DIR',
	bm		=> $self->{_hash}{bm},
	readlevel	=> $self->{_hash}{readlevel},
	postlevel	=> $self->{_hash}{postlevel},
    });
}

sub shmtouch {
    $_[0]->ego->{shm}{uptime} = 0;
}

sub refresh_archives {
    my $self = shift;

    return $self->{_hash}{archives} ||= $self->module('ArticleGroup')->new({
	basepath	=> "$self->{bbsroot}/$PATH_GEM",
	board		=> $self->{board},
	idxfile		=> '.DIR',
	bm		=> $self->{_hash}{bm},
	readlevel	=> $self->{_hash}{readlevel} || 0xffffffff,
	postlevel	=> $self->{_hash}{postlevel} || 0xffffffff,
    });
}

1;
