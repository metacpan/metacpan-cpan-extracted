#!/usr/bin/env perl

package Prty::Unindent::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Unindent');
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

    my $str = Prty::Unindent->hereDoc(<<'    EOT');

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

    my $str = Prty::Unindent->string('

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
    
    my $str = Prty::Unindent->trim(undef);
    $self->is($str,'');

    # String mit Leerzeilen und Einrückung
    
    $str = Prty::Unindent->trim('

      Dies ist
    ein Test-
    Text.

      Nächster
    Absatz

    ');
    $self->is($str,$Result3);
}

# -----------------------------------------------------------------------------

package main;
Prty::Unindent::Test->runTests;

# eof
