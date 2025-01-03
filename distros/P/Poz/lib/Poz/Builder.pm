package Poz::Builder;
use 5.032;
use strict;
use warnings;
use Poz::Types::null;
use Poz::Types::string;
use Poz::Types::number;
use Poz::Types::object;
use Poz::Types::array;
use Poz::Types::enum;
use Poz::Types::union;
use Poz::Types::is;

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

sub null {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    return Poz::Types::null->new({
        %{$opts},
        need_coerce => $self->{need_coerce},
    });
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

sub datetime {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    return $self->string({invalid_type_error => 'Not a datetime', %$opts})->datetime;
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

sub union {
    my ($self, @validators) = @_;
    return Poz::Types::union->new(@validators);
}

sub is {
    my ($self, $isa) = @_;
    return Poz::Types::is->new($isa);
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

=head2 null

    my $null_type = $builder->null(\%opts);

Creates a new null type with the given options.

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

=head2 union

    my $union_type = $builder->union(@validators);

Creates a new union type with the given validators.

=head2 is

    my $is_type = $builder->is($isa);

Creates a new is type with the given class.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut
