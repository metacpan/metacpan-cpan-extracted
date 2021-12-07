#!/usr/bin/env perl

package Quiq::Dbms::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Dbms');
}

# -----------------------------------------------------------------------------

sub test_new : Test(8) {
    my $self = shift;

    my $sql = Quiq::Dbms->new('Oracle');
    $self->is($sql->{'dbms'},'Oracle');

    $sql = Quiq::Dbms->new('PostgreSQL');
    $self->is($sql->{'dbms'},'PostgreSQL');

    $sql = Quiq::Dbms->new('SQLite');
    $self->is($sql->{'dbms'},'SQLite');

    $sql = Quiq::Dbms->new('MySQL');
    $self->is($sql->{'dbms'},'MySQL');

    $sql = Quiq::Dbms->new('Access');
    $self->is($sql->{'dbms'},'Access');

    $sql = Quiq::Dbms->new('MSSQL');
    $self->is($sql->{'dbms'},'MSSQL');

    $sql = Quiq::Dbms->new('JDBC');
    $self->is($sql->{'dbms'},'JDBC');

    eval { Quiq::Dbms->new('Unknown') };
    $self->like($@,qr/Unknown DBMS/);
}

# -----------------------------------------------------------------------------

sub test_dbmsNames : Test(2) {
    my $self = shift;

    my $dbmsNames = [qw/Oracle PostgreSQL SQLite MySQL Access MSSQL JDBC/];

    my @arr = Quiq::Dbms->dbmsNames;
    $self->isDeeply(\@arr,$dbmsNames);

    my $arr = Quiq::Dbms->dbmsNames;
    $self->isDeeply($arr,$dbmsNames);
}

# -----------------------------------------------------------------------------

sub test_dbmsTestVector : Test(7) {
    my $self = shift;

    my @vec = Quiq::Dbms->new('Oracle')->dbmsTestVector;
    $self->isDeeply(\@vec,[1,0,0,0,0,0,0]);

    @vec = Quiq::Dbms->new('PostgreSQL')->dbmsTestVector;
    $self->isDeeply(\@vec,[0,1,0,0,0,0,0]);

    @vec = Quiq::Dbms->new('SQLite')->dbmsTestVector;
    $self->isDeeply(\@vec,[0,0,1,0,0,0,0]);

    @vec = Quiq::Dbms->new('MySQL')->dbmsTestVector;
    $self->isDeeply(\@vec,[0,0,0,1,0,0,0]);

    @vec = Quiq::Dbms->new('Access')->dbmsTestVector;
    $self->isDeeply(\@vec,[0,0,0,0,1,0,0]);

    @vec = Quiq::Dbms->new('MSSQL')->dbmsTestVector;
    $self->isDeeply(\@vec,[0,0,0,0,0,1,0]);

    @vec = Quiq::Dbms->new('JDBC')->dbmsTestVector;
    $self->isDeeply(\@vec,[0,0,0,0,0,0,1]);
}

# -----------------------------------------------------------------------------

sub test_isOracle : Test(2) {
    my $self = shift;

    my $bool = Quiq::Dbms->new('Oracle')->isOracle;
    $self->is($bool,1);

    $bool = Quiq::Dbms->new('PostgreSQL')->isOracle;
    $self->is($bool,0);
}

# -----------------------------------------------------------------------------

sub test_isPostgreSQL : Test(2) {
    my $self = shift;

    my $bool = Quiq::Dbms->new('PostgreSQL')->isPostgreSQL;
    $self->is($bool,1);

    $bool = Quiq::Dbms->new('Oracle')->isPostgreSQL;
    $self->is($bool,0);
}

# -----------------------------------------------------------------------------

sub test_isSQLite : Test(2) {
    my $self = shift;

    my $bool = Quiq::Dbms->new('SQLite')->isSQLite;
    $self->is($bool,1);

    $bool = Quiq::Dbms->new('PostgreSQL')->isSQLite;
    $self->is($bool,0);
}

# -----------------------------------------------------------------------------

sub test_isMySQL : Test(2) {
    my $self = shift;

    my $bool = Quiq::Dbms->new('MySQL')->isMySQL;
    $self->is($bool,1);

    $bool = Quiq::Dbms->new('PostgreSQL')->isMySQL;
    $self->is($bool,0);
}

# -----------------------------------------------------------------------------

sub test_isAccess : Test(2) {
    my $self = shift;

    my $bool = Quiq::Dbms->new('Access')->isAccess;
    $self->is($bool,1);

    $bool = Quiq::Dbms->new('PostgreSQL')->isAccess;
    $self->is($bool,0);
}

# -----------------------------------------------------------------------------

sub test_isMSSQL : Test(2) {
    my $self = shift;

    my $bool = Quiq::Dbms->new('MSSQL')->isMSSQL;
    $self->is($bool,1);

    $bool = Quiq::Dbms->new('PostgreSQL')->isMSSQL;
    $self->is($bool,0);
}

# -----------------------------------------------------------------------------

sub test_isJDBC : Test(2) {
    my $self = shift;

    my $bool = Quiq::Dbms->new('JDBC')->isJDBC;
    $self->is($bool,1);

    $bool = Quiq::Dbms->new('PostgreSQL')->isJDBC;
    $self->is($bool,0);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Dbms::Test->runTests;

# eof
