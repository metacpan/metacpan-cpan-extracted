package RxPerl::Subject;
use strict;
use warnings;

use base 'RxPerl::Observable';

our $VERSION = "v6.0.2";

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
