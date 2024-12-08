package Poz::Types::array;
use 5.032;
use strict;
use warnings;
use Carp ();
use Try::Tiny;

sub new {
    my ($class, $validator) = @_;
    if (!$validator->isa('Poz::Types')) {
        Carp::croak("Invalid validator: is not a subclass of Poz::Types");
    }
    my $self = bless { 
        __validator__ => $validator,
        __as__        => undef,
        __rules__     => [],
    }, $class;
    return $self;
}

sub as {
    my ($self, $typename) = @_;
    $self->{__as__} = $typename;
    return $self;
}

sub parse {
    my ($self, $data) = @_;
    my ($valid, $errors) = $self->safe_parse($data);
    if ($errors) {
        my $error_message = _errors_to_string($errors);
        Carp::croak($error_message);
    }
    return $valid;
}

sub safe_parse {
    my ($self, $data) = @_;
    my @errors = ();
    if (ref($data) ne 'ARRAY') {
        push @errors, {
            key   => undef,
            error => "Invalid data: is not arrayref"
        };
    } else {
        for my $rule (@{$self->{__rules__}}) {
            my $err = $rule->($self, $data);
            if (defined $err) {
                push @errors, {
                    key   => undef,
                    error => $err,
                };
            }
        }
        for my $i (0 .. $#{$data}) {
            my $v = $self->{__validator__};
            my $val = $data->[$i];
            try {
                $v->parse($val);
            } catch {
                my $error_message = $_;
                $error_message =~ s/ at .+ line [0-9]+\.\n//;
                push @errors, {
                    key   => $i,
                    error => $error_message,
                };
            }
        }
    }
    if (scalar(@errors) > 0) {
        return (undef, [@errors])
    }
    my $classname = $self->{__as__};
    my $valid = $classname ? bless [@$data], $classname : [@$data];
    return ($valid, undef);
}

sub _errors_to_string {
    my $errors = shift;
    my @error_strings = ();
    for my $error (@$errors) {
        my $message = $error->{key} ? 
            sprintf("%s on key `%s`", $error->{error}, $error->{key}) :
            sprintf("%s", $error->{error});
        push @error_strings, $message;
    }
    return join(", and ", @error_strings);
}

sub min {
    my ($self, $min) = @_;
    push @{$self->{__rules__}}, sub {
        my ($self, $value) = @_;
        return "Array is too short" if scalar(@$value) < $min;
        return;
    };
    return $self;
}

sub max {
    my ($self, $max) = @_;
    push @{$self->{__rules__}}, sub {
        my ($self, $value) = @_;
        return "Array is too long" if scalar(@$value) > $max;
        return;
    };
    return $self;
}

sub length {
    my ($self, $length) = @_;
    push @{$self->{__rules__}}, sub {
        my ($self, $value) = @_;
        return "Array is not of length $length" if scalar(@$value) != $length;
        return;
    };
    return $self;
}

sub nonempty {
    my ($self) = @_;
    push @{$self->{__rules__}}, sub {
        my ($self, $value) = @_;
        return "Array is empty" if scalar(@$value) == 0;
        return;
    };
    return $self;
}

sub element {
    my ($self) = @_;
    return $self->{__validator__};
}
1;

=head1 NAME

Poz::Types::array - Array type validation for Poz::Types

=head1 SYNOPSIS

    use Poz qw/z/;

    my $array_validator = z->array(z->number);

    $array_validator->min(1)->max(5)->nonempty();

    my $data = [1, 2, 3];
    my $validated_data = $array_validator->parse($data);

=head1 DESCRIPTION

Poz::Types::array provides a way to validate arrays with various rules. It is designed to work with the Poz.

=head1 METHODS

=head2 as

    $array_validator->as('ArrayClass');

Sets the class name to bless the validated array into.

=head2 parse

    my $validated_data = $array_validator->parse($data);

Parses and validates the data. Throws an exception if validation fails.

=head2 safe_parse

    my ($validated_data, $errors) = $array_validator->safe_parse($data);

Parses and validates the data. Returns the validated data and any errors.

=head2 min

    $array_validator->min($min_length);

Sets a minimum length for the array.

=head2 max

    $array_validator->max($max_length);

Sets a maximum length for the array.

=head2 length

    $array_validator->length($exact_length);

Sets an exact length for the array.

=head2 nonempty

    $array_validator->nonempty();

Ensures the array is not empty.

=head2 element

    my $element_validator = $array_validator->element();

Returns the element validator.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut