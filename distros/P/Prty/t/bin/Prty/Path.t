#!/usr/bin/env perl

package Prty::Path::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Path');
}

# -----------------------------------------------------------------------------

sub test_append : Test(2) {
    my $self = shift;

    my $file = "/tmp/test_append$$";

    Prty::Path->append($file,"A\n");
    my $data = Prty::Path->read($file);
    $self->is($data,"A\n");

    Prty::Path->append($file,"B\n");
    $data = Prty::Path->read($file);
    $self->is($data,"A\nB\n");

    Prty::Path->delete($file);
}

# -----------------------------------------------------------------------------

sub test_compareData : Test(2) {
    my $self = shift;

    my $file = '/tmp/compareData.txt';
    Prty::Path->write($file,'a');

    my $bool = Prty::Path->compareData($file,'a');
    $self->is($bool,0);

    $bool = Prty::Path->compareData($file,'b');
    $self->is($bool,1);

    Prty::Path->delete($file);
}

# -----------------------------------------------------------------------------

sub test_copy : Test(1) {
    my $self = shift;

    my $src = "/tmp/copy1.txt";
    my $srcData = "$$\n";
    my $dest = "/tmp/copy2.txt";

    Prty::Path->write($src,$srcData);
    Prty::Path->copy($src,$dest);
    my $destData = Prty::Path->read($dest);
    $self->is($srcData,$destData);

    Prty::Path->delete($src);
    Prty::Path->delete($dest);
}

# -----------------------------------------------------------------------------

sub test_newlineStr : Test(3) {
    my $self = shift;

    my $testFile = '/tmp/newlineStr.tst';
    for my $nlStr ("\cJ","\cM\cJ","\cM") { # LF, CRLF, CR
        # Datei schreiben

        my $fh = Prty::FileHandle->new('>',$testFile);
        $fh->binmode;
        for my $line (qw/Zeile1 Zeile2 Zeile3/) {
            $fh->print($line.$nlStr);
        }
        $fh->close;

        # Zeilentrenner bestimmen

        my $nlStr2 = Prty::Path->newlineStr($testFile);
        $self->is($nlStr2,$nlStr);
    }
    Prty::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_read : Test(4) {
    my $self = shift;

    my $file = "/tmp/test_read$$";

    Prty::Path->write($file,"Hallo\n");
    my $data = Prty::Path->read($file);
    $self->is($data,"Hallo\n");

    Prty::Path->write($file,"1\n2\n3\n");
    $data = Prty::Path->read($file,-skipLines=>2);
    $self->is($data,"3\n");

    Prty::Path->write($file,"1\n#2\n3\n# 4\n5\n");
    $data = Prty::Path->read($file,-skip=>qr/^#/);
    $self->is($data,"1\n3\n5\n");

    Prty::Path->write($file,"1\n2\n3\n4\n5\n");
    $data = Prty::Path->read($file,-maxLines=>3);
    $self->is($data,"1\n2\n3\n");

    # aufräumen
    Prty::Path->delete($file);
}

# -----------------------------------------------------------------------------

sub test_write : Test(3) {
    my $self = shift;

    my $file = "/tmp/test_write$$";

    Prty::Path->write($file);
    $self->is(Prty::Path->isEmpty($file),1);

    Prty::Path->write($file,'x');
    $self->is(Prty::Path->read($file),'x');

    Prty::Path->write($file,'y',-append=>1);
    $self->is(Prty::Path->read($file),'xy');

    Prty::Path->delete($file);
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
    Prty::Path->mkdir("$root/a/b/c/d",-recursive=>1);
    Prty::Path->mkdir("$root/a/b/e/f",-recursive=>1);
    my $f1 = "$root/a/b/c/d/y.txt";
    Prty::Path->write($f1,'');
    my $f2 = "$root/a/x.txt";
    Prty::Path->write($f2,'');

    my @paths = sort Prty::Path->find("$root/a",-type=>'f');
    $self->isDeeply(\@paths,[$f1,$f2]);

    @paths = sort Prty::Path->find("$root/a",-type=>'d');
    $self->is(scalar(@paths),6);

    @paths = sort Prty::Path->find("$root/a");
    $self->is(scalar(@paths),8);

    @paths = Prty::Path->find("$root/x",-sloppy=>1);
    $self->is(scalar(@paths),0);

    eval {Prty::Path->find("$root/x")};
    $self->like($@,qr/PATH-00011/);

    Prty::Path->delete($root);
}

# -----------------------------------------------------------------------------

sub test_mkdir : Test(2) {
    my $self = shift;

    my $path = "/tmp/mkdir$$/a/b";
    eval {Prty::Path->mkdir($path)};
    $self->like($@,qr/PATH-00004/);

    Prty::Path->mkdir($path,-recursive=>1);
    $self->ok(-e $path);

    Prty::Path->delete("/tmp/mkdir$$");
}

# -----------------------------------------------------------------------------

sub test_absolute : Test(4) {
    my $self = shift;

    my $cwd = Prty::Process->cwd;

    my $path = Prty::Path->absolute;
    $self->is($path,$cwd);

    $path = Prty::Path->absolute('.');
    $self->is($path,$cwd);

    $path = Prty::Path->absolute('/tmp');
    $self->is($path,'/tmp');

    $path = Prty::Path->absolute('tmp');
    $self->is($path,"$cwd/tmp");
}

# -----------------------------------------------------------------------------

sub test_basename : Test(3) {
    my $self = shift;

    my $base = Prty::Path->basename('datei');
    $self->is($base,'datei');

    $base = Prty::Path->basename('datei.ext');
    $self->is($base,'datei');

    $base = Prty::Path->basename('/ein/pfad/datei.ext');
    $self->is($base,'datei');
}

# -----------------------------------------------------------------------------

sub test_chmod : Test(3) {
    my $self = shift;

    my $file = "/tmp/chmod$$.txt";
    Prty::Path->write($file);
    Prty::Path->chmod($file,0666);
    $self->is(0666,Prty::Path->mode($file));

    Prty::Path->chmod($file,0644);
    $self->is(0644,Prty::Path->mode($file));

    Prty::Path->delete($file);

    eval {Prty::Path->chmod($file,0444) };
    $self->like($@,qr/PATH-00003/);
}

# -----------------------------------------------------------------------------

sub test_delete : Test(5) {
    my $self = shift;

    eval {Prty::Path->delete('/does/not/exist')};
    $self->ok(!$@);

    # Testverzeichnis erzeugen

    (my $dir) = (my $path) = "/tmp/test_delete$$";
    mkdir $path;
    for (qw/a b c/) {
        $path .= "/$_";
        mkdir $path;
    }
    my $file = "$path/f.txt";
    Prty::Path->write($file,"bla\n");

    # Datei

    $self->ok(-e $file);

    Prty::Path->delete($file);
    $self->ok(!-e $file);

    # Verzeichnis

    $self->ok(-e $dir);

    Prty::Path->delete($dir);
    $self->ok(!-e $dir);
}

# -----------------------------------------------------------------------------

sub test_expandTilde : Test(2) {
    my $self = shift;

    my $path1 = '/test';
    my $path2 = Prty::Path->expandTilde('/test');
    $self->is($path1,$path2);

    $path1 = '~/test';
    $path2 = Prty::Path->expandTilde('~/test');
    $self->isnt($path1,$path2);
}

# -----------------------------------------------------------------------------

sub test_filename : Test(2) {
    my $self = shift;

    my $file = Prty::Path->filename('datei');
    $self->is($file,'datei');

    $file = Prty::Path->filename('/ein/pfad/datei');
    $self->is($file,'datei');
}

# -----------------------------------------------------------------------------

sub test_glob : Test(5) {
    my $self = shift;

    # Testverzeichnis erzeugen

    my $dir = "/tmp/test_glob$$";
    Prty::Path->mkdir($dir);
    for (qw/a1 b2 c3/) {
        Prty::Path->write("$dir/$_");
    }

    # Listkontext

    my @paths = Prty::Path->glob("$dir/*");
    $self->isDeeply(\@paths,["$dir/a1","$dir/b2","$dir/c3",]);

    # Skalarkontext

    my $path = Prty::Path->glob("$dir/b*");
    $self->is($path,"$dir/b2");

    eval {Prty::Path->glob("$dir/*")};
    $self->like($@,qr/PATH-00015/);

    eval {Prty::Path->glob("$dir/bb*")};
    $self->like($@,qr/PATH-00014/);

    eval {Prty::Path->glob("$dir/*")};
    $self->like($@,qr/PATH-00015/);

    Prty::Path->delete($dir);
}

# -----------------------------------------------------------------------------

sub test_isEmpty_file : Test(3) {
    my $self = shift;

    my $file = "/tmp/test_isEmpty$$";
    Prty::Path->write($file);
    my $bool = Prty::Path->isEmpty($file);
    $self->is($bool,1);

    Prty::Path->write($file,'x');
    $bool = Prty::Path->isEmpty($file);
    $self->is($bool,0);

    # aufräumen

    Prty::Path->delete($file);
    $self->ok(!-e $file);
}

sub test_isEmpty_dir : Test(3) {
    my $self = shift;

    my $dir = "/tmp/test_isEmpty$$";
    mkdir $dir;

    my $val = Prty::Path->isEmpty($dir);
    $self->is($val,1);

    mkdir $dir;
    my $file = "$dir/f.txt";
    Prty::Path->write($file,"bla\n");
    $val = Prty::Path->isEmpty($dir);
    $self->is($val,0);

    # aufräumen

    Prty::Path->delete($dir);
    $self->ok(!-d $dir);
}

# -----------------------------------------------------------------------------

sub test_mtime : Test(4) {
    my $self = shift;

    my $time = time;

    my $file = '/tmp/mtime.txt';
    Prty::Path->delete($file);

    # Nicht-existenter Pfad

    my $mtime = Prty::Path->mtime($file);
    $self->ok($mtime == 0);

    Prty::Path->write($file,'');

    # Existenter Pfad

    $mtime = Prty::Path->mtime($file);
    $self->ok($mtime > 0);
    $self->ok($mtime >= $time);

    # mtime setzen

    Prty::Path->mtime($file,$time-3600);
    $mtime = Prty::Path->mtime($file);
    $self->is($mtime,$time-3600);

    Prty::Path->delete($file);
}

# -----------------------------------------------------------------------------

sub test_newer : Test(2) {
    my $self = shift;

    my $file1 = '/tmp/newer_1.txt';
    Prty::Path->write($file1,'');

    my $file2 = '/tmp/newer_2.txt';
    Prty::Path->write($file2,'');
    Prty::Path->mtime($file2,time-10);

    my $bool = Prty::Path->newer($file1,$file2);
    $self->is($bool,1);

    $bool = Prty::Path->newer($file2,$file1);
    $self->is($bool,0);

    Prty::Path->delete($file1);
    Prty::Path->delete($file2);
}

# -----------------------------------------------------------------------------

sub test_removeExtension : Test(3) {
    my $self = shift;

    my $base = Prty::Path->removeExtension('datei');
    $self->is($base,'datei');

    $base = Prty::Path->removeExtension('datei.ext');
    $self->is($base,'datei');

    $base = Prty::Path->removeExtension('/ein/pfad/datei.ext');
    $self->is($base,'/ein/pfad/datei');
}

# -----------------------------------------------------------------------------

sub test_rename : Test(1) {
    my $self = shift;

    my $newName = "/tmp/x$$.test";
    my $file = "/tmp/rename$$.test";
    Prty::Path->write($file);
    Prty::Path->rename($file,$newName);
    $self->ok(-e $newName);

    Prty::Path->delete($newName);
}

sub test_rename_except : Test(1) {
    my $self = shift;

    my $file = "/tmp/nicht-existent$$";
    eval {Prty::Path->rename($file,'x')};
    $self->like($@,qr/PATH-00010/);
}

# -----------------------------------------------------------------------------

sub test_split : Test(14) {
    my $self = shift;

    my ($dir,$file,$base,$ext) = Prty::Path->split('datei');
    $self->is($dir,'');
    $self->is($file,'datei');
    $self->is($base,'datei');
    $self->is($ext,'');

    ($dir,$file,$base,$ext) = Prty::Path->split('datei.ext');
    $self->is($dir,'');
    $self->is($file,'datei.ext');
    $self->is($base,'datei');
    $self->is($ext,'ext');

    ($dir,$file,$base,$ext) = Prty::Path->split('/ein/pfad/datei.ext');
    $self->is($dir,'/ein/pfad');
    $self->is($file,'datei.ext');
    $self->is($base,'datei');
    $self->is($ext,'ext');

    ($dir,undef,$base,undef) = Prty::Path->split('/ein/pfad/datei.ext');
    $self->is($dir,'/ein/pfad');
    $self->is($base,'datei');
}

# -----------------------------------------------------------------------------

sub test_symlink : Test(1) {
    my $self = shift;

    my $symlink = "/tmp/x$$.test";
    my $file = "/tmp/symlink$$.test";
    Prty::Path->write($file);
    Prty::Path->symlink($file,$symlink);
    $self->ok(-l $symlink);

    Prty::Path->delete($symlink);
    Prty::Path->delete($file);
}

# -----------------------------------------------------------------------------

sub test_symlinkRelative : Test(5) {
    my $self = shift;

    # FIXME: alle Prty::Path-Methoden in Prty::Path implementieren
    #     und diese nutzen.

    my @paths = (
        'a'=>'x',
        'a'=>'x/y',
        'a/b'=>'x',
        'a/b'=>'x/y',
        'a/b/c'=>'x/y',
    );
    while (@paths) {
        my $path = shift @paths;
        my $symlink = shift @paths;

        (my $pathTop = $path) =~ s|/.*||;
        (my $symlinkTop = $symlink) =~ s|/.*||;

        Prty::Path->delete($pathTop);
        Prty::Path->delete($symlinkTop);

        if ($path =~ m|/|) {
            # my $pathParent = Prty::Path->parent($path);
            # Prty::Path->mkdir($pathParent,-recursive=>1);
            my $dir = (Prty::Path->split($path))[0];
            Prty::Path->mkdir($dir,-recursive=>1);
        }
        if ($symlink =~ m|/|) {
            # my $pathSymlink = Prty::Path->parent($symlink);
            # Prty::Path->mkdir($pathSymlink,-recursive=>1);
            my $dir = (Prty::Path->split($symlink))[0];
            Prty::Path->mkdir($dir,-recursive=>1);
        }

        Prty::Path->write($path,$$);
        Prty::Path->symlinkRelative($path,$symlink);
        my $data = Prty::Path->read($symlink);

        $self->is($data,$$);
    }

    Prty::Path->delete('a');
    Prty::Path->delete('x');
}

# -----------------------------------------------------------------------------

package main;
Prty::Path::Test->runTests;

# eof
