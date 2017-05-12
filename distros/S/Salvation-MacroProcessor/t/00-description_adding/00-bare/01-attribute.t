use strict;

package Salvation::MacroProcessor::_t00_00_01::Class;

use Moose;

use Salvation::MacroProcessor;

has 'attribute'	=> ( is => 'rw', isa => 'Any' );

smp_add_description 'attribute';

no Moose;

package main;

use Test::More tests => 15;

my $description = Salvation::MacroProcessor::_t00_00_01::Class -> meta() -> smp_find_description_by_name( 'attribute' );

isa_ok( $description, 'Salvation::MacroProcessor::MethodDescription', 'description' );

is( $description -> method(), 'attribute', 'method name is ok' );
is( $description -> orig_method(), 'attribute', 'original method name is ok' );

is_deeply( $description -> connector_chain(), [], 'have no connector chain' );

is( $description -> associated_meta(), Salvation::MacroProcessor::_t00_00_01::Class -> meta(), 'metaclass is here' );

my $attribute = $description -> attr();

isa_ok( $attribute, 'Moose::Meta::Attribute', 'corresponding Moose::Meta::Attribute' );

is( $attribute -> name(), 'attribute', 'name of corresponding Moose::Meta::Attribute is ok' );
is( $attribute -> associated_class(), Salvation::MacroProcessor::_t00_00_01::Class -> meta(), 'associated class of corresponding Moose::Meta::Attribute is ok' );

ok( not( defined $description -> inherited_description() ), 'have no inherited description' );

ok( not( $description -> has_query() ), 'have no query parts' );
ok( not( $description -> has_postfilter() ), 'have no postfilter' );
ok( not( $description -> has_required_shares() ), 'have no requred shares' );
ok( not( $description -> has_required_filters() ), 'have no requred filters' );
ok( not( $description -> has_excludes_filters() ), 'have no excluded filters' );

ok( ( not( eval{ $description -> query(); 1; } ) and $@ ), 'cannot process such description' );

