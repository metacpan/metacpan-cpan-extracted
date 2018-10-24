#!/usr/bin/env perl

package Prty::Template::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Prty::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Template');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(3) {
    my $self = shift;

    # Instantiiere Objekt

    my $file1 = $self->testPath('t/data/html/simple1.html');
    my $tpl = Prty::Template->new('html',$file1);
    $self->is(ref($tpl),'Prty::Template');

    # Ermittele Platzhalter

    my @arr = $tpl->placeholders;
    $self->isDeeply(\@arr,['__TITLE__','__BODY__']);

    # Ersetze Platzhalter

    $tpl->replace(
        __TITLE__=>'Testseite',
        __BODY__=>'Hello World!',
    );

    my $file2 = $self->testPath('t/data/html/simple2.html');
    my $data = Prty::Path->read($file2);
    chomp $data;
    $self->is($tpl->asString,$data);

    return;
}

# -----------------------------------------------------------------------------

my $test1 = <<'__EOT__';
Dies ist <!--optional-->ein Test<!--/optional-->.
__EOT__

sub test_removeOptional_1 : Test(1) {
    my $self = shift;

    my $tpl = Prty::Template->new('xml',\$test1);
    $tpl->removeOptional;
    my $str = $tpl->asString;
    $self->is($str,'Dies ist ein Test.');
}

# -----------------------------------------------------------------------------

my $test2 = <<'__EOT__';
Dies ist <!--optional-->ein <!--optional-->Test<!--/optional--><!--/optional-->.
__EOT__

sub test_removeOptional_2 : Test(1) {
    my $self = shift;

    my $tpl = Prty::Template->new('xml',\$test2);
    $tpl->removeOptional;
    my $str = $tpl->asString;
    $self->is($str,'Dies ist ein Test.');
}

# -----------------------------------------------------------------------------

package main;
Prty::Template::Test->runTests;

# eof
