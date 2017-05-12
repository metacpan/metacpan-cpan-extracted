package Spica::Spec;
use strict;
use warnings;
use utf8;

use Mouse;

has clients => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { +{} },
);

has namespace => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

no Mouse;

sub set_default_instance {
    my ($class, $instance) = @_;
    no strict 'refs'; ## no critic
    no warnings 'once';
    return ${"${class}::DEFAULT_INSTANCE"} = $instance;
}

sub instance {
    my $class = shift;
    no strict 'refs'; ## no critic
    no warnings 'once';
    return ${"${class}::DEFAULT_INSTANCE"};
}

sub add_client {
    my ($self, $client) = @_;
    return $self->clients->{$client->name} = $client;
}

sub get_client {
    my ($self, $name) = @_;
    return unless $name;
    return $self->clients->{$name};
}

sub get_row_class {
    my ($self, $client_name) = @_;

    my $client = $self->get_client($client_name);
    return $client->{row_class} if $client;
    return 'Spica::Receiver::Row';
}

sub camelize {
    my $s = shift;
    return join '' => map { ucfirst $_ } split(/(?<=[A-Za-z])_(?=[A-Za-z])|\b/, $s);
}

1;
