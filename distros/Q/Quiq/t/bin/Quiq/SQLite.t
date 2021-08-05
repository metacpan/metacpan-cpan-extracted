#!/usr/bin/env perl

package Quiq::SQLite::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

use Quiq::Path;
use Quiq::SQLite;
use Quiq::Database::Connection;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::SQLite');
}

# -----------------------------------------------------------------------------

sub test_unitTest_root: Test(3) {
    my $self = shift;

    my $p = Quiq::Path->new;

    my $dbFile = '/tmp/test-sqlite.db';
    $p->delete($dbFile);

    my $exportDir = '/tmp/test-sqlite';
    $p->delete($exportDir);

    # Erzeuge initiale Datenbank

    Quiq::SQLite->recreateDatabase($dbFile,$exportDir,sub {
        my $dbFile = shift;
        
        my $db = Quiq::Database::Connection->new("dbi#sqlite:$dbFile");

        my $cur = $db->createTable('person',
            ['per_id',type=>'INTEGER',primaryKey=>1,autoIncrement=>1],
            ['per_vorname',type=>'STRING(100)',notNull=>1],
            ['per_nachname',type=>'STRING(100)',notNull=>1],
        );

        $db->disconnect;
    });

    # Füge Daten hinzu

    my $db = Quiq::Database::Connection->new("dbi#sqlite:$dbFile");
    $db->insert('person',per_vorname=>'Linus',per_nachname=>'Seitz');
    $db->disconnect(1);

    # Erzeuge die Datenbank mit geändertem Schema neu

    Quiq::SQLite->recreateDatabase($dbFile,$exportDir,sub {
        my $dbFile = shift;
        
        my $db = Quiq::Database::Connection->new("dbi#sqlite:$dbFile");

        my $cur = $db->createTable('person',
            ['per_id',type=>'INTEGER',primaryKey=>1,autoIncrement=>1],
            ['per_vorname',type=>'STRING(100)',notNull=>1],
            ['per_nachname',type=>'STRING(100)',notNull=>1],
            ['per_geburtstag',type=>'DATETIME'],
        );

        $db->disconnect;
    });

    # Prüfe, dass das Schema geändert wurde und die Daten
    # erhalten geblieben sind

    $db = Quiq::Database::Connection->new("dbi#sqlite:$dbFile");
    my $per = $db->lookup('person',per_vorname=>'Linus');
    $self->is($per->per_id,1);
    $self->is($per->per_nachname,'Seitz');
    $self->is($per->per_geburtstag,'');
    $db->disconnect;

    # Lösche Testdatenbank
    $p->delete($dbFile);

    return;
}

# -----------------------------------------------------------------------------

package main;
Quiq::SQLite::Test->runTests;

# eof
