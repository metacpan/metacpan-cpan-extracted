package Mojo::Rx::ConnectableObservable;
use strict;
use warnings FATAL => 'all';

use base 'Mojo::Rx::Observable';

use Mojo::Rx::Subscription;

use Scalar::Util 'weaken';

our $VERSION = "v0.12.1";

sub new {
    my ($class, $source, $subject_factory) = @_;

    my $weak_self;
    my $self = $class->SUPER::new(sub {
        my ($subscriber) = @_;

        return $weak_self->{_subject}->subscribe($subscriber);
    });
    weaken($weak_self = $self);

    %$self = (
        %$self,
        _source                => $source,
        _subject_factory       => $subject_factory,
        _subject               => $subject_factory->(),
        _connected             => 0,
        _subjects_subscription => undef,
    );

    return $self;
}

sub connect {
    my ($self) = @_;

    return $self->{_subjects_subscription} if $self->{_connected};

    $self->{_connected} = 1;

    $self->{_subjects_subscription} = Mojo::Rx::Subscription->new;
    weaken(my $weak_self = $self);
    $self->{_subjects_subscription}->add_dependents(sub {
        if (defined $weak_self) {
            $weak_self->{_connected} = 0;
            $weak_self->{_subjects_subscription} = undef;
            $weak_self->{_subject} = $weak_self->{_subject_factory}->();
        }
    });

    $self->{_source}->subscribe({
        new_subscription => $self->{_subjects_subscription},
        %{ $self->{_subject} },
    });

    return $self->{_subjects_subscription};
}

1;
