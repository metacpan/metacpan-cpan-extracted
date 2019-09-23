#!/usr/bin/env perl

package Quiq::Path::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Path');
}

# -----------------------------------------------------------------------------

sub test_append : Test(2) {
    my $self = shift;

    my $file = "/tmp/test_append$$";

    Quiq::Path->append($file,"A\n");
    my $data = Quiq::Path->read($file);
    $self->is($data,"A\n");

    Quiq::Path->append($file,"B\n");
    $data = Quiq::Path->read($file);
    $self->is($data,"A\nB\n");

    Quiq::Path->delete($file);
}

# -----------------------------------------------------------------------------

sub test_checkFileSecurity : Test(4) {
    my $self = shift;

    my $p = Quiq::Path->new;

    my $file = $p->tempFile;

    $p->chmod($file,0600);

    eval {$p->checkFileSecurity($file)};
    $self->ok(!$@);

    $p->chmod($file,0640);

    eval {$p->checkFileSecurity($file)};
    $self->ok($@);

    eval {$p->checkFileSecurity($file,1)};
    $self->ok(!$@);

    $p->chmod($file,0642);

    eval {$p->checkFileSecurity($file,1)};
    $self->ok($@);
}

# -----------------------------------------------------------------------------

sub test_compareData : Test(2) {
    my $self = shift;

    my $file = '/tmp/compareData.txt';
    Quiq::Path->write($file,'a');

    my $bool = Quiq::Path->compareData($file,'a');
    $self->is($bool,0);

    $bool = Quiq::Path->compareData($file,'b');
    $self->is($bool,1);

    Quiq::Path->delete($file);
}

# -----------------------------------------------------------------------------

sub test_copy : Test(1) {
    my $self = shift;

    my $src = "/tmp/copy1.txt";
    my $srcData = "$$\n";
    my $dest = "/tmp/copy2.txt";

    Quiq::Path->write($src,$srcData);
    Quiq::Path->copy($src,$dest);
    my $destData = Quiq::Path->read($dest);
    $self->is($srcData,$destData);

    Quiq::Path->delete($src);
    Quiq::Path->delete($dest);
}

# -----------------------------------------------------------------------------

sub test_newlineStr : Test(3) {
    my $self = shift;

    my $testFile = '/tmp/newlineStr.tst';
    for my $nlStr ("\cJ","\cM\cJ","\cM") { # LF, CRLF, CR
        # Datei schreiben

        my $fh = Quiq::FileHandle->new('>',$testFile);
        $fh->binmode;
        for my $line (qw/Zeile1 Zeile2 Zeile3/) {
            $fh->print($line.$nlStr);
        }
        $fh->close;

        # Zeilentrenner bestimmen

        my $nlStr2 = Quiq::Path->newlineStr($testFile);
        $self->is($nlStr2,$nlStr);
    }
    Quiq::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_read : Test(4) {
    my $self = shift;

    my $file = "/tmp/test_read$$";

    Quiq::Path->write($file,"Hallo\n");
    my $data = Quiq::Path->read($file);
    $self->is($data,"Hallo\n");

    Quiq::Path->write($file,"1\n2\n3\n");
    $data = Quiq::Path->read($file,-skipLines=>2);
    $self->is($data,"3\n");

    Quiq::Path->write($file,"1\n#2\n3\n# 4\n5\n");
    $data = Quiq::Path->read($file,-skip=>qr/^#/);
    $self->is($data,"1\n3\n5\n");

    Quiq::Path->write($file,"1\n2\n3\n4\n5\n");
    $data = Quiq::Path->read($file,-maxLines=>3);
    $self->is($data,"1\n2\n3\n");

    # aufräumen
    Quiq::Path->delete($file);
}

# -----------------------------------------------------------------------------

sub test_tempFile: Test(4) {
    my $self = shift;

    my $path;
    {
        my $file = Quiq::Path->tempFile;
        $path = "$file";
        my $tempDir = $ENV{'TMPDIR'};
        if (!defined($tempDir) || !-d $tempDir) {
            $tempDir = '/tmp';
        }
        $self->ok(-f $file);
        $self->like($file,qr|^$tempDir/|);
        $self->like(sprintf('%s',$file),qr|^$tempDir/|);
    }
    $self->ok(!-d $path);
}

# -----------------------------------------------------------------------------

sub test_unindent : Test(3) {
    my $self = shift;

    my $p = Quiq::Path->new;

    my $original = << '    __EOT__';

          Dies ist der
        erste Absatz.

          Dies ist ein
        zweiter Absatz.

    __EOT__

    # Einrückung entfernen

    my $expected = Quiq::Unindent->hereDoc($original);
    my $file = $p->tempFile($original);
    $p->unindent($file);
    my $data = $p->read($file);
    $self->is($data,$expected,'Einrückung wurde entfernt');

    # Ein wiederholter Aufruf ändert nichts an der Datei (auch nicht mtime)

    $expected = $p->mtime($file);
    sleep 1;
    $self->isnt($expected,time,'Zeit ist vergangen');
    $p->unindent($file);
    my $mtime = $p->mtime($file);
    $self->is($mtime,$expected,'Datei wurde nicht geändert');
}

# -----------------------------------------------------------------------------

sub test_write : Test(3) {
    my $self = shift;

    my $file = "/tmp/test_write$$";

    Quiq::Path->write($file);
    $self->is(Quiq::Path->isEmpty($file),1);

    Quiq::Path->write($file,'x');
    $self->is(Quiq::Path->read($file),'x');

    Quiq::Path->write($file,'y',-append=>1);
    $self->is(Quiq::Path->read($file),'xy');

    Quiq::Path->delete($file);
}

# -----------------------------------------------------------------------------

sub test_find : Test(5) {
    my $self = shift;

    # Test-Verzeichnisstruktur:
    #
    # /tmp/$$/a
    # /tmp/$$/a/b
    # /tmp/$$/a/b/c
    # /tmp/$$/a/b/c/d
    # /tmp/$$/a/b/c/d/y.txt (Datei)
    # /tmp/$$/a/b/e
    # /tmp/$$/a/b/e/f
    # /tmp/$$/a/x.txt (Datei)

    my $root = "/tmp/$$";
    Quiq::Path->mkdir("$root/a/b/c/d",-recursive=>1);
    Quiq::Path->mkdir("$root/a/b/e/f",-recursive=>1);
    my $f1 = "$root/a/b/c/d/y.txt";
    Quiq::Path->write($f1,'');
    my $f2 = "$root/a/x.txt";
    Quiq::Path->write($f2,'');

    my @paths = sort Quiq::Path->find("$root/a",-type=>'f');
    $self->isDeeply(\@paths,[$f1,$f2]);

    @paths = sort Quiq::Path->find("$root/a",-type=>'d');
    $self->is(scalar(@paths),6);

    @paths = sort Quiq::Path->find("$root/a");
    $self->is(scalar(@paths),8);

    @paths = Quiq::Path->find("$root/x",-sloppy=>1);
    $self->is(scalar(@paths),0);

    eval {Quiq::Path->find("$root/x")};
    $self->like($@,qr/PATH-00011/);

    Quiq::Path->delete($root);
}

# -----------------------------------------------------------------------------

sub test_findProgram : Test(1) {
    my $self = shift;

    my $path = Quiq::Path->findProgram('ls',1);
    $self->like($path,qr|/ls$|);
}

# -----------------------------------------------------------------------------

sub test_mkdir : Test(2) {
    my $self = shift;

    my $path = "/tmp/mkdir$$/a/b";
    eval {Quiq::Path->mkdir($path)};
    $self->like($@,qr/PATH-00004/);

    Quiq::Path->mkdir($path,-recursive=>1);
    $self->ok(-e $path);

    Quiq::Path->delete("/tmp/mkdir$$");
}

# -----------------------------------------------------------------------------

sub test_tempDir: Test(4) {
    my $self = shift;

    my $path;
    {
        my $dir = Quiq::Path->tempDir;
        $path = "$dir";
        my $tempDir = $ENV{'TMPDIR'};
        if (!defined($tempDir) || !-d $tempDir) {
            $tempDir = '/tmp';
        }
        $self->ok(-d $dir);
        $self->like($dir,qr|^$tempDir/|);
        $self->like(sprintf('%s',$dir),qr|^$tempDir/|);
    }
    $self->ok(!-d $path);
}

# -----------------------------------------------------------------------------

sub test_absolute : Test(4) {
    my $self = shift;

    my $cwd = Quiq::Process->cwd;

    my $path = Quiq::Path->absolute;
    $self->is($path,$cwd);

    $path = Quiq::Path->absolute('.');
    $self->is($path,$cwd);

    $path = Quiq::Path->absolute('/tmp');
    $self->is($path,'/tmp');

    $path = Quiq::Path->absolute('tmp');
    $self->is($path,"$cwd/tmp");
}

# -----------------------------------------------------------------------------

sub test_basename : Test(3) {
    my $self = shift;

    my $base = Quiq::Path->basename('datei');
    $self->is($base,'datei');

    $base = Quiq::Path->basename('datei.ext');
    $self->is($base,'datei');

    $base = Quiq::Path->basename('/ein/pfad/datei.ext');
    $self->is($base,'datei');
}

# -----------------------------------------------------------------------------

sub test_chmod : Test(3) {
    my $self = shift;

    my $file = "/tmp/chmod$$.txt";
    Quiq::Path->write($file);
    Quiq::Path->chmod($file,0666);
    $self->is(0666,Quiq::Path->mode($file));

    Quiq::Path->chmod($file,0644);
    $self->is(0644,Quiq::Path->mode($file));

    Quiq::Path->delete($file);

    eval {Quiq::Path->chmod($file,0444) };
    $self->like($@,qr/PATH-00003/);
}

# -----------------------------------------------------------------------------

sub test_delete : Test(5) {
    my $self = shift;

    eval {Quiq::Path->delete('/does/not/exist')};
    $self->ok(!$@);

    # Testverzeichnis erzeugen

    (my $dir) = (my $path) = "/tmp/test_delete$$";
    mkdir $path;
    for (qw/a b c/) {
        $path .= "/$_";
        mkdir $path;
    }
    my $file = "$path/f.txt";
    Quiq::Path->write($file,"bla\n");

    # Datei

    $self->ok(-e $file);

    Quiq::Path->delete($file);
    $self->ok(!-e $file);

    # Verzeichnis

    $self->ok(-e $dir);

    Quiq::Path->delete($dir);
    $self->ok(!-e $dir);
}

# -----------------------------------------------------------------------------

sub test_expandTilde : Test(2) {
    my $self = shift;

    my $path1 = '/test';
    my $path2 = Quiq::Path->expandTilde('/test');
    $self->is($path1,$path2);

    $path1 = '~/test';
    $path2 = Quiq::Path->expandTilde('~/test');
    $self->isnt($path1,$path2);
}

# -----------------------------------------------------------------------------

sub test_newExtension : Test(3) {
    my $self = shift;

    my $path = '/this/is/a/file.sql';
    $path = Quiq::Path->newExtension($path,'.log');
    $self->is($path,'/this/is/a/file.log');

    $path = '/this/is/a/file.sql';
    $path = Quiq::Path->newExtension($path,'log');
    $self->is($path,'/this/is/a/file.log');

    $path = '/this/is/a/file.ext.sql';
    $path = Quiq::Path->newExtension($path,'log');
    $self->is($path,'/this/is/a/file.ext.log');
}

# -----------------------------------------------------------------------------

sub test_filename : Test(2) {
    my $self = shift;

    my $file = Quiq::Path->filename('datei');
    $self->is($file,'datei');

    $file = Quiq::Path->filename('/ein/pfad/datei');
    $self->is($file,'datei');
}

# -----------------------------------------------------------------------------

sub test_glob : Test(5) {
    my $self = shift;

    # Testverzeichnis erzeugen

    my $dir = "/tmp/test_glob$$";
    Quiq::Path->mkdir($dir);
    for (qw/a1 b2 c3/) {
        Quiq::Path->write("$dir/$_");
    }

    # Listkontext

    my @paths = Quiq::Path->glob("$dir/*");
    $self->isDeeply(\@paths,["$dir/a1","$dir/b2","$dir/c3",]);

    # Skalarkontext

    my $path = Quiq::Path->glob("$dir/b*");
    $self->is($path,"$dir/b2");

    eval {Quiq::Path->glob("$dir/*")};
    $self->like($@,qr/PATH-00015/);

    eval {Quiq::Path->glob("$dir/bb*")};
    $self->like($@,qr/PATH-00014/);

    eval {Quiq::Path->glob("$dir/*")};
    $self->like($@,qr/PATH-00015/);

    Quiq::Path->delete($dir);
}

# -----------------------------------------------------------------------------

sub test_isEmpty_file : Test(3) {
    my $self = shift;

    my $file = "/tmp/test_isEmpty$$";
    Quiq::Path->write($file);
    my $bool = Quiq::Path->isEmpty($file);
    $self->is($bool,1);

    Quiq::Path->write($file,'x');
    $bool = Quiq::Path->isEmpty($file);
    $self->is($bool,0);

    # aufräumen

    Quiq::Path->delete($file);
    $self->ok(!-e $file);
}

sub test_isEmpty_dir : Test(3) {
    my $self = shift;

    my $dir = "/tmp/test_isEmpty$$";
    mkdir $dir;

    my $val = Quiq::Path->isEmpty($dir);
    $self->is($val,1);

    mkdir $dir;
    my $file = "$dir/f.txt";
    Quiq::Path->write($file,"bla\n");
    $val = Quiq::Path->isEmpty($dir);
    $self->is($val,0);

    # aufräumen

    Quiq::Path->delete($dir);
    $self->ok(!-d $dir);
}

# -----------------------------------------------------------------------------

sub test_mtime : Test(4) {
    my $self = shift;

    my $time = time;

    my $file = '/tmp/mtime.txt';
    Quiq::Path->delete($file);

    # Nicht-existenter Pfad

    my $mtime = Quiq::Path->mtime($file);
    $self->ok($mtime == 0);

    Quiq::Path->write($file,'');

    # Existenter Pfad

    $mtime = Quiq::Path->mtime($file);
    $self->ok($mtime > 0);
    $self->ok($mtime >= $time);

    # mtime setzen

    Quiq::Path->mtime($file,$time-3600);
    $mtime = Quiq::Path->mtime($file);
    $self->is($mtime,$time-3600);

    Quiq::Path->delete($file);
}

# -----------------------------------------------------------------------------

sub test_newer : Test(2) {
    my $self = shift;

    my $file1 = '/tmp/newer_1.txt';
    Quiq::Path->write($file1,'');

    my $file2 = '/tmp/newer_2.txt';
    Quiq::Path->write($file2,'');
    Quiq::Path->mtime($file2,time-10);

    my $bool = Quiq::Path->newer($file1,$file2);
    $self->is($bool,1);

    $bool = Quiq::Path->newer($file2,$file1);
    $self->is($bool,0);

    Quiq::Path->delete($file1);
    Quiq::Path->delete($file2);
}

# -----------------------------------------------------------------------------

sub test_removeExtension : Test(3) {
    my $self = shift;

    my $base = Quiq::Path->removeExtension('datei');
    $self->is($base,'datei');

    $base = Quiq::Path->removeExtension('datei.ext');
    $self->is($base,'datei');

    $base = Quiq::Path->removeExtension('/ein/pfad/datei.ext');
    $self->is($base,'/ein/pfad/datei');
}

# -----------------------------------------------------------------------------

sub test_rename : Test(1) {
    my $self = shift;

    my $newName = "/tmp/x$$.test";
    my $file = "/tmp/rename$$.test";
    Quiq::Path->write($file);
    Quiq::Path->rename($file,$newName);
    $self->ok(-e $newName);

    Quiq::Path->delete($newName);
}

sub test_rename_except : Test(1) {
    my $self = shift;

    my $file = "/tmp/nicht-existent$$";
    eval {Quiq::Path->rename($file,'x')};
    $self->like($@,qr/PATH-00010/);
}

# -----------------------------------------------------------------------------

sub test_split : Test(14) {
    my $self = shift;

    my ($dir,$file,$base,$ext) = Quiq::Path->split('datei');
    $self->is($dir,'');
    $self->is($file,'datei');
    $self->is($base,'datei');
    $self->is($ext,'');

    ($dir,$file,$base,$ext) = Quiq::Path->split('datei.ext');
    $self->is($dir,'');
    $self->is($file,'datei.ext');
    $self->is($base,'datei');
    $self->is($ext,'ext');

    ($dir,$file,$base,$ext) = Quiq::Path->split('/ein/pfad/datei.ext');
    $self->is($dir,'/ein/pfad');
    $self->is($file,'datei.ext');
    $self->is($base,'datei');
    $self->is($ext,'ext');

    ($dir,undef,$base,undef) = Quiq::Path->split('/ein/pfad/datei.ext');
    $self->is($dir,'/ein/pfad');
    $self->is($base,'datei');
}

# -----------------------------------------------------------------------------

sub test_symlink : Test(1) {
    my $self = shift;

    my $symlink = "/tmp/x$$.test";
    my $file = "/tmp/symlink$$.test";
    Quiq::Path->write($file);
    Quiq::Path->symlink($file,$symlink);
    $self->ok(-l $symlink);

    Quiq::Path->delete($symlink);
    Quiq::Path->delete($file);
}

# -----------------------------------------------------------------------------

sub test_symlinkRelative : Test(5) {
    my $self = shift;

    # FIXME: alle Quiq::Path-Methoden in Quiq::Path implementieren
    #     und diese nutzen.

    my @paths = (
        'a' => 'x',
        'a' => 'x/y',
        'a/b' => 'x',
        'a/b' => 'x/y',
        'a/b/c' => 'x/y',
    );
    while (@paths) {
        my $path = shift @paths;
        my $symlink = shift @paths;

        (my $pathTop = $path) =~ s|/.*||;
        (my $symlinkTop = $symlink) =~ s|/.*||;

        Quiq::Path->delete($pathTop);
        Quiq::Path->delete($symlinkTop);

        if ($path =~ m|/|) {
            # my $pathParent = Quiq::Path->parent($path);
            # Quiq::Path->mkdir($pathParent,-recursive=>1);
            my $dir = (Quiq::Path->split($path))[0];
            Quiq::Path->mkdir($dir,-recursive=>1);
        }
        if ($symlink =~ m|/|) {
            # my $pathSymlink = Quiq::Path->parent($symlink);
            # Quiq::Path->mkdir($pathSymlink,-recursive=>1);
            my $dir = (Quiq::Path->split($symlink))[0];
            Quiq::Path->mkdir($dir,-recursive=>1);
        }

        Quiq::Path->write($path,$$);
        Quiq::Path->symlinkRelative($path,$symlink);
        my $data = Quiq::Path->read($symlink);

        $self->is($data,$$);
    }

    Quiq::Path->delete('a');
    Quiq::Path->delete('x');
}

# -----------------------------------------------------------------------------

sub test_touch : Test(1) {
    my $self = shift;

    my $p = Quiq::Path->new;

    my $file = $p->tempFile;
    my $time1 = time-1;
    $p->mtime($file,$time1);

    $p->touch($file);
    my $time2 = $p->mtime($file);
    $self->cmpOk($time1,'<',$time2);
}

# -----------------------------------------------------------------------------

sub test_uid : Test(1) {
    my $self = shift;

    my $p = Quiq::Path->new;
    my $file = $p->tempFile;
    my $uid = $p->uid($file);
    $self->is($uid,$<);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Path::Test->runTests;

# eof
