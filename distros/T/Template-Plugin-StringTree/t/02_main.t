#!/usr/bin/perl

# Load test the Template::Plugin::StringTree module and do some super-basic tests

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

# Does everything load?
use Test::More 'tests' => 45;
use Template::Plugin::StringTree ();





# Creation and null stuff and support methods
my $TPS = "Template::Plugin::StringTree";
my $Tree = $TPS->new;
isa_ok( $Tree, $TPS );
is( $Tree->freeze, 'null', "Null freeze returns expected value" );
is_deeply( $Tree->_path('a'), [ 'a' ], "Basic path returns correctly" );
is_deeply( $Tree->_path('a.b.c'), [ 'a', 'b', 'c' ], "Longer path returns correctly" );

# Basic get/set
ok( $Tree->set('foo', 'bar'), "Trival set returns true" );
is( $Tree->get('foo'), 'bar', "Trivial get returns the set value" );
is( $Tree->get('bad'), undef, "Non-existant get returns undef" );

# More complex
ok( $Tree->set('foo.a', 'b'), "More complex set returns true" );
is( $Tree->get('foo'), 'bar', "Trival set value stays the same" );
is( $Tree->get('foo.a'), 'b', "More complex get returns the set value" );

# Long
ok( $Tree->set('a.b.c.d.e.f.g', "foo"), "Long set returns true" );
is( $Tree->get('a.b.c.d.e.f.g'), "foo", "Long get returns the set value" );
is( $Tree->get('a')            , undef, "Unoccupied node returns undef" );
is( $Tree->get('a.b')          , undef, "Unoccupied node returns undef" );
is( $Tree->get('a.b.c')        , undef, "Unoccupied node returns undef" );
is( $Tree->get('a.b.c.d')      , undef, "Unoccupied node returns undef" );
is( $Tree->get('a.b.c.d.e')    , undef, "Unoccupied node returns undef" );
is( $Tree->get('a.b.c.d.e.f')  , undef, "Unoccupied node returns undef" );

# Check ->add
ok( $Tree->add('a.b.c', 'foo'), "Added a value to an unset node" );
is( $Tree->get('a.b.c'), 'foo', "Got added value back the same" );
ok( ! $Tree->add('foo.a', 'c'), "Failed to add a value to an already set node" );
is( $Tree->get('foo.a'), 'b', "Failed added value remains unchanged" );

# Test freeze
my $frozen = <<'END_FREEZE';
a.b.c: foo
a.b.c.d.e.f.g: foo
foo: bar
foo.a: b
END_FREEZE
is( $Tree->freeze, $frozen, "->freeze output matches expected" );

# Do a loopback test
my $Object = $TPS->thaw( $frozen );
isa_ok( $Object, $TPS );
is( $Object->freeze, $frozen, "thaw -> freeze loop works" );

# Test ->equal
ok ( $Tree->equal('foo', 'bar'),     "Equal returns expected value" );
ok ( $Tree->equal('a.b.c', 'foo'),   "Equal returns expected value" );
ok ( $Tree->equal('foo.a', 'b'),     "Equal returns expected value" );
ok ( $Tree->equal('foo.b', undef),   "Equal returns expected value" );
ok ( ! $Tree->equal('foo', undef),   "Equal returns expected value" );
ok ( ! $Tree->equal('foo.b', 'foo'), "Equal returns expected value" );

# Test ->clone
my $Cloned = $Object->clone;
is( $Object->freeze, $Cloned->freeze, "Cloning works" );

# Test ->hash
my $hash = $Object->hash;
ok( (ref $hash eq 'HASH'), "->hash produces a normal hash, not an object" );

# Test stringification
my $node = $Tree->{a}->{b}->{c};
isa_ok( $node, "${TPS}::Node" );
is( "$node", "foo", "Node stringification works fine" );

# Check the 'can' and 'isa' bugs
my $Test = $TPS->new;
ok( $Test->set('foo.can.dance', 'foo'), "Setting up can check" );
ok( ref $Test->{foo}->can eq "${TPS}::Node", "One-argument form of can is caught correctly" );
ok( $Test->{foo}->can('__get'), "Two-argument form of can is caught correctly" );
ok( $Test->set('foo.isa.dancer', 'dance!'), "Setting up isa check" );
ok( ref $Test->{foo}->isa eq "${TPS}::Node", "One-argument form of can is caught correctly" );
ok( $Test->{foo}->isa('UNIVERSAL'), "Two-argument form of isa is caught correctly" );

# Check boolean casting
my $Cast = $TPS->new;
ok( $Cast->set('build.modperl', 0), "Setting up bool check" );
ok( $Cast->set('build.modperl.only', 0), "Setting up bool check" );
isa_ok( $Cast->hash->{build}->{modperl}, "${TPS}::Node", "Setting up bool check" );
if ( $Cast->hash->{build}->{modperl} ) {
	ok( '', "Checking bool case" );
} else {
	ok( 1, "Check bool case" );
}
