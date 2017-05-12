# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/NNTP/BoardGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::NNTP::BoardGroup;

use strict;
no warnings 'deprecated';
use fields qw/bbsroot nntp _ego _hash/;
use OurNet::BBS::Base;

use Net::NNTP;

sub refresh_meta {
    my ($self, $key) = @_;

    $self->{nntp} ||= Net::NNTP->new(
	$self->{bbsroot},
	Debug => $OurNet::BBS::DEBUG,
    ) or die $!;

    my @keys = (defined $key ? $key : keys(%{$self->{nntp}->list}));

    foreach $key (@keys) {
	$self->{_hash}{$key} ||= $self->module('Board')->new({
	    nntp  => $self->{nntp},
	    board => $key,
	});
    }

    return 1;
}

1;
