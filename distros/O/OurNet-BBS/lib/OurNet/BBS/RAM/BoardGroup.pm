# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/RAM/BoardGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::RAM::BoardGroup;

use strict;
no warnings 'deprecated';
use fields qw/bbsroot dbh mtime _ego _hash/;
use OurNet::BBS::Base (
    '@packlist' => [qw/id title bm level/],
);

sub refresh_meta {
    my ($self, $key) = @_;

    return $self->{_hash}{$key} ||= $self->module('Board')->new({
	dbh   => $self->{dbh},
	board => $key,
    }) if (defined $key);

    return if $self->timestamp(-1);

    # XXX: ALLBOARDS
    foreach my $board (my @allboards) {
        $self->{_hash}{$board} ||= $self->module('Board')->new({
            dbh   => $self->{dbh},
            board => $board,
        });
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;

    # XXX: ACTUAL STORAGE
    %{$self->{_hash}{$key} ||= $self->module('Board', $value)->new({
	dbh   => $self->{dbh},
	board => $key,
    })} = %{$value};

    $self->timestamp(1);

    return 1;
}

1;
