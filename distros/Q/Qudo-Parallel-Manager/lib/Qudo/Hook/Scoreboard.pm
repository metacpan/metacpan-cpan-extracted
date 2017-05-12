package Qudo::Hook::Scoreboard;
use strict;
use warnings;
use base 'Qudo::Hook';
use Qudo::Parallel::Manager::Registrar;
use Parallel::Prefork::SpareWorkers qw(:status);

sub load {
    my ($class, $klass) = @_;

    $klass->hooks->{pre_work}->{'scoreboard'} = sub {
        my $job = shift;
        Qudo::Parallel::Manager::Registrar->pm->set_status('A');
    };

    $klass->hooks->{post_work}->{'scoreboard'} = sub {
        my $job = shift;
        Qudo::Parallel::Manager::Registrar->pm->set_status(STATUS_IDLE);
    };
}

sub unload {
    my ($class, $klass) = @_;

    delete $klass->hooks->{pre_work}->{'scoreboard'};
    delete $klass->hooks->{post_work}->{'scoreboard'};
}

1;

