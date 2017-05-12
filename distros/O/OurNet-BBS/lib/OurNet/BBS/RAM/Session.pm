# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/RAM/Session.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::RAM::Session;

use strict;
no warnings 'deprecated';
use fields qw/recno chatport _ego _hash/;

use OurNet::BBS::Base (
    'SessionGroup' => [qw/@packlist/],
);

sub refresh_meta {
    my ($self, $key) = @_;

    # XXX SESSION READ
}

sub refresh_chat {
    my $self = shift;

    # XXX SESSION CHAT
}

sub remove {
    my $self = shift;

    # XXX SESSION REMOVE
}

sub STORE {
    my ($self, $key, $value) = @_;

    if ($key eq 'msg') {
        # XXX SESSION MSG
	}
    elsif ($key eq 'cb_msg') {
        # XXX SESSION CALLBACK
    }

    $self->refresh_meta($key);
    $self->{_hash}{$key} = $value;

    return unless $self->contains($key);
    # XXX SESSION UPDATE
}

sub DESTROY {
    my $self = shift;

    # XXX SESSION DESTROY
    return unless $self->{_hash}{flag};
}

1;
