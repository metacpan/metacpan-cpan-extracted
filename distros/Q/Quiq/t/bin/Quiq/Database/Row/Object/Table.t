#!/usr/bin/env perl

package Quiq::Database::Row::Object::Table::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

use Quiq::Database::Connection;
use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Database::Row::Object::Table');
}

# -----------------------------------------------------------------------------

sub udls : Foreach {
    my $self = shift;

    my $file = $self->testPath('t/data/db/test-databases.conf');
    my @arr = split /\n/,Quiq::Path->read($file);
    @arr = grep { !/^#/ } @arr; # Kommentarzeichen überlesen

    return @arr;
}

sub test_unitTest_startup : Startup(0) {
    my ($self,$udl) = @_;

    # diag "###$udl###";

    # Datenbankverbindung aufbauen

    my $db = Quiq::Database::Connection->new($udl,-utf8=>1);
    $self->set(db=>$db);
}

sub test_unitTest_shutdown : Shutdown(0) {
    shift->get('db')->disconnect;
}

# -----------------------------------------------------------------------------

sub test_tableName_single : Test(1) {
    my $self = shift;

    Quiq::Perl->createClass('Person9372','Quiq::Database::Row::Object::Table');

    my $row = Person9372->new(a=>1);
    my $table = $row->tableName;
    $self->is($table,'person9372');
}

sub test_tableName_multi : Test(1) {
    my $self = shift;

    Quiq::Perl->createClass('Test23::Person9373','Quiq::Database::Row::Object::Table');

    my $row = Test23::Person9373->new(a=>1);
    my $table = $row->tableName;
    $self->is($table,'person9373');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Database::Row::Object::Table::Test->runTests;

# eof
