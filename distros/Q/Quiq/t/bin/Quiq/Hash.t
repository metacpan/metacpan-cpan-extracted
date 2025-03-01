#!/usr/bin/env perl

package Quiq::Hash::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Hash');
}

# -----------------------------------------------------------------------------

sub test_new_keyVal : Test(5) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1,b=>2,c=>3);
    $self->is(ref($h),'Quiq::Hash');
    $self->is($h->{'a'},1);
    $self->is($h->{'b'},2);
    $self->is($h->{'c'},3);
    $self->ok(!$h->exists('d'));
}

sub test_new_keys_vals : Test(5) {
    my $self = shift;

    my @keys = qw/a b c/;
    my @vals = qw/1 2 3/;

    my $h = Quiq::Hash->new(\@keys,\@vals);
    $self->is(ref($h),'Quiq::Hash');
    $self->is($h->{'a'},1);
    $self->is($h->{'b'},2);
    $self->is($h->{'c'},3);
    $self->ok(!$h->exists('d'));
}

sub test_new_keys_val : Test(5) {
    my $self = shift;

    my @keys = qw/a b c/;

    my $h = Quiq::Hash->new(\@keys,1);
    $self->is(ref($h),'Quiq::Hash');
    $self->is($h->{'a'},1);
    $self->is($h->{'b'},1);
    $self->is($h->{'c'},1);
    $self->ok(!$h->exists('d'));
}

sub test_new_hash : Test(5) {
    my $self = shift;

    my $h = Quiq::Hash->new({a=>1,b=>2,c=>3});
    $self->is(ref($h),'Quiq::Hash');
    $self->is($h->{'a'},1);
    $self->is($h->{'b'},2);
    $self->is($h->{'c'},3);
    $self->ok(!$h->exists('d'));
}

# -----------------------------------------------------------------------------

sub test_get : Test(5) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1,b=>2,c=>3);

    my $val = $h->get('b');
    $self->is($val,2,'Skalarkontext');

    $val = $h->{'b'};
    $self->is($val,2,'Direkter Hashzugriff');

    my @arr = $h->get('b','a');
    $self->isDeeply(\@arr,[2,1],'Listkontext');

    @arr = @{$h}{'b','a'};
    $self->isDeeply(\@arr,[2,1],'Direkter Hashzugriff');

    $val = eval {$h->get('d')};
    $self->ok($@,'Unerlaubter Schlüssel -> Exception');
}

# -----------------------------------------------------------------------------

sub test_getDeep : Test(5) {
    my $self = shift;

    my $h = Quiq::Hash->new({a=>{b=>{c=>3,d=>['x'],e=>{}}}});

    # Zugriff auf Skalaren Wert

    my $val = $h->getDeep('a.b.c');
    $self->is($val,3);

    # Zugriff auf Array

    $val = $h->getDeep('a.b.d');
    $self->is(ref($val),'ARRAY');

    $val = $h->getDeep('a.b.d.[0]');
    $self->is($val,'x');

    # Zugriff auf Hash

    $val = $h->getDeep('a.b.e');
    $self->is(ref($val),'HASH');

    # Zugriff auf nicht-existente Komponente

    $val = eval {$h->getDeep('a.b.x')};
    $self->like($@,qr/Non-existent access path/);
}

# -----------------------------------------------------------------------------

sub test_getRef : Test(1) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1,b=>2,c=>3);

    my $valS = $h->getRef('b');
    $$valS .= 'a';
    $self->is($h->{'b'},'2a');
}

# -----------------------------------------------------------------------------

sub test_getArray : Test(2) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1,b=>[1..5],c=>3);

    my $arr = $h->getArray('b');
    $self->isDeeply($arr,[1..5]);

    my @arr = $h->getArray('b');
    $self->isDeeply(\@arr,[1..5]);
}

# -----------------------------------------------------------------------------

sub test_try : Test(2) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1,b=>2,c=>3);

    my $val = $h->try('b');
    $self->is($val,2,'Skalarkontext');
    
    my @arr = $h->try('b','a');
    $self->isDeeply(\@arr,[2,1],'Listkontext');
}

# -----------------------------------------------------------------------------

sub test_set : Test(5) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1,b=>2,c=>3);

    $h->set(b=>5);
    $self->is($h->{'b'},5);

    $h->{'b'} = 5;
    $self->is($h->{'b'},5);

    @{$h}{'b','c'} = (6,7);
    $self->is($h->{'b'},6);
    $self->is($h->{'c'},7);

    eval {$h->set(d=>7)};
    $self->ok($@);
}

# -----------------------------------------------------------------------------

sub test_add : Test(2) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1,b=>2,c=>3);

    $h->add(b=>5,d=>7);
    $self->is($h->{'b'},5,'Neuer Wert');
    $self->is($h->{'d'},7,'Neues Schlüssel/Wert-Paar');
}

# -----------------------------------------------------------------------------

sub test_memoize : Test(1) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>undef);
    my $val = $h->memoize('a',sub {5});
    $self->is($val,5);
}

# -----------------------------------------------------------------------------

sub test_compute : Test(1) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1);

    my $val = $h->compute('a',sub {
        my ($h,$key) = @_;
        return ++$h->{$key};
    });
    $self->is($val,2);
}

# -----------------------------------------------------------------------------

sub test_AUTOLOAD : Test(3) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1,b=>2,c=>3);

    my $val = $h->a;
    $self->is($val,1);

    $h->a = 3;
    $self->is($h->a,3);

    eval{$h->d};
    $self->like($@,qr/HASH-00001/);
}

# -----------------------------------------------------------------------------

sub test_keys : Test(3) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1,b=>2,c=>3);

    my @keys = $h->keys;
    @keys = sort @keys;
    $self->isDeeply(\@keys,[qw/a b c/]);

    my $keyA = $h->keys;
    $self->is(ref($keyA),'ARRAY');
    @keys = sort @$keyA;
    $self->isDeeply(\@keys,[qw/a b c/]);
}

# -----------------------------------------------------------------------------

sub test_hashSize : Test(1) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1,b=>2,c=>3);
    my $n = $h->hashSize;
    $self->is($n,3);
}

# -----------------------------------------------------------------------------

sub test_validate : Test(2) {
    my $self = shift;

    my $h = {a=>1,b=>2,c=>3};

    eval{Quiq::Hash->validate($h,[qw/a b c/])};
    $self->ok(!$@);

    eval{Quiq::Hash->validate($h,[qw/a b d/])};
    $self->ok($@);
}

# -----------------------------------------------------------------------------

sub test_copy : Test(2) {
    my $self = shift;

    my $h1 = Quiq::Hash->new(a=>1,b=>2,c=>3);

    my $h2 = $h1->copy;
    $self->isnt($h1,$h2,'Referenzen verschieden');
    $self->isDeeply($h1,$h2,'Gleiche Schlüssel/Wert-Paare');
}

# -----------------------------------------------------------------------------

sub test_join : Test(1) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1,b=>2,c=>3);
    my %hash = (b=>4);
    my $expectedH = Quiq::Hash->new(a=>1,b=>4,c=>3);
    
    $h->join(\%hash);
    $self->isDeeply($h,$expectedH);
}

# -----------------------------------------------------------------------------

sub test_delete : Test(4) {
    my $self = shift;

    # Test-Hash erzeugen
    my $h = Quiq::Hash->new(a=>1,b=>2,c=>3);

    # Schlüssel entfernen

    $h->delete('a','c');
    my $keyA = $h->keys;
    $self->isDeeply($keyA,['b']);

    # Entfernte Schlüssel erneut setzen

    $h->set(a=>4,c=>5);
    my @arr = $h->get(qw/a b c/);
    $self->isDeeply(\@arr,[4,2,5]);

    # Mehrere Schlüssel auf konventionelle Weise entfernen

    delete @{$h}{'a','c'};
    $keyA = $h->keys;
    $self->isDeeply($keyA,['b']);

    # Neue Schlüssel können nicht hinzugeügt werden

    eval{$h->set(d=>6)};
    $self->ok($@);
}

# -----------------------------------------------------------------------------

sub test_clear : Test(2) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1,b=>2,c=>3);

    # Fix: CPAN Testers

    my $n = $h->hashSize;
    $self->is($n,3);

    $h->clear;

    $n = $h->hashSize;
    $self->is($n,0);
}

# -----------------------------------------------------------------------------

sub test_exists : Test(2) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1);

    my $bool = $h->exists('a');
    $self->ok($bool,'a existiert');

    $bool = $h->exists('b');
    $self->ok(!$bool,'b existiert nicht');
}

# -----------------------------------------------------------------------------

sub test_defined : Test(2) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1,b=>undef);

    my $bool = $h->defined('a');
    $self->ok($bool,'a ist definiert');

    $bool = $h->defined('b');
    $self->ok(!$bool,'b ist nicht definiert');
}

# -----------------------------------------------------------------------------

sub test_isEmpty : Test(2) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1,b=>2,c=>3);
    my $bool = $h->isEmpty;
    $self->ok(!$bool,'Nicht leer');

    $h->clear;
    $bool = $h->isEmpty;
    $self->ok($bool,'Leer');
}

# -----------------------------------------------------------------------------

sub test_isLocked : Test(3) {
    my $self = shift;

    # Leerer Hash

    my $h = Quiq::Hash->new;
    if ($] < 5.018) {
        # Bug in Perl-Versionen kleiner 5.18.0
        $self->is($h->isLocked,0,'Leerer Hash ist nicht gelocked');
    }
    else {
        $self->is($h->isLocked,1,'Leerer Hash ist gelocked');
    }

    # Nicht-Leerer Hash

    $h = Quiq::Hash->new(a=>1,b=>2,c=>3);

    my $isLocked = $h->isLocked;
    $self->is($isLocked,1,'Nicht-leerer Hash ist gelocked');

    $h->unlockKeys;
    $isLocked = $h->isLocked;
    $self->is($isLocked,0,'Lock ist aufgehoben');
}

# -----------------------------------------------------------------------------

sub test_lockKeys : Test(2) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1,b=>2,c=>3);

    $h->lockKeys;

    my $val = $h->{'b'};
    $self->is($val,2,'Key b');

    $val = eval {$h->{'d'}};
    $self->like($@,qr/disallowed key 'd'/,'Key d - Exception');
}

# -----------------------------------------------------------------------------

sub test_unlockKeys : Test(3) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1,b=>2,c=>3);
    $h->lockKeys;

    my $val = $h->{'b'};
    $self->is($val,2,'Key b');

    $val = eval { $h->{'d'} };
    $self->like($@,qr/disallowed key 'd'/,'Key d - Exception');

    $h->unlockKeys;

    $val = $h->{'d'};
    $self->is($val,undef,'Key d - undef');
}

# -----------------------------------------------------------------------------

sub test_arraySize : Test(3) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>[1..5],b=>undef,c=>{});

    my $n = $h->arraySize('a');
    $self->is($n,5);

    $n = $h->arraySize('b');
    $self->is($n,0);

    eval{$h->arraySize('c')};
    $self->like($@,qr/HASH-00005/);
}

# -----------------------------------------------------------------------------

sub test_setOrPush : Test(3) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>[1..5],b=>undef,c=>{});

    $h->setOrPush(a=>10);
    my $arr = $h->get('a');
    $self->isDeeply($arr,[1..5,10]);

    $h->setOrPush(a=>[20,30]);
    $self->isDeeply($arr,[1..5,10,20,30]);

    $h->setOrPush(b=>42);
    my $val = $h->get('b');
    $self->is($val,42);
}

# -----------------------------------------------------------------------------

sub test_push : Test(1) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>[1..5],b=>undef,c=>{});

    $h->push(a=>10);
    my $arr = $h->get('a');
    $self->isDeeply($arr,[1..5,10]);
}

# -----------------------------------------------------------------------------

sub test_addNumber : Test(1) {
    my $self = shift;

    my $h = Quiq::Hash->new(a=>1);

    my $y = $h->addNumber(a=>45.5);
    $self->is($y,46.5);
}

# -----------------------------------------------------------------------------

sub test_weaken : Test(2) {
    my $self = shift;

    my $child = Quiq::Hash->new;
    my $parent = Quiq::Hash->new(child=>$child);
    $parent->weaken('child');
    $self->ok($parent->get('child'),'Schwache Referenz');
    $child = undef;
    $self->is($parent->get('child'),undef,'Referenz entfernt');
}

# -----------------------------------------------------------------------------

sub test_buckets : Test(2) {
    my $self = shift;

    my $h = Quiq::Hash->new;
    my $n = $h->buckets(1000);
    $self->ok($n,'Positiver Wert'); # Fix: CPAN Testers
    $n = $h->hashSize;
    $self->is($n,0,'Hash ist leer');
}

# -----------------------------------------------------------------------------

sub test_bucketsUsed : Test(2) {
    my $self = shift;

    my $h = Quiq::Hash->new;
    my $n = $h->bucketsUsed;
    $self->is($n,0,'Hash ist leer');

    $h->add(a=>1,b=>2,c=>3);
    $n = $h->bucketsUsed;
    $self->ok($n,'Buckets vorhanden (Anzahl schwankt)');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Hash::Test->runTests;

# eof
