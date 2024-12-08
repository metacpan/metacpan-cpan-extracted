package Poz::Builder;
use 5.032;
use strict;
use warnings;
use Poz::Types::string;
use Poz::Types::number;
use Poz::Types::object;
use Poz::Types::array;
use Poz::Types::enum;

sub new {
    my ($class) = @_;
    bless {
        need_coerce => 0,
    }, $class;
}

sub coerce {
    my ($self) = @_;
    $self->{need_coerce} = 1;
    return $self;
}

sub string {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    return Poz::Types::string->new({
        %{$opts},
        need_coerce => $self->{need_coerce},
    });
}

sub date {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    return $self->string({invalid_type_error => 'Not a date', %$opts})->date;
}

sub number {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    return Poz::Types::number->new({
        %{$opts},
        need_coerce => $self->{need_coerce},
    });
}

sub object {
    my ($self, $opts) = @_;
    return Poz::Types::object->new({%$opts});
}

sub array {
    my ($self, $validator) = @_;
    return Poz::Types::array->new($validator);
}

sub enum {
    my ($self, $opts) = @_;
    return Poz::Types::enum->new($opts);
}

1;

=head1 NAME

Poz::Builder - A module for building Poz projects

=head1 SYNOPSIS

    use Poz::Builder;
    my $builder = Poz::Builder->new();
    $builder->build();

=head1 DESCRIPTION

Poz::Builder is a module designed to facilitate the building and management of Poz projects. It provides methods to streamline the build process and ensure consistency across different environments.

=head1 METHODS

=head2 new

    my $builder = Poz::Builder->new();
    
Creates a new Poz::Builder object.

=head2 build

    $builder->build();
    
Executes the build process for the Poz project.
=head2 coerce

    $builder->coerce();
    
Enables coercion for the builder, which affects how types are handled.

=head2 string

    my $string_type = $builder->string(\%opts);
    
Creates a new string type with the given options.

=head2 date

    my $date_type = $builder->date(\%opts);
    
Creates a new date type with the given options. This is a specialized string type.

=head2 number

    my $number_type = $builder->number(\%opts);
    
Creates a new number type with the given options.

=head2 object

    my $object_type = $builder->object(\%opts);
    
Creates a new object type with the given options.

=head2 array

    my $array_type = $builder->array($validator);
    
Creates a new array type with the given validator.

=head2 enum

    my $enum_type = $builder->enum(\%opts);
    
Creates a new enum type with the given options.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut