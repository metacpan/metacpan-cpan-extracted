package RxPerl::BehaviorSubject;

use strict;
use warnings;

use base 'RxPerl::Subject';

use Carp 'croak';
use Scalar::Util 'weaken';

our $VERSION = "v6.27.0";

sub _on_subscribe {
    my ($self, $subscriber) = @_;

    $subscriber->{next}->($self->{_last_value}) if defined $subscriber->{next};
}

sub new {
    my ($class, $initial_value) = @_;

    @_ == 2 or croak 'missing initial value for behavior subject';

    my $self = $class->SUPER::new();

    $self->{_last_value} = $initial_value;

    weaken(my $w_self = $self);
    my $next_orig = $self->{next};
    $self->{next} = sub {
        $w_self->{_last_value} = $_[0] unless $w_self->{_closed};
        $next_orig->(@_);
    };

    bless $self, $class;
}

sub get_value {
    my ($self) = shift;

    return $self->{_last_value};
}

1;
