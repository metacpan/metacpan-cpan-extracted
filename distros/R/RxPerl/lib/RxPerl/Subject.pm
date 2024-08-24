package RxPerl::Subject;
use strict;
use warnings;

use base 'RxPerl::Observable';

use Hash::Ordered;

our $VERSION = "v6.29.7";

# over-rideable
# sub _on_subscribe {
#     my ($self, $subscriber) = @_;
#     ...
# }

# over-rideable
# sub _on_subscribe_closed {
#     my ($self, $subscriber) = @_;
#     ...
# }

sub new {
    my ($class) = @_;

    my $subscribers_oh = Hash::Ordered->new();

    my $self; $self = $class->SUPER::new(sub {
        my ($subscriber) = @_;

        if ($self->{_closed}) {
            $self->_on_subscribe_closed($subscriber) if $self->can('_on_subscribe_closed');
            my ($type, @args) = @{ $self->{_closed} };
            $subscriber->{$type}->(@args) if defined $subscriber->{$type};
            return;
        }

        $subscribers_oh->set("$subscriber", $subscriber);
        $self->_on_subscribe($subscriber) if $self->can('_on_subscribe');

        return sub {
            $subscribers_oh->delete("$subscriber");
        };
    });

    $self->{_closed} = 0;
    foreach my $type (qw/ error complete /) {
        $self->{$type} = sub {
            return if $self->{_closed};
            $self->{_closed} = [$type, @_];
            foreach my $subscriber ($subscribers_oh->values) {
                $subscriber->{$type}->(@_) if defined $subscriber->{$type};
            }
            $subscribers_oh->clear();
            # TODO: maybe: delete @$self{qw/ next error complete /};
            # (Think about how subclasses such as BehaviorSubjects will be affected)
        };
    }
    $self->{next} = sub {
        foreach my $subscriber ($subscribers_oh->values) {
            $subscriber->{next}->(@_) if defined $subscriber->{next};
        }
    };

    return $self;
}

sub next {
    my $self = shift;

    $self->{next}->(splice @_, 0, 1) if defined $self->{next};
}

sub error {
    my $self = shift;

    $self->{error}->(splice @_, 0, 1) if defined $self->{error};
}

sub complete {
    my $self = shift;

    $self->{complete}->() if defined $self->{complete};
}

1;
