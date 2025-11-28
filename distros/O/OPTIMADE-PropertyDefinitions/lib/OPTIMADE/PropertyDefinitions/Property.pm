package OPTIMADE::PropertyDefinitions::Property;

# ABSTRACT: OPTIMADE Property
our $VERSION = '0.1.0'; # VERSION

use strict;
use warnings;

use List::Util qw( any );
use OPTIMADE::PropertyDefinitions::Property::Nested;

sub new
{
    my( $class, $parent, $name ) = @_;
    return bless { parent => $parent, name => $name }, $class;
}

sub name() { $_[0]->{name} }
sub parent() { $_[0]->{parent} }

sub property($)
{
    my( $self, $property ) = @_;

    if( !exists $self->raw->{properties} ||
        !exists $self->raw->{properties}{$property} ) {
        die "no such property '$property'\n";
    }

    return OPTIMADE::PropertyDefinitions::Property::Nested->new( $self, $property );
}

sub properties()
{
    my( $self ) = @_;
    return my @empty unless exists $self->raw->{properties};
    return map { OPTIMADE::PropertyDefinitions::Property::Nested->new( $self, $_ ) }
               sort keys %{$self->raw->{properties}};
}

sub description() { $_[0]->raw->{description} }
sub format() { $_[0]->raw->{format} }
sub optimade_type() { $_[0]->raw->{'x-optimade-type'} }
sub query_support() { $_[0]->parent->raw->{'query-support'} }
sub required() { exists $_[0]->raw->{required} ? @{$_[0]->raw->{required}} : my @empty }
sub response_level() { $_[0]->parent->raw->{'response-level'} }
sub sortable() { $_[0]->parent->raw->{sortable} }
sub support() { $_[0]->parent->raw->{support} }
sub type() { @{$_[0]->raw->{type}} }
sub unit() { $_[0]->raw->{'x-optimade-unit'} }
sub version() { $_[0]->raw->{version} }

sub is_nullable() { any { $_ eq 'null' } $_[0]->type }

sub raw() { $_[0]->parent->raw->{properties}{$_[0]->name} }

1;
