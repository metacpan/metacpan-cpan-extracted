#!/usr/bin/env perl

package Quiq::Html::Component::Bundle::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

use Quiq::Html::Component;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Component::Bundle');
}

# -----------------------------------------------------------------------------

sub test_unitTest_1 : Test(6) {
    my $self = shift;

    # Konstruktor

    my $b = Quiq::Html::Component::Bundle->new;
    $self->is(ref($b),'Quiq::Html::Component::Bundle');
    $self->is($b->count,0);

    # Komponenten hinzufügen

    my $c1 = Quiq::Html::Component->new(
        name => 'c1',
    );
    $b->push($c1);

    my $c2 = Quiq::Html::Component->new(
        name => 'c2',
    );
    $b->push($c2);

    $self->is($b->count,2);

    # Komponente ermitteln

    my $c = $b->component('c2');
    $self->is($c->name,'c2');

    # Liste der Komponenten

    my $componentA = $b->components;
    $self->isDeeply([map {$_->name} @$componentA],[qw/c1 c2/]);

    my @components = $b->components;
    $self->isDeeply([map {$_->name} @components],[qw/c1 c2/]);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Component::Bundle::Test->runTests;

# eof
