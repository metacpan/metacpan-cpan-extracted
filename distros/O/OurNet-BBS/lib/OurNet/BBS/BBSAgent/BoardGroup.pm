# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/BBSAgent/BoardGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::BBSAgent::BoardGroup;

use strict;
no warnings 'deprecated';
use fields qw/bbsroot bbsobj mtime _ego _hash/;
use OurNet::BBS::Base;

sub refresh_meta {
    my ($self, $key) = @_;

    die 'board listing not implemented' unless $key;

    $self->{_hash}{$key} ||= $self->module('Board')->new(
	@{$self}{qw/bbsroot bbsobj/}, $key,
    );

    return 1;
}

1;
