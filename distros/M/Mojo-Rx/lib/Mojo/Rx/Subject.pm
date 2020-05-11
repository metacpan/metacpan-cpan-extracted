package Mojo::Rx::Subject;
use strict;
use warnings FATAL => 'all';

use base 'Mojo::Rx::Observable';

use Mojo::Rx 'rx_observable';
use Mojo::Rx::Utils 'get_subscription_from_subscriber';

our $VERSION = "v0.12.1";

sub new {
    my ($class) = @_;

    my %subscribers;

    my $self; $self = $class->SUPER::new(sub {
        my ($subscriber) = @_;

        if ($self->{_closed}) {
            $subscriber->{complete}->() if defined $subscriber->{complete};
            return;
        }

        $subscribers{$subscriber} = $subscriber;

        return sub {
            delete $subscribers{$subscriber};
        };
    });

    $self->{_closed} = 0;
    foreach my $type (qw/ error complete /) {
        $self->{$type} = sub {
            $self->{_closed} = 1;
            foreach my $subscriber (values %subscribers) {
                $subscriber->{$type}->(@_) if defined $subscriber->{$type};
            }
            %subscribers = ();
            # TODO: maybe: delete @$self{qw/ next error complete /};
            # (Think about how subclasses such as BehaviorSubjects will be affected)
        };
    }
    $self->{next} = sub {
        foreach my $subscriber (values %subscribers) {
            $subscriber->{next}->(@_) if defined $subscriber->{next};
        }
    };

    return $self;
}

1;
