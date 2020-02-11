#!/usr/bin/env perl

package Quiq::List::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Hash;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::List');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(10) {
    my $self = shift;

    my $lst = Quiq::List->new;
    $self->is(ref($lst),'Quiq::List');

    my @objs = $lst->elements;
    $self->isDeeply(\@objs,[]);

    my $n = $lst->count;
    $self->is($n,0);

    my $obj = $lst->push(Quiq::Hash->new(
        produkt => 'Erdbeeren',
        preis => 3.99,
    ));
    $n = $lst->count;
    $self->is($n,1);
    $self->is(ref($obj),'Quiq::Hash');
    $self->is($obj->produkt,'Erdbeeren');
    $self->is($obj->preis,3.99);

    @objs = $lst->elements;
    $self->isDeeply(\@objs,[{produkt=>'Erdbeeren',preis=>3.99}]);

    $obj = $lst->push(Quiq::Hash->new(
        produkt => 'Pflaumen',
        preis => 2.99,
    ));

    my $str = join ',',$lst->map(sub {
        my $obj = shift;
        return $obj->produkt;
    });
    $self->is($str,'Erdbeeren,Pflaumen');

    $lst->loop(\my $sum,sub {
        my ($sumS,$obj,$i) = @_;
        $$sumS += $obj->preis;
    });
    $self->is($sum,6.98);
}

# -----------------------------------------------------------------------------

package main;
Quiq::List::Test->runTests;

# eof
