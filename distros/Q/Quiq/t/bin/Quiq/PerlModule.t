#!/usr/bin/env perl

package Quiq::PerlModule::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Test::More;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::PerlModule');
}

# -----------------------------------------------------------------------------

sub test_new : Startup(3) {
    my $self = shift;

    my $obj1 = Quiq::PerlModule->new('Quiq::PerlModule');
    is ref($obj1),'Quiq::PerlModule','new: Quiq::PerlModule';

    my $obj2 = Quiq::PerlModule->new('Test::More');
    is ref($obj2),'Quiq::PerlModule','new: Test::More';

    my $obj3 = Quiq::PerlModule->new('strict');
    is ref($obj3),'Quiq::PerlModule','new: strict';

    $self->set(obj1=>$obj1,obj2=>$obj2,obj3=>$obj3);
}

# -----------------------------------------------------------------------------

sub test_name : Test(3) {
    my $self = shift;

    my $obj1 = $self->get('obj1');
    my $val = $obj1->name;
    is $val,'Quiq::PerlModule','name: Quiq::PerlModule';

    my $obj2 = $self->get('obj2');
    $val = $obj2->name;
    is $val,'Test::More','name: Test::More';

    my $obj3 = $self->get('obj3');
    $val = $obj3->name;
    is $val,'strict','name: strict';
}

# -----------------------------------------------------------------------------

sub test_isCore : Test(3) {
    my $self = shift;

    my $obj1 = $self->get('obj1');
    my $val = $obj1->isCore;
    ok !$val,'isCore: Quiq::PerlModule';

    my $obj2 = $self->get('obj2');
    $val = $obj2->isCore;
    ok $val,'isCore: Test::More';

    my $obj3 = $self->get('obj3');
    $val = $obj3->isCore;
    ok $val,'isCore: strict';
}

# -----------------------------------------------------------------------------

sub test_isPragma : Test(3) {
    my $self = shift;

    my $obj1 = $self->get('obj1');
    my $val = $obj1->isPragma;
    ok !$val,'isPragma: Quiq::PerlModule';

    my $obj2 = $self->get('obj2');
    $val = $obj2->isPragma;
    ok !$val,'isPragma: Test::More';

    my $obj3 = $self->get('obj3');
    $val = $obj3->isPragma;
    ok $val,'isPragma: strict';
}

# -----------------------------------------------------------------------------

sub test_loadPath : Test(3) {
    my $self = shift;

    eval { Quiq::PerlModule->new('A::B::C')->loadPath };
    like $@,qr/PERLMODULE-00001/,'loadPath: Klasse nicht geladen';

    my $obj1 = $self->get('obj1');
    my $val = $obj1->loadPath;
    like $val,qr|Quiq/PerlModule\.pm$|,'loadPath: Quiq::PerlModule';

    my $obj3 = $self->get('obj3');
    $val = $obj3->loadPath;
    like $val,qr/strict.pm$/,'loadPath: strict';
}

# -----------------------------------------------------------------------------

sub test_nameToPath : Test(4) {
    my $self = shift;

    my $val = Quiq::PerlModule->nameToPath('A::B::C');
    is $val,'A/B/C.pm','nameToPath: A::B::C';

    my $obj1 = $self->get('obj1');
    $val = $obj1->nameToPath;
    is $val,'Quiq/PerlModule.pm','nameToPath: Quiq::PerlModule';

    my $obj2 = $self->get('obj2');
    $val = $obj2->nameToPath;
    is $val,'Test/More.pm','nameToPath: Test::More';

    my $obj3 = $self->get('obj3');
    $val = $obj3->nameToPath;
    is $val,'strict.pm','nameToPath: strict';
}

# -----------------------------------------------------------------------------

sub test_pathToName : Test(1) {
    my $self = shift;

    my $val = Quiq::PerlModule->pathToName('A/B/C.pm');
    is $val,'A::B::C','pathToName';
}

# -----------------------------------------------------------------------------

package main;
Quiq::PerlModule::Test->runTests;

# eof
