#!/usr/bin/perl
use strict;
use warnings;
use Benchmark qw(:all :hireswallclock);

require "egObjectLocalVars.pl";     # avoid CPAN indexing of .pm
require "egClassMethodMaker.pl";
require "egHandRoll.pl";

my $egObjectLocalVars = egObjectLocalVars->new;
my $egClassMethodMaker = egClassMethodMaker->new;
my $egHandRoll = egHandRoll->new;

my %many_objs;
sub create {
    my $class = shift;
    push @{$many_objs{$class}}, $class->new;
}

sub destroy {
    my $class = shift;
    @{$many_objs{$class}} = ();
}

sub churn {
    my ($obj, $n) = @_;
    $n = 1 if $n < 1;
    while ($n--) {
        $obj->set_prop1(1);
        $obj->prop1;
    }
    return; 
}

sub cycle {
    my $obj = shift->new;
    $obj->crunch(shift);
}

print "OBJECT CREATION\n";
cmpthese ( 500000, {
    'Class::MethodMaker'    => sub { create("egClassMethodMaker") },
    'Object::LocalVars'     => sub { create("egObjectLocalVars") },
    'Hand Rolled'           => sub { create("egHandRoll") },
});

print "\nOBJECT DESTRUCTION\n";
cmpthese ( 500000, {
    'Class::MethodMaker'    => sub { destroy("egClassMethodMaker") },
    'Object::LocalVars'     => sub { destroy("egObjectLocalVars") },
    'Hand Rolled'           => sub { destroy("egHandRoll") },
});

print "\nOBJECT PROPERTY MUTATOR\n";
cmpthese ( 500000, {
    'Class::MethodMaker'    => sub { $egClassMethodMaker->set_prop1(1) },
    'Object::LocalVars'     => sub { $egObjectLocalVars->set_prop1(1) },
    'Hand Rolled'           => sub { $egHandRoll->set_prop1(1) },
});

print "\nOBJECT PROPERTY ACCESSOR\n";
cmpthese ( 1000000, {
    'Class::MethodMaker'    => sub { $egClassMethodMaker->prop1() },
    'Object::LocalVars'     => sub { $egObjectLocalVars->prop1() },
    'Hand Rolled'           => sub { $egHandRoll->prop1() },
});

print "\nOBJECT PROPERTY MUTATE AND ACCESS\n";
cmpthese ( 500000, {
    'Class::MethodMaker'    => sub { churn($egClassMethodMaker,1) },
    'Object::LocalVars'     => sub { churn($egObjectLocalVars,1) },
    'Hand Rolled'           => sub { churn($egHandRoll,1) },
});

print "\nOBJECT PROPERTY ACCESS INSIDE METHODS: 1 CYCLE\n";
cmpthese ( 500000, {
    'Class::MethodMaker'    => sub { $egClassMethodMaker->crunch(1) },
    'Object::LocalVars'     => sub { $egObjectLocalVars->crunch(1) },
    'Hand Rolled'           => sub { $egHandRoll->crunch(1) },
});

print "\nOBJECT PROPERTY ACCESS INSIDE METHODS: 5 CYCLES\n";
cmpthese ( 100000, {
    'Class::MethodMaker'    => sub { $egClassMethodMaker->crunch(5) },
    'Object::LocalVars'     => sub { $egObjectLocalVars->crunch(5) },
    'Hand Rolled'           => sub { $egHandRoll->crunch(5) },
});

print "\nOBJECT PROPERTY ACCESS INSIDE METHODS: 10 CYCLES\n";
cmpthese ( 100000, {
    'Class::MethodMaker'    => sub { $egClassMethodMaker->crunch(10) },
    'Object::LocalVars'     => sub { $egObjectLocalVars->crunch(10) },
    'Hand Rolled'           => sub { $egHandRoll->crunch(10) },
});

print "\nOBJECT CREATE, ACCESS INSIDE, DESTROY: 1 CYCLE\n";
cmpthese ( 100000, {
    'Class::MethodMaker'    => sub { cycle("egClassMethodMaker",1) },
    'Object::LocalVars'     => sub { cycle("egObjectLocalVars",1) },
    'Hand Rolled'           => sub { cycle("egHandRoll",1) },
});

print "\nOBJECT CREATE, ACCESS INSIDE, DESTROY: 5 CYCLES\n";
cmpthese ( 100000, {
    'Class::MethodMaker'    => sub { cycle("egClassMethodMaker",5) },
    'Object::LocalVars'     => sub { cycle("egObjectLocalVars",5) },
    'Hand Rolled'           => sub { cycle("egHandRoll",5) },
});

print "\nOBJECT CREATE, ACCESS INSIDE, DESTROY: 10 CYCLES\n";
cmpthese ( 100000, {
    'Class::MethodMaker'    => sub { cycle("egClassMethodMaker",10) },
    'Object::LocalVars'     => sub { cycle("egObjectLocalVars",10) },
    'Hand Rolled'           => sub { cycle("egHandRoll",10) },
});

    

