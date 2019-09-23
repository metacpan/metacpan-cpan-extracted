#!/usr/bin/env perl

package Quiq::OrderedHash::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::OrderedHash');
}

# -----------------------------------------------------------------------------

# Test der Grundfunktionalität

sub test_unitTest : Test(5) {
    my $self = shift;

    my @keys = ('a'..'d');
    my $oh = Quiq::OrderedHash->new(a=>1,b=>2,c=>3,d=>4);
    $self->is(ref($oh),'Quiq::OrderedHash');

    my $arr = $oh->keys;
    $self->isDeeply($arr,\@keys);

    my @arr = $oh->keys;
    $self->isDeeply(\@arr,\@keys);

    $oh->set(d=>7,b=>9);
    $arr = $oh->keys;
    $self->isDeeply($arr,\@keys);

    $oh->set(z=>26,y=>25);
    $arr = $oh->keys;
    $self->isDeeply($arr,['a'..'d','z','y']);
}

# -----------------------------------------------------------------------------

sub test_get : Test(3) {
    my $self = shift;

    my $oh = Quiq::OrderedHash->new(a=>1,b=>2,c=>3,d=>4);

    my $val = $oh->get('b');
    $self->is($val,2);

    my @arr = $oh->get('b');
    $self->isDeeply(\@arr,[2]);

    @arr = $oh->get('b','d','a');
    $self->isDeeply(\@arr,[2,4,1]);
}

# -----------------------------------------------------------------------------

sub test_setDelete : Test(2) {
    my $self = shift;

    my $oh = Quiq::OrderedHash->new(a=>1,b=>2,c=>3,d=>4);

    $oh->setDelete(b=>5,a=>undef,z=>26);
    my $arr = $oh->keys;
    $self->isDeeply($arr,['b'..'d','z']);
    $arr = $oh->values;
    $self->isDeeply($arr,[5,3,4,26]);
}

# -----------------------------------------------------------------------------

sub test_clear : Test(4) {
    my $self = shift;

    my $oh = Quiq::OrderedHash->new(a=>1,b=>2,c=>3,d=>4);

    $oh->clear;
    my $arr = $oh->keys;
    $self->isDeeply($arr,[]);
    $arr = $oh->values;
    $self->isDeeply($arr,[]);

    $oh = Quiq::OrderedHash->new(a=>1,b=>2,c=>3,d=>4);

    $oh->clear(z=>26,y=>25);
    $arr = $oh->keys;
    $self->isDeeply($arr,['z','y']);
    $arr = $oh->values;
    $self->isDeeply($arr,[26,25]);
}

# -----------------------------------------------------------------------------

sub test_copy : Test(3) {
    my $self = shift;

    my $oh1 = Quiq::OrderedHash->new(a=>1,b=>2,c=>3,d=>4);
    my $oh2 = $oh1->copy;

    $self->isnt($oh1,$oh2);

    my $arr1 = $oh1->keys;
    my $arr2 = $oh2->keys;
    $self->isDeeply($arr1,$arr2);

    $arr1 = $oh1->values;
    $arr2 = $oh2->values;
    $self->isDeeply($arr1,$arr2);
}

# -----------------------------------------------------------------------------

sub test_delete : Test(2) {
    my $self = shift;

    my $oh = Quiq::OrderedHash->new(a=>1,b=>2,c=>3,d=>4);

    $oh->delete('c','a','z','a');

    my $arr = $oh->keys;
    $self->isDeeply($arr,['b','d']);

    $arr = $oh->values;
    $self->isDeeply($arr,[2,4]);
}

# -----------------------------------------------------------------------------

sub test_increment : Test(3) {
    my $self = shift;

    my $h = Quiq::OrderedHash->new(a=>1,b=>2,c=>3);

    my $n = $h->increment('a');
    $self->is($n,2);

    $n = $h->increment('b');
    $self->is($n,3);

    $n = $h->increment('c');
    $self->is($n,4);
}

# -----------------------------------------------------------------------------

sub test_keys : Test(3) {
    my $self = shift;

    my $oh = Quiq::OrderedHash->new(a=>1,b=>2,c=>3,d=>4);

    my $arr = $oh->keys;
    $self->isDeeply($arr,['a'..'d']);

    $oh->set(e=>5,f=>6);

    $arr = $oh->keys;
    $self->isDeeply($arr,['a'..'f']);

    $oh->set(b=>9,d=>11);

    $arr = $oh->keys;
    $self->isDeeply($arr,['a'..'f']);
}

# -----------------------------------------------------------------------------

sub test_hashSize : Test(2) {
    my $self = shift;

    my $oh = Quiq::OrderedHash->new;
    my $n = $oh->hashSize;
    $self->is($n,0);

    $oh = Quiq::OrderedHash->new(a=>1,b=>2,c=>3,d=>4);
    $n = $oh->hashSize;
    $self->is($n,4);
}

# -----------------------------------------------------------------------------

sub test_unshift : Test(4) {
    my $self = shift;

    my $oh = Quiq::OrderedHash->new(a=>1,b=>2,c=>3,d=>4);

    $oh->unshift(z=>26);

    my $arr = $oh->keys;
    $self->isDeeply($arr,['z','a'..'d']);
    $arr = $oh->values;
    $self->isDeeply($arr,[26,1..4]);

    $oh->unshift(b=>5);

    $arr = $oh->keys;
    $self->isDeeply($arr,['z','a'..'d']);
    $arr = $oh->values;
    $self->isDeeply($arr,[26,1,5,3,4]);
}

# -----------------------------------------------------------------------------

sub test_values : Test(3) {
    my $self = shift;

    my $oh = Quiq::OrderedHash->new(a=>1,b=>2,c=>3,d=>4);

    my $arr = $oh->values;
    $self->isDeeply($arr,[1..4]);

    $oh->set(e=>5,f=>6);

    $arr = $oh->values;
    $self->isDeeply($arr,[1..6]);

    $oh->set(b=>9,d=>11);

    $arr = $oh->values;
    $self->isDeeply($arr,[1,9,3,11,5,6]);
}

# -----------------------------------------------------------------------------

sub test_exists : Test(2) {
    my $self = shift;

    my $oh = Quiq::OrderedHash->new(a=>1,b=>2,c=>3,d=>4);

    my $bool = $oh->exists('b');
    $self->is($bool,1);

    $bool = $oh->exists('z');
    $self->is($bool,0);
}

# -----------------------------------------------------------------------------

package main;
Quiq::OrderedHash::Test->runTests;

# eof
