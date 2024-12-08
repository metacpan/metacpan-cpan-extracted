package Poz::Types;
use strict;
use warnings;
use Carp;

sub new {
    my ($class, $opts) = @_;
    $opts = $opts || {};
    my $rulecode = $class . "::rule";
    my $self = bless {
        %{$opts},
        rules => [\&$rulecode],
        transform => [],
        caller => [ caller() ],
    }, $class;
    $self->{required_error} //= 'required';
    $self->{invalid_type_error} //= 'invalid type';
    return $self;
}

sub rule {
    Carp::croak("Not implemented");
}

sub parse {
    my ($self, $value) = @_;
    if (length($self->{transform}) > 0) {
        for my $transformer (@{$self->{transform}}) {
            $value = $transformer->($self, $value);
        }
    }
    for my $rule (@{$self->{rules}}) {
        my $err = $rule->($self, $value);
        if (defined $err && ref($err) eq "Poz::Result::ShortCircuit") {
            return;
        }
        return $err if defined $err;
    }
    if ($self->{need_coerce}) {
        $value = $self->coerce($value);
    }
    return $value;
}

1;

=head1 NAME

Poz::Types - A module for handling type validation and transformation

=head1 SYNOPSIS

    use Poz::Types;
    
    my $type = Poz::Types->new({
        required_error => 'This field is required',
        invalid_type_error => 'Invalid type provided',
    });
    
    my $result = $type->parse($value);

=head1 DESCRIPTION

Poz::Types is a module designed to handle type validation and transformation. 
It provides a flexible way to define rules and transformations for different types.

=head1 METHODS

=head2 new

    my $type = Poz::Types->new(\%options);

Creates a new Poz::Types object. The optional hash reference can contain the following keys:
- required_error: Custom error message for required fields.
- invalid_type_error: Custom error message for invalid types.

=head2 rule

    $type->rule();

This method should be overridden in subclasses to provide specific validation rules. 
By default, it throws a "Not implemented" error.

=head2 parse

    my $result = $type->parse($value);

Parses the given value according to the defined rules and transformations. 
Returns the transformed value or an error if validation fails.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut