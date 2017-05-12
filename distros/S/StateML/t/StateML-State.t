use Test;
use StateML::State;
use StateML::Arc;
use StateML::Event;
use StateML::Machine;
use strict;

my $m;
my $s0;
my $s1;

my @tests = (
sub {
    $m = StateML::Machine->new(   ID => "m0" );
    $m->add( StateML::Event->new( ID => "e0" ) );
    $m->add( $s0 = StateML::State->new( ID => "s0" ) );
    $m->add( $s1 = StateML::State->new( ID => "s1" ) );
    $m->add( StateML::Arc->new(   ID => "a01", FROM => "s0", TO => "s1" ) );
    $m->add( StateML::Arc->new(   ID => "a10", FROM => "s1", TO => "s0" ) );
    ok 1;
},

sub {
    ok join( "", map $_->id, $s0->arcs_from ), "a01";
},

sub {
    ok join( "", map $_->id, $s0->arcs_to   ), "a10";
},

);

plan tests => 0+@tests;

$_->() for @tests;
