#!/usr/bin/env perl

package Quiq::Database::Row::Object::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Database::Row::Object');
}

# -----------------------------------------------------------------------------

sub test_new : Test(7) {
    my $self = shift;

    my @titles = qw/a b c/;
    my @values = qw/1 2 3/;

    my $obj = Quiq::Database::Row::Object->new(\@titles,\@values);
    $self->is(ref($obj),'Quiq::Database::Row::Object');
    $self->is(ref($obj->[0]),'Quiq::Hash');
    $self->isDeeply($obj->[1],\@titles);
    $self->is($obj->[2],'I');
    $self->is($obj->[3],undef);
    $self->is($obj->[4],undef);
    $self->is($obj->[5],undef);
}

sub test_new_keyVal : Test(7) {
    my $self = shift;

    my @titles = qw/a b c/;

    my $obj = Quiq::Database::Row::Object->new(a=>1,b=>2,c=>3);
    $self->is(ref($obj),'Quiq::Database::Row::Object');
    $self->is(ref($obj->[0]),'Quiq::Hash');
    $self->isDeeply($obj->[1],\@titles);
    $self->is($obj->[2],'I');
    $self->is($obj->[3],undef);
    $self->is($obj->[4],undef);
    $self->is($obj->[5],undef);
}

# -----------------------------------------------------------------------------

sub test_exists : Test(4) {
    my $self = shift;

    my $row = Quiq::Database::Row::Object->new(a=>1,b=>2,c=>3);

    for my $key (qw/a b c/) {
        $self->ok($row->exists($key));
    }

    $self->ok(!$row->exists('d'));
}

# -----------------------------------------------------------------------------

sub test_get : Test(4) {
    my $self = shift;

    my $row = Quiq::Database::Row::Object->new(a=>1,b=>2,c=>3);

    my $val = $row->get('b');
    $self->is($val,2);

    my ($a,$b,$c) = $row->get(qw/a b c/);
    $self->is($a,1);
    $self->is($b,2);
    $self->is($c,3);
}

# -----------------------------------------------------------------------------

sub test_try : Test(2) {
    my $self = shift;

    my $row = Quiq::Database::Row::Object->new(a=>1,b=>2,c=>3);

    my $val = $row->try('b');
    $self->is($val,2);

    $val = $row->try('d');
    $self->is($val,undef);
}

# -----------------------------------------------------------------------------

sub test_set : Test(1) {
    my $self = shift;

    my $row = Quiq::Database::Row::Object->new(a=>1,b=>2,c=>3);

    eval {$row->set(d=>4)};
    $self->ok($@);
}

# -----------------------------------------------------------------------------

sub test_init : Test(3) {
    my $self = shift;

    my $row = Quiq::Database::Row::Object->new(a=>1,b=>2,c=>3);
    my $titles = $row->titles;
    $self->isDeeply($titles,[qw/a b c/]);

    my $obj = Quiq::Hash->new(a=>4,b=>5,c=>6,d=>7);
    $row->init($obj);
    $titles = $row->titles;
    $self->isDeeply($titles,[qw/a b c/]);
    my @arr = $row->get(qw/a b c/);
    $self->isDeeply(\@arr,[qw/4 5 6/]);
}

# -----------------------------------------------------------------------------

sub test_addAttribute : Test(3) {
    my $self = shift;

    my $row = Quiq::Database::Row::Object->new(a=>1,b=>2,c=>3);

    $row->addAttribute('d','e');
    my $val = $row->d;
    $self->is($val,'');
    $val = $row->e;
    $self->is($val,'');
    eval {$row->f};
    $self->like($@,qr/ROW-00002/);
}

# -----------------------------------------------------------------------------

sub test_add : Test(1) {
    my $self = shift;

    my $row = Quiq::Database::Row::Object->new(a=>1,b=>2,c=>3);

    $row->add(d=>4);
    my $val = $row->d;
    $self->is($val,4);
}

# -----------------------------------------------------------------------------

sub test_memoize : Test(1) {
    my $self = shift;

    my $row = Quiq::Database::Row::Object->new(a=>1,b=>2,c=>3);

    $row->memoize(d=>sub {
        4;
    });
    my $val = $row->d;
    $self->is($val,4);
}

# -----------------------------------------------------------------------------

sub test_getSet : Test(6) {
    my $self = shift;

    my $row = Quiq::Database::Row::Object->new(a=>1);

    my $val = $row->getSet('a');
    $self->is($val,1);

    $val = $row->getSet(a=>undef);
    $self->is($val,'');

    $val = $row->getSet(a=>'');
    $self->is($val,'');

    $val = $row->getSet(a=>0);
    $self->is($val,0);

    $val = $row->getSet(a=>2);
    $self->is($val,2);

    eval { $row->getSet(b=>4) };
    $self->like($@,qr/ROW-00004/);
}

# -----------------------------------------------------------------------------

sub test_rowStatus : Test(5) {
    my $self = shift;

    my $row = Quiq::Database::Row::Object->new(id=>4711);
    $self->is($row->rowStatus,'I');

    $row->set(id=>4712);
    $self->is($row->rowStatus,'I');

    $row->rowStatus(0);
    $row->set(id=>4713);
    $self->is($row->rowStatus,'U');

    $row->rowStatus('D');
    $row->set(id=>4714);
    $self->is($row->rowStatus,'D');

    eval { $row->rowStatus('X') };
    $self->like($@,qr/ROW-00005/);
}

# -----------------------------------------------------------------------------

sub test_copy : Test(9) {
    my $self = shift;

    my $row = Quiq::Database::Row::Object->new([qw/a b c/]);
    $row->set(a=>1); # Änderungs-Hash erzeugen

    my $newRow = $row->copy;
    $self->is(ref($newRow),ref($row));

    $self->isnt($newRow->[0],$row->[0]);
    $self->isDeeply($newRow->[0],$row->[0]);

    $self->is($newRow->[1],$row->[1]);

    $self->is($newRow->[2],$row->[2]);

    $self->isnt($newRow->[3],$row->[3]);
    $self->isDeeply($newRow->[3],$row->[3]);

    $self->is($newRow->[4],$row->[4]);
    $self->is($newRow->[5],$row->[5]);
}

# -----------------------------------------------------------------------------

sub test_copyData : Test(1) {
    my $self = shift;

    my $row0 = Quiq::Database::Row::Object->new(a=>1,b=>2,c=>3,d=>4);
    my $row1 = Quiq::Database::Row::Object->new(a=>5,b=>6,c=>7,e=>8);

    $row0->copyData($row1);
    my $arr0 = $row0->asArray;
    $self->isDeeply($arr0,[5,6,7,4]);
}

sub test_copyData_ignore : Test(1) {
    my $self = shift;

    my $row0 = Quiq::Database::Row::Object->new(a=>1,b=>2,c=>3,d=>4);
    my $row1 = Quiq::Database::Row::Object->new(a=>5,b=>6,c=>7,e=>8);

    $row0->copyData($row1,-ignore=>['a','c']);
    my $arr0 = $row0->asArray;
    $self->isDeeply($arr0,[1,6,3,4]);
}

sub test_copyData_dontCopyNull : Test(1) {
    my $self = shift;

    my $row0 = Quiq::Database::Row::Object->new(a=>1,b=>2,c=>3,d=>4);
    my $row1 = Quiq::Database::Row::Object->new(a=>5,b=>undef,c=>'',e=>8);

    $row0->copyData($row1,-dontCopyNull=>1);
    my $arr0 = $row0->asArray;
    $self->isDeeply($arr0,[5,2,3,4]);
}

# -----------------------------------------------------------------------------

sub test_AUTOLOAD : Test(5) {
    my $self = shift;

    my $rowClass = 'MyRowClass';

    Quiq::Perl->createClass($rowClass,'Quiq::Database::Row::Object');

    my $row = $rowClass->new(a=>1,b=>2);
    $self->is(ref($row),$rowClass);

    # FIXME: Prüfen, dass die Codereferenz für dieselbe Methode
    # sich nicht ändert, AUTOLOAD also nur einmal aufgerufen wird.

    my $val = $row->a;
    $self->is($val,1);

    $val = $row->b;
    $self->is($val,2);

    eval {$rowClass->z};
    $self->like($@,qr/ROW-00001/);

    eval {$row->z};
    $self->like($@,qr/ROW-00002/);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Database::Row::Object::Test->runTests;

# eof
