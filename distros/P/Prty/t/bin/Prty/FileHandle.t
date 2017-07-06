#!/usr/bin/env perl

package Prty::FileHandle::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::FileHandle');
}

# -----------------------------------------------------------------------------

sub test_unitTest: Test(1) {
    my $self = shift;

    my $testFile = '/tmp/test_unitTest.tst';
    my $testData = "Dies\nist\nein\nTest\n";

    # Datei schreiben

    my $fh = Prty::FileHandle->new('>',$testFile);
    for (split /\n/,$testData) {
        $fh->print("$_\n");
    }
    $fh->close;

    # Datei lesen

    my $data;
    $fh = Prty::FileHandle->new('<',$testFile);
    while (my $line = $fh->readLine) {
        $data .= $line;
    }
    $fh->close;

    $self->is($data,$testData,'Testdaten');

    # aufräumen
    Prty::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_new : Test(3) {
    my $self = shift;

    my $testFile = '/tmp/new.tst';

    my $fh = Prty::FileHandle->new('>',$testFile);
    $self->is(ref($fh),'Prty::FileHandle','new: Test auf Klasse');

    my $str1 = 'abc';
    $fh = Prty::FileHandle->new('<',\$str1);
    my $str2 = <$fh>;
    $self->is($str1,$str2,'new: in-memory File');

    $str1 = 'abc';
    bless \$str1,'TestFH';
    $fh = Prty::FileHandle->new('<',\$str1);
    $str2 = <$fh>;
    $self->is($str1,$str2,'new: in-memory File über geblesste Referenz');

    Prty::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_destroy : Test(3) {
    my $self = shift;

    my $testFile = '/tmp/destroy.tst';

    my $fh = Prty::FileHandle->new('>',$testFile);
    $self->is(ref($fh),'Prty::FileHandle','destroy: Test auf Klasse');

    $fh->destroy;
    $self->is($fh,undef,'destroy: Datei geschlossen');

    $fh = Prty::FileHandle->new('>',$testFile);
    CORE::close $fh;

    eval { $fh->close };
    $self->like($@,qr/FH-00009/,
        'destroy: Schließen einer geschlossenen Handle');

    Prty::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_getc : Test(1) {
    my $self = shift;

    my $testFile = '/tmp/getc.tst';
    my $testData = "Dies\nist\nein\nTest\n";

    Prty::Path->write($testFile,$testData);

    my $fh = Prty::FileHandle->new('<',$testFile);
    my $c = $fh->getc;
    $self->is($c,'D','getc: erstes Zeichen');

    Prty::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_print : Test(2) {
    my $self = shift;

    my $testFile = '/tmp/print.tst';
    my $testData = "Test $$\n";

    my $fh = Prty::FileHandle->new('>',$testFile);

    $fh->print($testData);
    $self->ok(1,'print: Daten geschrieben');

    $fh->close;

    my $val = Prty::Path->read($testFile);
    $self->is($val,$testData,'print: Dateiinhalt');    
    Prty::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_seek : Test(1) {
    my $self = shift;

    # Datei erzeugen

    my $testFile = '/tmp/seek.tst';
    my $testData = "Zeile1\nZeile2\n";
    Prty::Path->write($testFile,$testData);

    my $fh = Prty::FileHandle->new('<',$testFile);
    $fh->seek(7);
    my $line = $fh->readLine;
    $self->is($line,"Zeile2\n",'seek');

    # Datei löschen
    Prty::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_tell : Test(1) {
    my $self = shift;

    # Datei erzeugen

    my $testFile = '/tmp/tell.tst';
    my $testData = "Zeile1\nZeile2\n";
    Prty::Path->write($testFile,$testData);

    my $fh = Prty::FileHandle->new('<',$testFile);
    my $line = $fh->readLine;
    my $pos = $fh->tell;
    $fh->close;
    $self->is($pos,7,'tell');

    # Datei löschen
    Prty::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_lock : Test(5) {
    my $self = shift;

    my $testFile = '/tmp/lock.tst';

    my $fh = Prty::FileHandle->new('>',$testFile);

    $fh->lock('SH');
    $self->ok(1,'lock: shared lock');

    $fh->lock('SHNB');
    $self->ok(1,'lock: shared lock, non-blocking');

    $fh->lock('EX');
    $self->ok(1,'lock: exclusive lock');

    $fh->lock('EXNB');
    $self->ok(1,'lock: exclusive lock, non-blocking');

    eval { $fh->lock('BLA') };
    $self->like($@,qr/FH-00002/,'lock: unbekannter Lockmodus');

    Prty::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_unlock : Test(2) {
    my $self = shift;

    my $testFile = '/tmp/unlock.tst';

    my $fh = Prty::FileHandle->new('>',$testFile);

    $fh->lock('EX');
    $self->ok(1,'unlock: Lock setzen');

    $fh->unlock;
    $self->ok(1,'unlock: Lock aufheben');

    Prty::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_binmode : Test(1) {
    my $self = shift;

    # Datei erzeugen

    my $testFile = '/tmp/binmode.tst';
    my $testData = "Zeile1\nZeile2\n";
    Prty::Path->write($testFile,$testData);

    my $fh = Prty::FileHandle->new('<',$testFile);
    $fh->binmode;
    $fh->close;
    $self->ok(1,'binmode');

    # Datei löschen
    Prty::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

package main;
Prty::FileHandle::Test->runTests;

# eof
