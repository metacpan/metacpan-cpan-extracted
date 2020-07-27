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

sub time_out {
    my ($self, $multi) = @_;

    my $is_active = $self->SUPER::time_out($multi);

    # Sometimes (maybe depending on the curl version?) $is_active
    # is 0 despite the presence of in-progress requests.
    $is_active ||= %{ $self->{'callbacks'} } || %{ $self->{'deferred'} };

    $self->CLEAR_TIMER() if !$is_active;

    return $is_active;
}

1;
