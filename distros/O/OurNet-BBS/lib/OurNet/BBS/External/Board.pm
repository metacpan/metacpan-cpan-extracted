# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/External/Board.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::External::Board;

use strict;
no warnings 'deprecated';
use fields qw/article_store article_fetch board mtime _ego _hash/;

use OurNet::BBS::Base (
    'BoardGroup' => [qw/@packlist/],
);

sub refresh_articles {
    my $self = shift;

    $self->{_hash}{articles} ||= $self->module('ArticleGroup')->new({
	article_store	=> $self->{article_store},
	article_fetch	=> $self->{article_fetch},
        board		=> $self->{board},
        name		=> 'articles',
    });

    return $self->{_hash}{articles};
}

sub refresh_archives {
    my $self = shift;

    return $self->{_hash}{archives} ||= $self->module('ArticleGroup')->new({
	article_store	=> $self->{article_store},
	article_fetch	=> $self->{article_fetch},
        board		=> $self->{board},
        name		=> 'archives',
    });
}

sub refresh_meta {
    my ($self, $key) = @_;
    
    return if $key and !$self->contains($key);
    return if $self->timestamp(-1);

    # XXX: RETRIEVE ACCORDING TO @packlist
    @{$self->{_hash}}{@packlist} = () if 0;

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;

    return 1;
}

sub remove {
    my $self = shift;

    # XXX: DELETE BOARD ENTRY
    return 1;
}

1;

