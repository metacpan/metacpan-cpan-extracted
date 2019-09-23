#!/usr/bin/env perl

package Quiq::FileHandle::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::FileHandle');
}

# -----------------------------------------------------------------------------

sub test_unitTest: Test(1) {
    my $self = shift;

    my $testFile = '/tmp/test_unitTest.tst';
    my $testData = "Dies\nist\nein\nTest\n";

    # Datei schreiben

    my $fh = Quiq::FileHandle->new('>',$testFile);
    for (split /\n/,$testData) {
        $fh->print("$_\n");
    }
    $fh->close;

    # Datei lesen

    my $data;
    $fh = Quiq::FileHandle->new('<',$testFile);
    while (my $line = $fh->readLine) {
        $data .= $line;
    }
    $fh->close;

    $self->is($data,$testData,'Testdaten');

    # aufräumen
    Quiq::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_new : Test(3) {
    my $self = shift;

    my $testFile = '/tmp/new.tst';

    my $fh = Quiq::FileHandle->new('>',$testFile);
    $self->is(ref($fh),'Quiq::FileHandle','new: Test auf Klasse');

    my $str1 = 'abc';
    $fh = Quiq::FileHandle->new('<',\$str1);
    my $str2 = <$fh>;
    $self->is($str1,$str2,'new: in-memory File');

    $str1 = 'abc';
    bless \$str1,'TestFH';
    $fh = Quiq::FileHandle->new('<',\$str1);
    $str2 = <$fh>;
    $self->is($str1,$str2,'new: in-memory File über geblesste Referenz');

    Quiq::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_destroy : Test(3) {
    my $self = shift;

    my $testFile = '/tmp/destroy.tst';

    my $fh = Quiq::FileHandle->new('>',$testFile);
    $self->is(ref($fh),'Quiq::FileHandle','destroy: Test auf Klasse');

    $fh->destroy;
    $self->is($fh,undef,'destroy: Datei geschlossen');

    $fh = Quiq::FileHandle->new('>',$testFile);
    CORE::close $fh;

    eval { $fh->close };
    $self->like($@,qr/FH-00009/,
        'destroy: Schließen einer geschlossenen Handle');

    Quiq::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_getc : Test(1) {
    my $self = shift;

    my $testFile = '/tmp/getc.tst';
    my $testData = "Dies\nist\nein\nTest\n";

    Quiq::Path->write($testFile,$testData);

    my $fh = Quiq::FileHandle->new('<',$testFile);
    my $c = $fh->getc;
    $self->is($c,'D','getc: erstes Zeichen');

    Quiq::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_print : Test(2) {
    my $self = shift;

    my $testFile = '/tmp/print.tst';
    my $testData = "Test $$\n";

    my $fh = Quiq::FileHandle->new('>',$testFile);

    $fh->print($testData);
    $self->ok(1,'print: Daten geschrieben');

    $fh->close;

    my $val = Quiq::Path->read($testFile);
    $self->is($val,$testData,'print: Dateiinhalt');    
    Quiq::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

use Quiq::TempFile;

sub test_writeData : Test(1) {
    my $self = shift;

    my $file = Quiq::TempFile->new;

    my $data1 = "abcdef\näöüÄÖÜß\nxyz";

    my $fh = Quiq::FileHandle->new('>',$file);
    $fh->writeData(Encode::encode('utf-8',$data1));
    $fh->close;

    $fh = Quiq::FileHandle->new('<',$file);
    my $data2 = Encode::decode('utf-8',$fh->readData);
    $fh->close;

    $self->is($data2,$data1);
}

# -----------------------------------------------------------------------------

sub test_seek : Test(1) {
    my $self = shift;

    # Datei erzeugen

    my $testFile = '/tmp/seek.tst';
    my $testData = "Zeile1\nZeile2\n";
    Quiq::Path->write($testFile,$testData);

    my $fh = Quiq::FileHandle->new('<',$testFile);
    $fh->seek(7);
    my $line = $fh->readLine;
    $self->is($line,"Zeile2\n",'seek');

    # Datei löschen
    Quiq::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_tell : Test(1) {
    my $self = shift;

    # Datei erzeugen

    my $testFile = '/tmp/tell.tst';
    my $testData = "Zeile1\nZeile2\n";
    Quiq::Path->write($testFile,$testData);

    my $fh = Quiq::FileHandle->new('<',$testFile);
    my $line = $fh->readLine;
    my $pos = $fh->tell;
    $fh->close;
    $self->is($pos,7,'tell');

    # Datei löschen
    Quiq::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_lock : Test(5) {
    my $self = shift;

    my $testFile = '/tmp/lock.tst';

    my $fh = Quiq::FileHandle->new('>',$testFile);

    $fh->lock('SH');
    $self->ok(1,'lock: shared lock');

    $fh->lock('SHNB');
    $self->ok(1,'lock: shared lock, non-blocking');

    if ($^O eq 'MSWin32') {
        $self->skipTest(1,'On Windows exclusive locking hangs when used on'.
            ' file with shared lock');
    } else {
        $fh->lock('EX');
        $self->ok(1,'lock: exclusive lock');
    }

    $fh->lock('EXNB');
    $self->ok(1,'lock: exclusive lock, non-blocking');

    eval { $fh->lock('BLA') };
    $self->like($@,qr/FH-00002/,'lock: unbekannter Lockmodus');

    Quiq::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_unlock : Test(2) {
    my $self = shift;

    my $testFile = '/tmp/unlock.tst';

    my $fh = Quiq::FileHandle->new('>',$testFile);

    $fh->lock('EX');
    $self->ok(1,'unlock: Lock setzen');

    $fh->unlock;
    $self->ok(1,'unlock: Lock aufheben');

    Quiq::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_binmode : Test(1) {
    my $self = shift;

    # Datei erzeugen

    my $testFile = '/tmp/binmode.tst';
    my $testData = "Zeile1\nZeile2\n";
    Quiq::Path->write($testFile,$testData);

    my $fh = Quiq::FileHandle->new('<',$testFile);
    $fh->binmode;
    $fh->close;
    $self->ok(1,'binmode');

    # Datei löschen
    Quiq::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

package main;
Quiq::FileHandle::Test->runTests;

# eof
