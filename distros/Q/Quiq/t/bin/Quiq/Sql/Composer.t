#!/usr/bin/env perl

package Quiq::Sql::Composer::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sql::Composer');
}

# -----------------------------------------------------------------------------

sub test_case : Test(4) {
    my $self = shift;

    my $s = Quiq::Sql::Composer->new('PostgreSQL');
    $self->is(ref($s),'Quiq::Sql::Composer');

    my $sql = $s->case("strftime('%w', datum)",0=>'So',1=>'Mo',2=>'Di',
        3=>'Mi',4=>'Do',5=>'Fr',6=>'Sa');
    $self->isText("$sql\n",q~
        CASE strftime('%w', datum)
            WHEN '0' THEN 'So'
            WHEN '1' THEN 'Mo'
            WHEN '2' THEN 'Di'
            WHEN '3' THEN 'Mi'
            WHEN '4' THEN 'Do'
            WHEN '5' THEN 'Fr'
            WHEN '6' THEN 'Sa'
        END
    ~);

    $sql = $s->case('bearbeitet',1=>'Ja','Nein',-fmt=>'i');
    $self->is($sql,"CASE bearbeitet WHEN '1' THEN 'Ja' ELSE 'Nein' END");

    $sql = $s->case('bearbeitet',1=>'Ja',0=>'Nein',\'NULL',-fmt=>'i');
    $self->is($sql,"CASE bearbeitet WHEN '1' THEN 'Ja' WHEN '0'".
        " THEN 'Nein' ELSE NULL END");
}

# -----------------------------------------------------------------------------

sub test_stringLiteral : Test(4) {
    my $self = shift;

    my $s = Quiq::Sql::Composer->new('PostgreSQL');

    my $val = $s->stringLiteral("Sie hat's");
    $self->is($val,"'Sie hat''s'");

    $val = $s->stringLiteral('');
    $self->is($val,'');

    $val = $s->stringLiteral('',\'NULL');
    $self->is($val,'NULL');

    $val = $s->stringLiteral('','schwarz');
    $self->is($val,"'schwarz'");

    return;
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sql::Composer::Test->runTests;

# eof
