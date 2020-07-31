package Net::Curl::Promiser::Backend::LoopBase;

use strict;
use warnings;

use parent 'Net::Curl::Promiser::Backend';

sub _CB_TIMER {
    my ($multi, $timeout_ms, $self) = @_;

    $self->CLEAR_TIMER();

    if ($timeout_ms != -1) {
        $self->SET_TIMER($multi, $timeout_ms);
    }

    return 1;
}

sub _finish_handle {
    my ($self, @args) = @_;

    $self->SUPER::_finish_handle(@args);

    my $is_active = %{ $self->{'callbacks'} } || %{ $self->{'deferred'} };

    $self->CLEAR_TIMER() if !$is_active;

    return;
}

1;
