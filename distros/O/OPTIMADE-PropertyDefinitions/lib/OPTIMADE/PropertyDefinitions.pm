package OPTIMADE::PropertyDefinitions;

# ABSTRACT: Top-level Property Definition class
our $VERSION = '0.1.0'; # VERSION

use strict;
use warnings;

use OPTIMADE::PropertyDefinitions::EntryType;
use JSON;
use YAML qw( LoadFile );

sub new
{
    my( $class, $path, $format ) = @_;
    $path .= '/' unless $path =~ /\/$/;
    $format = 'yaml' unless $format;
    return bless { path => $path, format => $format }, $class;
}

sub entry_type($)
{
    my( $self, $entry_type ) = @_;
    die "no such entry type '$entry_type'\n" unless $self->raw->{entrytypes}{$entry_type};
    return OPTIMADE::PropertyDefinitions::EntryType->new( $self, $entry_type );
}

sub entry_types()
{
    my( $self ) = @_;
    return map { OPTIMADE::PropertyDefinitions::EntryType->new( $self, $_ ) }
               sort keys %{$self->raw->{entrytypes}};
}

sub path() { $_[0]->{path} }

sub raw()
{
    my( $self ) = @_;
    $self->{raw} = $self->_raw( 'standards/optimade' ) unless $self->{raw};
    return $self->{raw};
}

sub _raw($)
{
    my( $self, $path ) = @_;
    if(      $self->{format} eq 'json' ) {
        open my $inp, '<', $self->path . $path . '.json';
        my $json = decode_json join '', <$inp>;
        close $inp;
        return $json;
    } elsif( $self->{format} eq 'yaml' ) {
        return $self->_resolve_inherits( LoadFile( $self->path . $path . '.yaml' ) );
    } else {
        die "no such format '$self->{format}'\n";
    }
}

sub _resolve_inherits($$)
{
    my( $self, $yaml ) = @_;

    if( exists $yaml->{'$$inherit'} ) {
        my $parent = $self->_raw( '..' . $yaml->{'$$inherit'} );
        $yaml = { %$parent, %$yaml };
    }

    for my $key (keys %$yaml) {
        next unless ref $yaml->{$key} eq 'HASH';
        $yaml->{$key} = $self->_resolve_inherits( $yaml->{$key} );
    }

    return $yaml;
}

1;
