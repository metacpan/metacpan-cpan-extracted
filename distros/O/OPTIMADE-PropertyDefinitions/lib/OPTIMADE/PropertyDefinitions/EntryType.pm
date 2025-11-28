package OPTIMADE::PropertyDefinitions::EntryType;

# ABSTRACT: OPTIMADE Entry Type
our $VERSION = '0.1.0'; # VERSION

use strict;
use warnings;

use OPTIMADE::PropertyDefinitions::Property;

sub new
{
    my( $class, $parent, $name ) = @_;
    return bless { parent => $parent, name => $name }, $class;
}

sub property($)
{
    my( $self, $property ) = @_;
    die "no such property '$property'\n" unless $self->raw->{properties}{$property};
    return OPTIMADE::PropertyDefinitions::Property->new( $self, $property );
}

sub properties()
{
    my( $self ) = @_;
    return map { OPTIMADE::PropertyDefinitions::Property->new( $self, $_ ) }
               sort keys %{$self->raw->{properties}};
}

sub name() { $_[0]->{name} }
sub parent() { $_[0]->{parent} }

sub raw() { $_[0]->parent->raw->{entrytypes}{$_[0]->name} }

1;
