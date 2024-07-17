package RxPerl::ConnectableObservable;
use strict;
use warnings;

use base 'RxPerl::Observable';

use RxPerl::Subscription;

use Scalar::Util 'weaken';

our $VERSION = "v6.29.0";

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

    $self->{_subjects_subscription} = RxPerl::Subscription->new;
    weaken(my $weak_self = $self);
    $self->{_subjects_subscription}->add(sub {
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
