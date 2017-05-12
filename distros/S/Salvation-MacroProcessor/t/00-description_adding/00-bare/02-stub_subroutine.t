use strict;

package Salvation::MacroProcessor::_t00_00_02::Class;

use Moose;

use Salvation::MacroProcessor;

sub method;

smp_add_description 'method';

no Moose;

package main;

use Test::More tests => 13;

my $description = Salvation::MacroProcessor::_t00_00_02::Class -> meta() -> smp_find_description_by_name( 'method' );

isa_ok( $description, 'Salvation::MacroProcessor::MethodDescription', 'description' );

is( $description -> method(), 'method', 'method name is ok' );
is( $description -> orig_method(), 'method', 'original method name is ok' );

is_deeply( $description -> connector_chain(), [], 'have no connector chain' );

is( $description -> associated_meta(), Salvation::MacroProcessor::_t00_00_02::Class -> meta(), 'metaclass is here' );

ok( not( defined $description -> attr() ), 'have no corresponding Moose::Meta::Attribute' );

ok( not( defined $description -> inherited_description() ), 'have no inherited description' );

ok( not( $description -> has_query() ), 'have no query parts' );
ok( not( $description -> has_postfilter() ), 'have no postfilter' );
ok( not( $description -> has_required_shares() ), 'have no requred shares' );
ok( not( $description -> has_required_filters() ), 'have no requred filters' );
ok( not( $description -> has_excludes_filters() ), 'have no excluded filters' );

ok( ( not( eval{ $description -> query(); 1; } ) and $@ ), 'cannot process such description' );

