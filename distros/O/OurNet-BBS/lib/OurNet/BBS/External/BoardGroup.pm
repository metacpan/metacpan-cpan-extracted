# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/External/BoardGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::External::BoardGroup;

use strict;
no warnings 'deprecated';
use fields qw/article_store article_fetch mtime _ego _hash/;
use OurNet::BBS::Base (
    '@packlist' => [qw/id title bm level/],
);

sub refresh_meta {
    my ($self, $key) = @_;

    return $self->{_hash}{$key} ||= $self->module('Board')->new({
	article_store	=> $self->{article_store},
	article_fetch	=> $self->{article_fetch},
	board		=> $key,
    }) if (defined $key);

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;

    return 1;
}

1;
