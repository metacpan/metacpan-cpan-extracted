#!/usr/bin/perl

package Moose::Meta::Method::VariantTable;
use Moose;

extends qw(Moose::Object Moose::Meta::Method);

use MooseX::Types::VariantTable;

use Carp qw(croak);
use Sub::Name qw(subname);

has _variant_table => (
    isa => "MooseX::Types::VariantTable",
    is  => "ro",
    default => sub { MooseX::Types::VariantTable->new },
    handles => qr/^(?: \w+_variant$ | has_ )/x,
);

has class => (
    isa => "Class::MOP::Class",
    is  => "ro",
);

has name => (
    isa => "Str",
    is  => "ro",
);

has full_name => (
    isa => "Str",
    is  => "ro",
    lazy => 1,
    default => sub {
        my $self = shift;
        join "::", $self->class->name, $self->name;
    },
);

has super => (
    isa => "Maybe[Class::MOP::Method]",
    is  => "ro",
    lazy_build => 1,
);

sub _build_super {
    my $self = shift;

    $self->class->find_next_method_by_name($self->name);
}

has body => (
    isa => "CodeRef",
    is  => "ro",
    lazy => 1,
    builder => "initialize_body",
);

sub merge {
    my ( $self, @others ) = @_;

    return ( ref $self )->new(
        _variant_table => $self->_variant_table->merge(map { $_->_variant_table } @others),
    );
}

sub initialize_body {
    my $self = shift;

    my $variant_table = $self->_variant_table;

    my $super = $self->super;
    my $super_body = $super && $super->body;

    my $name = $self->name;

    return subname $self->full_name, sub {
        my ( $self, $value, @args ) = @_;

        if ( my ( $result, $type ) = $variant_table->find_variant($value) ) {
            my $method = (ref($result)||'') eq 'CODE'
                ? $result
                : $self->can($result);

            goto $method;
        } else {
            return $self->next::method($value, @args);
        }

        my $dump = eval { require Devel::PartialDump; 1 }
            ? \&Devel::PartialDump::dump
            : sub { return join $", map { overload::StrVal($_) } @_ };

        croak "No variant of method '$name' found for ", $dump->($value, @args);
    };
}


__PACKAGE__

__END__

