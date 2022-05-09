#!/usr/bin/env perl

package Quiq::Database::Patch::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Perl;
use Quiq::Database::Connection;
use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Database::Patch');
}

# -----------------------------------------------------------------------------

sub test_unitTest: Test(5) {
    my $self = shift;

    Quiq::Perl->createClass('Test::Patch','Quiq::Database::Patch');
    Quiq::Perl->setSubroutine('Test::Patch',patch1=>sub {
        my ($self,$db) = @_;
        $db->createTable('person',
            ['per_id',type=>'INTEGER',primaryKey=>1,autoIncrement=>1],
            ['per_vorname',type=>'STRING(20)',notNull=>1],
        );
        return;
    });
    Quiq::Perl->setSubroutine('Test::Patch',patch2=>sub {
        my ($self,$db) = @_;
        $db->insertMulti('person',['per_vorname'],[
            ['Linus'],
            ['Hanno'],
        ]);
        return;
    });

    my $maxLevel = Test::Patch->maxLevel;
    $self->is($maxLevel,2);

    my $testDb = "dbi#sqlite:/tmp/test$$.db";
    my $db = Quiq::Database::Connection->new($testDb,-log=>1);

    my $pat = Test::Patch->new($db);
    $self->is(ref($pat),'Test::Patch');

    my $currLevel = $pat->currentLevel;
    $self->is($currLevel,0);

    $pat->apply(2);

    my $tab = $db->select('person');
    $self->is($tab->count,2);

    $currLevel = $pat->currentLevel;
    $self->is($currLevel,2);

    Quiq::Path->delete($testDb);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Database::Patch::Test->runTests;

# eof
