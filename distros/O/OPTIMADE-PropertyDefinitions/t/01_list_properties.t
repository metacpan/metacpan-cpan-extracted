#!/usr/bin/perl

use strict;
use warnings;

use OPTIMADE::PropertyDefinitions;
use Test::More;

my $has_yaml_schemas = -d 'externals/OPTIMADE' ? 1 : 0;
my $has_json_schemas = -d 'externals/OPTIMADE/schemas/output' ? 1 : 0;

plan skip_all => 'No available cases' unless $has_yaml_schemas;
plan tests => 4 + $has_json_schemas;

my( $pd_yaml, $pd_json );
my( @properties_yaml, @properties_json );

$pd_yaml = OPTIMADE::PropertyDefinitions->new( 'externals/OPTIMADE/schemas/src/defs/v1.2/' );
is join( ',', sort map { $_->name } $pd_yaml->entry_types ), 'calculations,files,references,structures';
is scalar( map { $_->properties } $pd_yaml->entry_types ), 75;
@properties_yaml = map { $_->properties } $pd_yaml->entry_types;

if( $has_json_schemas ) {
    $pd_json = OPTIMADE::PropertyDefinitions->new( 'externals/OPTIMADE/schemas/output/defs/v1.2/', 'json' );
    @properties_json = map { $_->properties } $pd_json->entry_types;
}

if( $has_json_schemas ) {
    is join( '', sort map { $_->name } @properties_yaml ),
       join( '', sort map { $_->name } @properties_json );
}

$pd_yaml = OPTIMADE::PropertyDefinitions->new( 'externals/OPTIMADE/schemas/src/defs/v1.3/' );
is join( ',', sort map { $_->name } $pd_yaml->entry_types ), 'calculations,files,references,structures';
is scalar( map { $_->properties } $pd_yaml->entry_types ), 80;
