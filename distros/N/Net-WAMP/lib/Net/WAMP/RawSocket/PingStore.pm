package Net::WAMP::RawSocket::PingStore;

use strict;
use warnings;

use Net::WAMP::X ();

sub new { return bless [], shift; }

sub add {
    my ($self) = @_;

    push @$self, $self->_generate_text();

    return $self->[-1];
}

#Out-of-order responses are a fatal error. This seems unnecessary (IMO);
#it would do just as well to clear the entire queue as WebSocket does, but
#that’s not what WAMP RawSocket’s specification describes.
sub remove {
    my ($self, $body) = @_;

    if (@$self) {
        if ( $body eq $self->[0] ) {
            splice @$self, 0, 1;
            return 1;
        }
        else {
            for my $item ( @{$self}[ 1 .. $#$self ] ) {
                if ($item eq $body ) {
                    die Net::WAMP::X->create('RawSocket::BadPongOrder', $body);
                }
            }
        }
    }

    return 0;
}

sub get_count { return 0 + @{$_[0]}; }

#----------------------------------------------------------------------

#TODO: de-duplicate with Net::WebSocket::PingStore
sub _generate_text {
    my ($self) = @_;

    return sprintf(
        '%s UTC: ping #%d (%x)',
        scalar(gmtime),
        $self->get_count(),
        substr(rand, 2),
    );
}

1;
