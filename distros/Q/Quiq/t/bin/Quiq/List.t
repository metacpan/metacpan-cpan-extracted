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

sub test_unitTest : Test(13) {
    my $self = shift;

    # new()

    my $lst = Quiq::List->new;
    $self->is(ref($lst),'Quiq::List');

    # elements()

    my @objs = $lst->elements;
    $self->isDeeply(\@objs,[]);

    # count()

    my $n = $lst->count;
    $self->is($n,0);

    # push(), count(), elements()

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
    $n = $lst->count;
    $self->is($n,2);

    # map()

    my $str = join ',',$lst->map(sub {
        my $obj = shift;
        return $obj->produkt;
    });
    $self->is($str,'Erdbeeren,Pflaumen');

    # grep()

    my @objects = $lst->grep(sub {
        my $obj = shift;
        return substr($obj->produkt,0,1) eq 'P'? 1: 0;
    });
    $self->isDeeply(\@objects,[{produkt=>'Pflaumen',preis=>2.99}]);

    # loop()

    $lst->loop(\my $sum,sub {
        my ($obj,$i,$sumS) = @_;
        $$sumS += $obj->preis;
    });
    $self->is($sum,6.98);

    # Simplere Fassung

    $sum = 0;
    $lst->loop(sub {
        $sum += shift->preis;
    });
    $self->is($sum,6.98);
}

# -----------------------------------------------------------------------------

package main;
Quiq::List::Test->runTests;

# eof
