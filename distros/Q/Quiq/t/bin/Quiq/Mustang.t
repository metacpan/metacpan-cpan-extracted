#!/usr/bin/env perl

package Quiq::Mustang::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Path;
use Quiq::Test::Class;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Mustang');
}

# -----------------------------------------------------------------------------

sub test_unitTest: Test(3) {
    my $self = shift;

    my $p = Quiq::Path->new;

    my $jarFile = '~/sys/opt/mustang/Mustang-CLI-2.16.2.jar';
    if (!$p->exists($jarFile)) {
        $self->skipAll('JAR-Datei nicht vorhanden');
        return;
    }

    my $mus = Quiq::Mustang->new($jarFile);
    $self->is(ref($mus),'Quiq::Mustang');

    my $xmlFile = Quiq::Test::Class->testPath(
        'quiq/test/data/mustang/174341665800.xml');

    my $status = $mus->validate($xmlFile);
    $self->is($status,0);

    (my $pdfFile = $xmlFile) =~ s/xml$/pdf/;
    $mus->visualize($xmlFile,$pdfFile);
    $self->is(-e $pdfFile,1);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Mustang::Test->runTests;

# eof
