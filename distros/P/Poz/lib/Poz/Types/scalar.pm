package Poz::Types::scalar;
use 5.032;
use strict;
use warnings;
use parent 'Poz::Types';

sub coerce {
    my ($self, $value) = @_;
    return $value;
}

sub default {
    my ($self, $default) = @_;
    push @{$self->{transform}}, sub {
        my ($self, $value) = @_;
        return $value if defined $value;
        return ref($default) eq "CODE" ? $default->($self) : $default;
    };
    return $self;
}

sub nullable {
    my ($self) = @_;
    unshift @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        return bless [], "Poz::Result::ShortCircuit" unless defined $value;
        return;
    };
    return $self;
}

sub optional {
    my ($self) = @_;
    unshift @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        return bless [], "Poz::Result::ShortCircuit" unless defined $value;
        return;
    };
    return $self;
}

1;

=head1 NAME

Poz::Types::scalar - Scalar type handling for Poz framework

=head1 SYNOPSIS

    use Poz::Types::scalar;

    my $scalar_type = Poz::Types::scalar->new();
    $scalar_type->default('default_value');
    $scalar_type->nullable();
    $scalar_type->optional();

=head1 DESCRIPTION

Poz::Types::scalar provides methods to handle scalar types within the Poz framework. It allows setting default values, marking values as nullable or optional, and coercing values.

=head1 METHODS

=head2 coerce

    $scalar_type->coerce($value);

Returns the given value without modification. This method is used to coerce values into the desired type.

=head2 default

    $scalar_type->default($default_value);

Sets a default value for the scalar type. If the value is undefined, the default value will be used. The default value can be a scalar or a code reference.

=head2 nullable

    $scalar_type->nullable();

Marks the scalar type as nullable. If the value is undefined, it will short-circuit and return without further processing.

=head2 optional

    $scalar_type->optional();

Marks the scalar type as optional. If the value is undefined, it will short-circuit and return without further processing.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut
