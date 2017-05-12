package Net::WebSocket::PingStore;

#----------------------------------------------------------------------
# This isn’t really meant for public consumption, but it is at least
# useful in Net::WAMP for implementing the same behavior as WebSocket uses.
#----------------------------------------------------------------------

use strict;
use warnings;

sub new { return bless { }, shift; }

sub add {
    my ($self) = @_;

    my $str = $self->_generate_text();

    return $self->{$str} = $str;
}

#NB: We expect a response to any ping that we’ve sent; any pong
#we receive that doesn’t actually correlate to a ping we’ve sent
#is ignored—i.e., it doesn’t reset the ping counter. This means that
#we could still timeout even if we’re receiving pongs.
sub remove {
    my ($self, $text) = @_;

    if ( delete $self->{$text} ) {
        $self->_reset();
        return 1;
    }

    return 0;
}

sub get_count {
    my ($self) = @_;

    return 0 + keys %$self;
}

#----------------------------------------------------------------------

sub _generate_text {
    my ($self) = @_;

    return sprintf(
        '%s UTC: ping #%d (%x)',
        scalar(gmtime),
        $self->get_count(),
        substr(rand, 2),
    );
}

sub _reset {
    my ($self) = @_;

    return %$self = ();
}

1;
