package RxPerl::ReplaySubject;

use strict;
use warnings;

use base 'RxPerl::Subject';

use Scalar::Util 'weaken';
use Time::HiRes 'time';

our $VERSION = "v6.12.0";

sub _on_subscribe {
    my ($self, $subscriber) = @_;

    my $now; $now = time if defined $self->{_window_time};

    if (defined $subscriber->{next}) {
        foreach my $replay_value (@{ $self->{_replay_values} }) {
            my ($value, $time) = @$replay_value;
            $subscriber->{next}->($value) if ! defined $self->{_window_time} or $time + $self->{_window_time} >= $now;
        }
    }
}

sub _on_subscribe_closed {
    _on_subscribe(@_);
}

sub new {
    my ($class, $replay_size, $window_time) = @_;

    my $self = $class->SUPER::new();

    $self->{_replay_values} = [];
    $self->{_window_time} = $window_time;

    weaken(my $w_self = $self);
    my $next_orig = $self->{next};
    $self->{next} = sub {
        push @{$w_self->{_replay_values}}, [$_[0], time] unless $w_self->{_closed};
        splice @{$w_self->{_replay_values}}, 0, -$replay_size if defined $replay_size;
        $next_orig->($_[0]);
    };

    bless $self, $class;
}

1;
