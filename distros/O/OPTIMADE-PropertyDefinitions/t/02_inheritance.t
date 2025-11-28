#!/usr/bin/perl

use strict;
use warnings;

use OPTIMADE::PropertyDefinitions;
use Test::More;

my $has_yaml_schemas = -d 'externals/OPTIMADE' ? 1 : 0;

plan skip_all => 'No available cases' unless $has_yaml_schemas;
plan tests => 3;

my $pd = OPTIMADE::PropertyDefinitions->new( 'externals/OPTIMADE/schemas/src/defs/v1.2/' );

my $id = $pd->entry_type( 'structures' )->property( 'id' );
is $id->optimade_type, 'string', 'simple one-step resolution';

my $struct_assemblies_sites_in_groups = $pd->entry_type( 'structures' )->property( 'assemblies' )->property( 'sites_in_groups' );
is $struct_assemblies_sites_in_groups->optimade_type, 'list';

my $ref_editor_name = $pd->entry_type( 'references' )->property( 'editors' );
is $ref_editor_name->unit, 'inapplicable';
