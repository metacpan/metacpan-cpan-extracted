package Poz::Types::object;
use 5.032;
use strict;
use warnings;
use Carp ();
use Try::Tiny;

sub new {
    my ($class, $struct) = @_;
    my $self = bless { 
        __struct__ => {},
        __as__     => undef,
    }, $class;
    for my $key (keys %$struct) {
        my $v = $struct->{$key};
        if ($v->isa('Poz::Types')) {
            $self->{__struct__}{$key} = $v;
        }
    }
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
    if (ref($data) ne 'HASH') {
        push @errors, {
            key   => undef,
            error => "Invalid data: is not hashref"
        };
    } else {
        for my $key (sort keys %{$self->{__struct__}}) {
            my $v = $self->{__struct__}{$key};
            my $val = $data->{$key};
            try {
                $v->parse($val);
            } catch {
                my $error_message = $_;
                $error_message =~ s/ at .+ line [0-9]+\.\n//;
                push @errors, {
                    key   => $key,
                    error => $error_message,
                };
            }
        }
    }
    if (scalar(@errors) > 0) {
        return (undef, [@errors])
    }
    my $classname = $self->{__as__};
    my $valid = $classname ? bless {%$data}, $classname : {%$data};
    return ($valid, undef);
}

sub _errors_to_string {
    my $errors = shift;
    my @error_strings = ();
    for my $error (@$errors) {
        push @error_strings, sprintf("%s on key `%s`", $error->{error}, $error->{key});
    }
    return join(", and ", @error_strings);
}

1;

=head1 NAME

Poz::Types::object - A module for handling structured data with type validation

=head1 SYNOPSIS

    use Poz qw/z/;

    my $object = z->object({
        name => z->string,
        age => z->number,
    })->as('Some::Class');

    my $parsed_data = $object->parse($data);

=head1 DESCRIPTION

Poz::Types::object is a module for handling structured data with type validation. It allows you to define a structure with specific types and validate data against this structure.

=head1 METHODS

=head2 as

    $object->as($typename);

Sets the class name to bless the parsed data into. The C<$typename> parameter should be a string representing the class name.

=head2 parse

    my $parsed_data = $object->parse($data);

Parses and validates the given data against the structure. If the data is valid, it returns the parsed data. If the data is invalid, it throws an exception with the validation errors.

=head2 safe_parse

    my ($valid, $errors) = $object->safe_parse($data);

Parses and validates the given data against the structure. If the data is valid, it returns the parsed data and undef for errors. If the data is invalid, it returns undef for valid data and an array reference of errors.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut