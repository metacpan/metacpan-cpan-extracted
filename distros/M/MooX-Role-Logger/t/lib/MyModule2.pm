use strict;
use warnings;

package MyModule2;

use Moo;
with 'MooX::Role::Logger';

sub run {
    my ($self) = @_;
    $self->cry;
}

sub cry {
    my ($self) = @_;
    $self->_logger->info("I'm sad");
}

1;

