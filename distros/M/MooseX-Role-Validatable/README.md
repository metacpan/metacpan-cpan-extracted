[![Build Status](https://travis-ci.org/binary-com/perl-MooX-Role-Validatable.svg?branch=master)](https://travis-ci.org/binary-com/perl-MooX-Role-Validatable)
[![codecov](https://codecov.io/gh/binary-com/perl-MooX-Role-Validatable/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-MooX-Role-Validatable)


# NAME

MooseX::Role::Validatable - Role to add validation to a class

# SYNOPSIS

    package MyClass;

    use Moose;
    with 'MooseX::Role::Validatable';

    has 'attr1' => (is => 'ro', lazy_build => 1);

    sub _build_attr1 {
        my $self = shift;

        # Note initialization errors
        $self->add_errors( {
            message => 'Error: blabla',
            message_to_client => 'Something is wrong!'
        } ) if 'blabla';
    }

    sub _validate_some_other_errors { # _validate_*
        my $self = shift;

        my @errors;
        push @errors, {
            message => '...',
            message_to_client => '...',
        };

        return @errors;
    }

    ## use
    my $ex = MyClass->new();

    if (not $ex->initialized_correctly) {
        my @errors = $ex->all_init_errors();
        ...;    # We didn't even start with good data.
    }

    if (not $ex->confirm_validity) { # does not pass those _validate_*
        my @errors = $ex->all_errors();
        ...;
    }

# DESCRIPTION

MooseX::Role::Validatable is a Moo/Moose role which provides a standard way to add validation to a class.

# METHODS

## initialized\_correctly

no error when init the object (no add\_errors is called)

## add\_errors

    $self->add_errors(...)

add errors on those lazy attributes or sub BUILD

## confirm\_validity

run all those __\_validate\_\*__ messages and returns true if no error found.

## all\_errors

An array of the errors currently noted. combined with __all\_init\_errors__ and __all\_validation\_errors__

all errors including below methods are instance of error\_class, default to [MooseX::Role::Validatable::Error](https://metacpan.org/pod/MooseX::Role::Validatable::Error)

## all\_init\_errors

all errors on init

## all\_validation\_errors

all errors on validation

## all\_errors\_by\_severity

order by severity

## primary\_validation\_error

the first error of __all\_errors\_by\_severity__

## validation\_methods

A list of all validation methods available on this object.
This can be auto-generated from all methods which begin with
"\_validate\_" which is especially helpful in devleoping new validations.

You may wish to set this list directly on the object, if
you create and validate a lot of static objects.

## error\_class

default to [MooseX::Role::Validatable::Error](https://metacpan.org/pod/MooseX::Role::Validatable::Error), override by

    has '+error_class' => (is => 'ro', default => sub { 'My::Validatable::Error' });

    # or
    ->new(error_class => 'My::Validatable::Error');

# AUTHOR

Binary.com <fayland@binary.com>

# COPYRIGHT

Copyright 2014- Binary.com

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
