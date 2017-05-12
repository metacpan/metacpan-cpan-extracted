#!/usr/bin/perl -w

use Search::ContextGraph;
use Test::More  'no_plan';
use Data::Dumper;

my %docs = (
  'First Document' => { 'elephant' => 2, 'snake' => 1 },
  'Second Document' => { 'camel' => 1, 'pony' => 1 },
  'Third Document' => { 'snake' => 2, 'constrictor' => 1 },
);

for my $XS ( 0..1 ) {
	last if $XS;
	
	my $cg = Search::ContextGraph->new( xs => $XS);
	
	ok($cg, "have Search::ContextGraph object");
	
	# ACTIVATE THRESHOLD
	
	is($cg->get_activate_threshold(), 1, "Able to retrieve activate threshold" );
	ok($cg->set_activate_threshold( .5 ),  "Setting activate threshold" );
	is($cg->get_activate_threshold(), .5, "Activate threshold reset correctly" );
	
	
	# COLLECTION THRESHOLD
	
	$cg->set_collect_threshold(.13);
	ok( abs( $cg->get_collect_threshold() - .13 ) < .001, "Collect was set properly" );
	ok(	$cg->set_collect_threshold(0), "set collect threshold to zero" );
	is(  $cg->get_collect_threshold(), 0, "collect threshold updated properly" );

	
	# INITIAL ENERGY
	
	is( $cg->get_initial_energy(), 100, "got correct initial energy" );
	ok( $cg->set_initial_energy(120),  "reset initial energy" );
	is( $cg->get_initial_energy(), 120, "initial energy reset correctly" );
	
	
	# MAX DEPTH
	is( $cg->get_max_depth(), 100000000, "Got correct default depth" );
	ok( $cg->set_max_depth( 20 ), "Set maximum depth succeeded" );
	is( $cg->get_max_depth(), 20, "Maximum depth updated properly" );
	ok( $cg->set_max_depth(0), "Able to assign zero as maximum depth" );
	eval { $cg->set_max_depth() };
	ok( $@ =~ /Tried to set maximum depth to an undefined value/, 
				"did not allow maximum depth to be an undefined value");
	is( $cg->get_max_depth(), 100000000, "Got correct default depth" );
	
	# FAILURES
	
	# Can't set activation energy higher than initial energy;
	eval{ $cg->set_initial_energy( -200 ) };
	ok(  $@, "Can't set initial energy to negative value" );
	
	eval{ $cg->set_activate_threshold( 0 ) };
	ok(  $@, "Can't set activate threshold to zero" );
	
	eval{ $cg->set_activate_threshold( -120 ) };
	ok(  $@, "Can't set activate threshold to negative value" );
	
}