package Poz::Types::union;
use 5.032;
use strict;
use warnings;
use Carp ();
use Try::Tiny;
use parent 'Poz::Types';

sub new {
    my ($class, @validators) = @_;
    for my $validator (@validators) {
        if (!$validator->isa('Poz::Types')) {
            Carp::croak("Invalid validator: is not a subclass of Poz::Types");
        }
    }
    my $self = bless {
        __validators__ => \@validators,
        __rules__      => [],
        __optional__   => 0,
        __default__    => undef,
    }, $class;
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
    Carp::croak "Must handle error" unless wantarray;

    my ($self, $data) = @_;
    my @errors = ();
    if (defined $self->{__default__} && !defined $data) {
        $data = $self->{__default__};
    }
    if (!defined $data) {
        if ($self->{__optional__}) {
            return (undef, undef);
        } elsif (grep {ref $_ eq 'Poz::Types::null'} @{$self->{__validators__}}) {
            return (undef, undef);
        } else {
            push @errors, "Required";
        }
    } else {
        for my $validator (@{$self->{__validators__}}) {
            my ($v, $e) = $validator->safe_parse($data);
            if (!$e) {
                return ($v, undef);
            }
            push @errors, $e;
        }
    }
    return (undef, [@errors]);
}

sub _errors_to_string {
    my ($errors) = @_;
    my @error_messages = ();
    for my $error (@$errors) {
        push @error_messages, $error;
    }
    return join(", ", @error_messages) . ' for union value';
}

sub optional {
    my ($self) = @_;
    $self->{__optional__} = 1;
    return $self;
}

sub default {
    my ($self, $default) = @_;
    $self->{__default__} = $default;
    return $self;
}

1;

=head1 NAME

Poz::Types::union - Union type for multiple validators in Poz

=head1 SYNOPSIS

    use Poz::Builder;
    use Poz::Types;

    my $builder = Poz::Builder->new;
    my $validator = $builder->union(
        $builder->number->multipleOf(3),
        $builder->number->multipleOf(5),
    );

    my $valid = $validator->parse(6); # 6 is multiple of 3 and 5
    my $invalid = $validator->parse(8); # 8 is not multiple of 3 or 5

=head1 DESCRIPTION

This module provides a way to validate a value against multiple validators. The value is considered valid if it passes any of the validators.

=head1 METHODS

=head2 new

    my $validator = Poz::Types::union->new(@validators);
    
Creates a new union validator with the given validators.

=head2 parse

    my $valid = $validator->parse($value);

Validates the given value against the defined rules. Throws an error if the value is invalid.

=head2 safe_parse

    my ($valid, $errors) = $validator->safe_parse($value);

Validates the given value against the defined rules. If the value is valid, it returns the parsed value. If the value is invalid, it returns the validation errors.

=head2 optional

    $validator->optional;

Marks the value as optional.

=head2 default

    $validator->default($default);

Sets the default value for the validator.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

