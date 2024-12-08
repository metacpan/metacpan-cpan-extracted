package Poz::Types::number;
use 5.032;
use strict;
use warnings;
use parent 'Poz::Types::scalar';
use Carp ();

sub new {
    my ($class, $opts) = @_;
    $opts = $opts || {};
    $opts->{required_error} //= "required";
    $opts->{invalid_type_error} //= "Not a number";
    my $self = $class->SUPER::new($opts);
    return $self;
}

sub rule {
    my ($self, $value) = @_;
    return Carp::croak($self->{required_error}) unless defined $value;
    return Carp::croak($self->{invalid_type_error}) unless $value =~ /^-?\d+\.?\d*$/;
    return;
};

sub coerce {
    my ($self, $value) = @_;
    return $value +0;
}

sub gt {
    my ($self, $min, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Too small";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) if $value <= $min;
        return;
    };
    return $self;
}

sub gte {
    my ($self, $min, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Too small";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) if $value < $min;
        return;
    };
    return $self;
}

sub lt {
    my ($self, $max, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Too large";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) if $value >= $max;
        return;
    };
    return $self;
}

sub lte {
    my ($self, $max, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Too large";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) if $value > $max;
        return;
    };
    return $self;
}

# value must be an integer
sub int {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not an integer";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) if $value !~ /^-?\d+$/;
        return;
    };
    return $self;
}

sub positive {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not a positive number";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) if $value <= 0;
        return;
    };
    return $self;
}

sub negative {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not a negative number";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) if $value >= 0;
        return;
    };
    return $self;
}

sub nonpositive {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not a non-positive number";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) if $value > 0;
        return;
    };
    return $self;
}

sub nonnegative {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not a non-negative number";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) if $value < 0;
        return;
    };
    return $self;
}

# Evenly divisible by 5.
sub multipleOf {
    my ($self, $divisor, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not a multiple of $divisor";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) if $value % $divisor != 0;
        return;
    };
    return $self;
}

# synonym for multipleOf
sub step {
    my ($self, $divisor, $opts) = @_;
    return $self->multipleOf($divisor, $opts);
}

1;

=head1 NAME

Poz::Types::number - A module for number type validation and coercion

=head1 SYNOPSIS

    use Poz qw/z/;
    
    my $number = z->number;
    
    # Validate a number
    $number->rule(42); # No error
    
    # Coerce a value to a number
    my $coerced_value = $number->coerce("42.5");
    
    # Add validation rules
    $number->gt(10)->lt(100);
    
    # Validate with custom rules
    $number->rule(50); # No error

=head1 DESCRIPTION

Poz::Types::number is a module for validating and coercing number types. It provides various methods to enforce constraints on numbers, such as greater than, less than, integer, positive, negative, and multiples of a given number.

=head1 METHODS

=head2 rule

    $number->rule($value);

Validates the given value against the defined rules. Throws an error if the value is invalid.

=head2 coerce

    my $coerced_value = $number->coerce($value);

Coerces the given value to a number.

=head2 gt

    $number->gt($min, \%opts);

Adds a rule to ensure the value is greater than the specified minimum.

=head2 gte

    $number->gte($min, \%opts);

Adds a rule to ensure the value is greater than or equal to the specified minimum.

=head2 lt

    $number->lt($max, \%opts);

Adds a rule to ensure the value is less than the specified maximum.

=head2 lte

    $number->lte($max, \%opts);

Adds a rule to ensure the value is less than or equal to the specified maximum.

=head2 int

    $number->int(\%opts);

Adds a rule to ensure the value is an integer.

=head2 positive

    $number->positive(\%opts);

Adds a rule to ensure the value is a positive number.

=head2 negative

    $number->negative(\%opts);

Adds a rule to ensure the value is a negative number.

=head2 nonpositive

    $number->nonpositive(\%opts);

Adds a rule to ensure the value is a non-positive number.

=head2 nonnegative

    $number->nonnegative(\%opts);

Adds a rule to ensure the value is a non-negative number.

=head2 multipleOf

    $number->multipleOf($divisor, \%opts);

Adds a rule to ensure the value is a multiple of the specified divisor.

=head2 step

    $number->step($divisor, \%opts);

Synonym for `multipleOf`.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut