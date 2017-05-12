# Subclass LWP::UserAgent in order to support basic authentication.

package RT::Client::REST::HTTPClient;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.01';

use base 'LWP::UserAgent';

sub get_basic_credentials {
    my $self = shift;

    if ($self->basic_auth_cb) {
        return $self->basic_auth_cb->(@_);
    } else {
        return;
    }
}

sub basic_auth_cb {
    my $self = shift;

    if (@_) {
        $self->{basic_auth_cb} = shift;
    }

    return $self->{basic_auth_cb};
}

1;
