#!/usr/bin/env perl

package Quiq::Unindent::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Unindent');
}

# -----------------------------------------------------------------------------

my $Result2 =  <<'__STR__';

  Dies ist
ein Test-
Text.

  Nächster
Absatz.

__STR__

sub test_hereDoc : Test(1) {
    my $self = shift;

    my $str = Quiq::Unindent->hereDoc(<<'    EOT');

      Dies ist
    ein Test-
    Text.

      Nächster
    Absatz.

    EOT
    $self->is($str,$Result2);
}

# -----------------------------------------------------------------------------

my $Result1 =  <<'__STR__';

  Dies ist
ein Test-
Text.

  Nächster
Absatz

__STR__

sub test_string : Test(1) {
    my $self = shift;

    my $str = Quiq::Unindent->string('

      Dies ist
    ein Test-
    Text.

      Nächster
    Absatz

    ');
    $self->is($str,$Result1);
}

# -----------------------------------------------------------------------------

my $Result3 =
'  Dies ist
ein Test-
Text.

  Nächster
Absatz';

sub test_trim : Test(2) {
    my $self = shift;

    # undef
    
    my $str = Quiq::Unindent->trim(undef);
    $self->is($str,'');

    # String mit Leerzeilen und Einrückung
    
    $str = Quiq::Unindent->trim('

      Dies ist
    ein Test-
    Text.

      Nächster
    Absatz

    ');
    $self->is($str,$Result3);
}

# -----------------------------------------------------------------------------

my $Result4 =
"  Dies ist
ein Test-
Text.

  Nächster
Absatz\n";

sub test_trimNl : Test(2) {
    my $self = shift;

    # undef
    
    my $str = Quiq::Unindent->trimNl(undef);
    $self->is($str,'');

    # String mit Leerzeilen und Einrückung
    
    $str = Quiq::Unindent->trimNl('

      Dies ist
    ein Test-
    Text.

      Nächster
    Absatz

    ');
    $self->is($str,$Result4);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Unindent::Test->runTests;

# eof
