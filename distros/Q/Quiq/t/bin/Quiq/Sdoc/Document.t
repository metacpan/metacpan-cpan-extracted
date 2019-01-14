#!/usr/bin/env perl

package Quiq::Sdoc::Document::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sdoc::Document');
}

# -----------------------------------------------------------------------------

# Allgemeine Tests

sub test_unitTest : Test(1) {
    my $self = shift;

    my $file = $self->testPath('t/data/sdoc/test.sdoc');
    my $tree = Quiq::Sdoc::Document->new($file,-utf8=>1);
    $self->is(ref($tree),'Quiq::Sdoc::Document','Klasse');
    # warn "---DEBUG\n";
    # warn $tree->dump('debug');
    # warn "---POD\n";
    # warn $tree->dump('pod');
    # warn "---EHTML\n";
    # warn $tree->dump('ehtml');
    # warn "---HTML\n";
    # warn $tree->dump('html');
}

# Anker-Test

sub test_unitTest_anchor : Test(9) {
    my $self = shift;

    my $file = $self->testPath('t/data/sdoc/test_anchor.sdoc');
    my $tree = Quiq::Sdoc::Document->new($file);
    my $str = $tree->dump('html');

    $self->like($str,qr/id="methoden"/,'anchor: h1 Titel-Anker');
    $self->like($str,qr/id="new_konstruktor"/,'anchor: new - Titel-Anker');
    $self->like($str,qr/id="new"/,'anchor: new - Schlüssel-Anker');
    $self->like($str,qr/id="new_konstruktor_options"/,
        'anchor: new/options - Titelpfad-Anker');
    $self->like($str,qr/id="new_options"/,'anchor: new/options - Pfad-Anker');
    $self->like($str,qr/id="get_getter"/,'anchor: get - Titel-Anker');
    $self->like($str,qr/id="get"/,'anchor: get - Schlüssel-Anker');
    $self->like($str,qr/id="get_getter_options"/,
        'anchor: get/options - Titelpfad-Anker');
    $self->like($str,qr/id="get_options"/,'anchor: Pfad-Anker');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sdoc::Document::Test->runTests;

# eof
