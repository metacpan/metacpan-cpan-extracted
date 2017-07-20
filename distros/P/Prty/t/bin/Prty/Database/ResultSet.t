#!/usr/bin/env perl

package Prty::Database::ResultSet::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use utf8;

use Prty::Database::ResultSet::Array;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Database::ResultSet');
}

# -----------------------------------------------------------------------------

my $File = Prty::Test::Class->testPath('prty/test/data/db/person.tab');
my @Titles;
my $NumOfRows;

sub test_unitTest : Foreach {
    my $self = shift;

    # Datei für Vergleiche einlesen

    my $fh = Prty::FileHandle->new('<',$File);
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

    use Prty::Database::Row::Object;
    Prty::Perl->createClass('PersonObject',
        'Prty::Database::Row::Object');
    use Prty::Database::Row::Array;
    Prty::Perl->createClass('PersonArray',
        'Prty::Database::Row::Array');

    my @rowClasses = qw/PersonObject PersonArray/;
    return @rowClasses;
}

# -----------------------------------------------------------------------------

sub test_new : Startup(1) {
    my ($self,$rowClass) = @_;

    my $tab = Prty::Database::ResultSet->loadFromFile($File,-rowClass=>$rowClass);
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

    my $origData = Prty::Path->read($File);
    my $bool = Prty::Path->compareData($file,$origData);
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
Prty::Database::ResultSet::Test->runTests;

# eof
