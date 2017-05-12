# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/BBSAgent/Board.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::BBSAgent::Board;

use strict;
no warnings 'deprecated';
use fields qw/bbsroot bbsobj board _ego _hash/;
use OurNet::BBS::Base;

sub refresh_articles {
    my $self = shift;

    $self->{_hash}{articles} ||= $self->module('ArticleGroup')->new(
	@{$self}{qw/bbsroot bbsobj board/}, 'articles',
    );

    return 1;
}

sub refresh_archives {
    die 'archive not implemented';
}

sub refresh_meta {
    die 'metadata not implemented';
}

sub STORE {
    die 'storage not implemented';
}

1;
