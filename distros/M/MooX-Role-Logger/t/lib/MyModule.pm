use strict;
use warnings;

package MyModule;

use Moo;
with 'MooseX::Role::Logger';

sub run {
    my ($self) = @_;
    $self->cry;
}

sub cry {
    my ($self) = @_;
    $self->_logger->info("I'm sad");
}

1;

