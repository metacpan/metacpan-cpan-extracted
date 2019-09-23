#!/usr/bin/env perl

package Quiq::Database::ResultSet::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

use Quiq::Database::ResultSet::Array;
use Quiq::Test::Class;
use Quiq::FileHandle;
use Quiq::Perl;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Database::ResultSet');
}

# -----------------------------------------------------------------------------

my $File = Quiq::Test::Class->testPath('t/data/db/person.tab');
my @Titles;
my $NumOfRows;

sub test_unitTest : Foreach {
    my $self = shift;

    # Datei für Vergleiche einlesen

    my $fh = Quiq::FileHandle->new('<',$File);
    while (<$fh>) {
        if (!@Titles) {
            chomp;
            @Titles = split /\|/;
            next;
        }
        $NumOfRows++;
    }
    $fh->close;

    # Klassen erzeugen

    use Quiq::Database::Row::Object;
    Quiq::Perl->createClass('PersonObject',
        'Quiq::Database::Row::Object');
    use Quiq::Database::Row::Array;
    Quiq::Perl->createClass('PersonArray',
        'Quiq::Database::Row::Array');

    my @rowClasses = qw/PersonObject PersonArray/;
    return @rowClasses;
}

# -----------------------------------------------------------------------------

sub test_new : Startup(1) {
    my ($self,$rowClass) = @_;

    my $tab = Quiq::Database::ResultSet->loadFromFile($File,-rowClass=>$rowClass);
    my $tableClass = $rowClass->tableClass;
    $self->is(ref($tab),$tableClass);

    $self->set(tab=>$tab);
}

# -----------------------------------------------------------------------------

sub test_rowClass : Test(1) {
    my ($self,$rowClass) = @_;

    my $tab = $self->get('tab');

    my $class = $tab->rowClass;
    $self->is($class,$rowClass);
}

# -----------------------------------------------------------------------------

sub test_rows : Test(2) {
    my ($self) = @_;

    my $tab = $self->get('tab');

    my $arr = $tab->rows;
    $self->is(scalar(@$arr),$NumOfRows);

    my @arr = $tab->rows;
    $self->is(scalar(@arr),$NumOfRows);
}

# -----------------------------------------------------------------------------

sub test_titles : Test(2) {
    my ($self) = @_;

    my $tab = $self->get('tab');

    my $arr = $tab->titles;
    $self->isDeeply($arr,\@Titles);

    my @arr = $tab->titles;
    $self->isDeeply(\@arr,\@Titles);
}

# -----------------------------------------------------------------------------

sub test_isRaw : Test(1) {
    my ($self,$rowClass) = @_;

    my $tab = $self->get('tab');

    my $bool = $rowClass =~ /Array/? 1: 0;

    my $val = $tab->isRaw;
    $self->is($val,$bool);
}

# -----------------------------------------------------------------------------

sub test_lookup : Test(2) {
    my ($self,$rowClass) = @_;

    my $tab = $self->get('tab');
    my $isRaw = $tab->isRaw;

    my $row = $tab->lookup(per_id=>2);
    $self->is($isRaw? $row->[2]: $row->per_nachname,'Pirelli');

    eval { $tab->lookup(per_nachname=>'x') };
    $self->like($@,qr/TAB-00001/);
}

# -----------------------------------------------------------------------------

sub test_saveToFile : Test(1) {
    my ($self,$rowClass) = @_;

    my $tab = $self->get('tab');

    my $file = '/tmp/person.dat';
    $tab->saveToFile($file);

    my $origData = Quiq::Path->read($File);
    my $bool = Quiq::Path->compareData($file,$origData);
    $self->is($bool,0);
}

# -----------------------------------------------------------------------------

sub test_count : Test(1) {
    my ($self,$rowClass) = @_;

    my $tab = $self->get('tab');

    my $n = $tab->count;
    $self->is($n,$NumOfRows);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Database::ResultSet::Test->runTests;

# eof
