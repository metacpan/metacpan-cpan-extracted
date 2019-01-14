#!/usr/bin/env perl

package Quiq::DestinationTree::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::DestinationTree');
}

# -----------------------------------------------------------------------------

sub unit_setup : Setup(2) Group(^unit_) {
    my $self = shift;

    my $fixDir = $self->testDir('fixture');
    Quiq::Path->mkdir("$fixDir/a",-recursive=>1);
    Quiq::Path->write("$fixDir/a/hello.c","main(){}\n");
    Quiq::Path->write("$fixDir/a/hello.o","xyz\n");
    $self->ok(-d $fixDir,'Fixture-Verzeichnis erzeugt');

    my $tree = Quiq::DestinationTree->new("$fixDir/a",
        -exclude=>qr/\.o$/,
        -quiet=>1,
    );
    $self->is(ref($tree),'Quiq::DestinationTree');

    $self->set(fixDir=>$fixDir,tree=>$tree);
}

sub unit_test1 : Test(5) {
    my $self = shift;

    my ($tree,$fixDir) = $self->get(qw/tree fixDir/);

    my $written = $tree->addFile("$fixDir/a/hello.c","main(){}\n");
    $self->is($written,0,'Datei hat gleichen Inhalt');

    $written = $tree->addFile("$fixDir/a/hello.c","main(){printf()}\n");
    $self->is($written,1,'Datei hat verschiedenen Inhalt');

    my $created = $tree->addDir("$fixDir/a");
    $self->is($created,0,'Verzeichnis nicht erzeugt');

    $created = $tree->addDir("$fixDir/b");
    $self->is($created,1,'Verzeichnis erzeugt');

    my $n = $tree->cleanup;
    $self->is($n,0,'Keine Pfade entfernt');
}

sub unit_test2 : Test(2) {
    my $self = shift;

    my ($tree,$fixDir) = $self->get(qw/tree fixDir/);

    my $written = $tree->addFile("$fixDir/a/b/c/test.txt","1\n");
    $self->is($written,2,'Datei erzeugt');

    my $n = $tree->cleanup;
    $self->is($n,1,'Überzählige Datei entfernt');
}

sub unit_teardown : Teardown(2) Group(^unit_) {
    my $self = shift;

    my $dir = $self->get('fixDir');
    Quiq::Path->delete($dir);
    $self->ok(!-e $dir,'Fixture-Verzeichnis gelöscht');

    $dir = $self->testDir;
    Quiq::Path->delete($dir);
    $self->ok(!-e $dir,'Test-Verzeichnis gelöscht');
}

# -----------------------------------------------------------------------------

package main;
Quiq::DestinationTree::Test->runTests;

# eof
