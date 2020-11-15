package RxPerl::BehaviorSubject;

use strict;
use warnings;

use base 'RxPerl::Subject';

use Carp 'croak';

our $VERSION = "v6.1.1";

sub _on_subscribe {
    my ($self, $subscriber) = @_;

    $subscriber->{next}->($self->{_last_value}) if defined $subscriber->{next};
}

sub new {
    my ($class, $initial_value) = @_;

    @_ == 2 or croak 'missing initial value for behavior subject';

    my $self = $class->SUPER::new();

    $self->{_last_value} = $initial_value;

    bless $self, $class;
}

sub next {
    my $self = shift;

    $self->{_last_value} = $_[0] unless $self->{_closed};

    $self->SUPER::next(@_);
}

1;
