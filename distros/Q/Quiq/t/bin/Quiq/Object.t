#!/usr/bin/env perl

package Quiq::Object::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Object');
}

# -----------------------------------------------------------------------------

sub test_bless : Test(1) {
    my $self = shift;

    my $class = 'Quiq::Hash';

    my $ref = $class->bless({});
    $self->is(ref($ref),$class);
}

# -----------------------------------------------------------------------------

sub test_rebless : Test(1) {
    my $self = shift;

    my $obj = Quiq::Hash->new;

    my $class = 'Quiq::Object';
    $obj->rebless($class);
    $self->is(ref($obj),$class);
}

# -----------------------------------------------------------------------------

sub test_addMethod : Test(2) {
    my $self = shift;

    # Wir nutzen die Klasse selbst als Testklasse
    my $testClass = 'Quiq::Object';

    # instantiiere Objekt

    my $h = bless {},$testClass;
    $self->is(ref($h),$testClass);

    # füge Methode hinzu

    $h->addMethod('myMethod',sub {
        my $self = shift;
        return 4711;
    });

    # rufe Methode auf

    my $r = $h->myMethod;
    $self->is($r,4711);
}

# -----------------------------------------------------------------------------

sub test_classFile : Test(1) {
    my $self = shift;

    my $path = 'Quiq::Object';
    $path =~ s|::|/|g;

    my $file = Quiq::Object->classFile;
    $self->like($file,qr|$path|);
}

# -----------------------------------------------------------------------------

sub test_this_scalar : Test(2) {
    my $self = shift;

    my $this = 'Quiq::Hash';
    my $class = Quiq::Object->this($this);
    $self->is($class,'Quiq::Hash');

    $this = Quiq::Hash->new;
    $class = Quiq::Object->this($this);
    $self->is($class,'Quiq::Hash');
}

sub test_this_list : Test(6) {
    my $self = shift;

    my $this = 'Quiq::Hash';
    my ($class,$obj,$isClassMethod) = Quiq::Object->this($this);
    $self->is($class,'Quiq::Hash');
    $self->is($obj,undef);
    $self->ok($isClassMethod);

    $this = Quiq::Hash->new;
    ($class,$obj,$isClassMethod) = Quiq::Object->this($this);
    $self->is($class,'Quiq::Hash');
    $self->is(ref($obj),'Quiq::Hash');
    $self->ok(!$isClassMethod);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Object::Test->runTests;

# eof
