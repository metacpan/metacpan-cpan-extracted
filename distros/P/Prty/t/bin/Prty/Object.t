#!/usr/bin/env perl

package Prty::Object::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Object');
}

# -----------------------------------------------------------------------------

sub test_bless : Test(1) {
    my $self = shift;

    my $class = 'Prty::Hash';

    my $ref = $class->bless({});
    $self->is(ref($ref),$class);
}

# -----------------------------------------------------------------------------

sub test_rebless : Test(1) {
    my $self = shift;

    my $obj = Prty::Hash->new;

    my $class = 'Prty::Object';
    $obj->rebless($class);
    $self->is(ref($obj),$class);
}

# -----------------------------------------------------------------------------

sub test_addMethod : Test(2) {
    my $self = shift;

    # Wir nutzen die Klasse selbst als Testklasse
    my $testClass = 'Prty::Object';

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

    my $path = 'Prty::Object';
    $path =~ s|::|/|g;

    my $file = Prty::Object->classFile;
    $self->like($file,qr|$path|);
}

# -----------------------------------------------------------------------------

sub test_this_scalar : Test(2) {
    my $self = shift;

    my $this = 'Prty::Hash';
    my $class = Prty::Object->this($this);
    $self->is($class,'Prty::Hash');

    $this = Prty::Hash->new;
    $class = Prty::Object->this($this);
    $self->is($class,'Prty::Hash');
}

sub test_this_list : Test(6) {
    my $self = shift;

    my $this = 'Prty::Hash';
    my ($class,$obj,$isClassMethod) = Prty::Object->this($this);
    $self->is($class,'Prty::Hash');
    $self->is($obj,undef);
    $self->ok($isClassMethod);

    $this = Prty::Hash->new;
    ($class,$obj,$isClassMethod) = Prty::Object->this($this);
    $self->is($class,'Prty::Hash');
    $self->is(ref($obj),'Prty::Hash');
    $self->ok(!$isClassMethod);
}

# -----------------------------------------------------------------------------

package main;
Prty::Object::Test->runTests;

# eof
