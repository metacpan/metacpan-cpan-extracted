package RxPerl::Subject;
use strict;
use warnings;

use base 'RxPerl::Observable';

use Hash::Ordered;
use Scalar::Util 'weaken';

our $VERSION = "v6.29.8";

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
    weaken(my $w_subscribers_oh = $subscribers_oh);

    my $w_self;
    my $self = $class->SUPER::new(sub {
        my ($subscriber) = @_;

        if ($w_self->{_closed}) {
            $w_self->_on_subscribe_closed($subscriber) if $w_self->can('_on_subscribe_closed');
            my ($type, @args) = @{ $w_self->{_closed} };
            $subscriber->{$type}->(@args) if defined $subscriber->{$type};
            return;
        }

        $w_subscribers_oh->set("$subscriber", $subscriber);
        $w_self->_on_subscribe($subscriber) if $w_self->can('_on_subscribe');

        my $string = "$subscriber";
        # return;
        return sub {
            $w_subscribers_oh and $w_subscribers_oh->delete($string);
        };
    });
    weaken($w_self = $self);

    $self->{_closed} = 0;
    foreach my $type (qw/ error complete /) {
        $self->{$type} = sub {
            return if $w_self->{_closed};
            $w_self->{_closed} = [$type, @_];
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
