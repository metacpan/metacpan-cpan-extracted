#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# $Net::SFTP::Foreign::debug = -1;

use lib "./t";
use common;

use File::Spec;
use Cwd qw(getcwd);

use Config;

BEGIN {
    plan skip_all => "tests not supported on inferior OS"
	if (is_windows and eval "no warnings; getlogin ne 'salva'");

    plan skip_all => "Net::SFTP::Foreign is required for testing"
	unless eval <<USE;
use Net::SFTP::Foreign;
use Net::SFTP::Foreign::Constants qw(:flags);
1;
USE

    plan tests => 716;
}

$SIG{ALRM} = sub {
    print STDERR "# timeout expired: your computer is too slow or some test is not finishing\n";
    exit 1;
};

# don't set the alarm if we are being debugged!
alarm 300 unless exists ${DB::}{sub};

my @cmd = ($Config{perlpath}, '-Ilib', 'bin/sftp-server-fs-perl');
my @new_args = (open2_cmd => \@cmd, timeout => 10);
my $sftp = eval { Net::SFTP::Foreign->new(@new_args) };
diag($@) if $@;

ok (defined $sftp, "creating object");

my $lcwd = File::Spec->rel2abs('t');
my $rcwd = $sftp->realpath($lcwd);

ok (defined $rcwd, "realpath");

my @data = <DATA>;

for my $setcwd (0, 1) {
    my $orcwd = $rcwd;

    if ($setcwd) {
        $sftp->setcwd($orcwd);
        $rcwd = '.';
    }

    # print STDERR "cwd: $sftp->{cwd}\n";

    my $dlfn = File::Spec->catfile($lcwd, 'data.l');
    my $dlfn1 = File::Spec->catfile($lcwd, 'data1.l');
    my $drfn = File::Spec->catfile($rcwd, 'data.r');
    my $drfn_l = File::Spec->catfile($lcwd, 'data.r');
    my $drfn1 = "$drfn.1";
    my $drfn1_l = "$drfn_l.1";
    my $drdir_l = File::Spec->catdir($lcwd, 'testdir');
    my $drdir = File::Spec->catdir($rcwd, 'testdir');

    for my $i (1..8) {

	local $\ = ($i == 4 ? "-bad-" : undef);

        mktestfile($dlfn, $i * 4000,
                   "this is just testing data... foo bar doz wahtever... ");

        ok ($sftp->put($dlfn, $drfn1), "put - $i");
        diag ($sftp->error) if $sftp->error;

        ok(!filediff($dlfn, $drfn1_l), "put - file content - $i");

	unlink $drfn_l;
	ok (open(F, '<', $dlfn), "put fh - open - $i");
	ok ($sftp->put(\*F, $drfn1), "put fh - $i");
        diag ($sftp->error) if $sftp->error;
	ok (close(F), "put fh - close - $i");

        ok(!filediff($dlfn, $drfn1_l), "put fh - file content - $i");

        unlink $drfn_l;
        ok($sftp->rename($drfn1, $drfn), "rename - $i");
        diag ($sftp->error) if $sftp->error;

        mktestfile($drfn1_l, $i, "blah, blah, blah...");
        ok(!$sftp->rename($drfn, $drfn1), "rename no overwrite - $i");

        ok($sftp->rename($drfn, $drfn1, overwrite => 1), "rename force overwrite - $i");
        diag ($sftp->error) if $sftp->error;

        ok($sftp->rename($drfn1, $drfn), "rename again - $i");
        diag ($sftp->error) if $sftp->error;

        ok (my $attr = $sftp->stat($drfn), "stat - $i");

        is ($attr->size, (stat($dlfn))[7], "stat - size - $i");

        ok (!$sftp->put($dlfn, $drfn, overwrite => 0), "no overwrite - $i");
        is (int $sftp->error, Net::SFTP::Foreign::Constants::SFTP_ERR_REMOTE_OPEN_FAILED(), "no overwrite - error - $i");

        ok ($sftp->get($drfn, $dlfn1), "get - $i");
        diag ($sftp->error) if $sftp->error;
        ok(!filediff($drfn_l, $dlfn1), "get - file content - $i");
        unlink $dlfn1;

	ok (open(F, '>', $dlfn1), "get fh - open - $i");
	ok ($sftp->get($drfn, \*F), "get fh - $i");
	diag ($sftp->error) if $sftp->error;
	ok (close(F), "get fh - close - $i");
	ok(!filediff($drfn_l, $dlfn1), "get fh - file content - $i");

        unlink $dlfn1;
        unlink $drfn_l;
        unlink $dlfn;

    }

    # mkdir and rmdir

    rmdir $drdir_l;

    ok($sftp->mkdir($drdir), "mkdir 1");
    ok((-d $drdir_l), "mkdir 2");
    ok($sftp->rmdir($drdir), "rmdir 1");
    ok(!(-d $drdir_l), "rmdir 2");

    my $attr = Net::SFTP::Foreign::Attributes->new;
    $attr->set_perm(0700);

    ok($sftp->mkdir($drdir, $attr), "mkdir 3");
    ok((-d $drdir_l), "mkdir 4");

    my @stat = stat $drdir_l;
    is($stat[2] & 0777, 0700, "mkdir 5");

    $attr->set_perm(0770);
    ok($sftp->setstat($drdir, $attr), "setstat 1");
    @stat = stat $drdir_l;
    is($stat[2] & 0777, 0770, "setstat 2");

    ok($sftp->rmdir($drdir), "rmdir 3");
    ok(!(-d $drdir_l), "rmdir 4");

    # reconnect
    $sftp = eval { Net::SFTP::Foreign->new(@new_args) };
    diag($@) if $@;

    ok (defined $sftp, "creating object 2");

    # print STDERR "setcwd=$setcwd ($rcwd=$rcwd)\n";
    if ($setcwd) {
        $sftp->setcwd($orcwd);
    }

    my $fh = $sftp->open($drfn, SSH2_FXF_CREAT|SSH2_FXF_WRITE);
    ok ($fh, "open write file");

    print $fh $_ for @data;
    ok((print $fh @data, @data, @data, @data), "write to file 2");
    print $fh $_ for @data;
    ok((print $fh @data, @data, @data, @data), "write to file 2");
    ok (close $fh);

    my @all = (@data) x 10;

    $fh = $sftp->open($drfn);
    ok($fh, "open read file");

    my @read = <$fh>;
    # our ($a, $b);
    # D("@read", "@all") and diag "got: $a\nexp: $b\n\n";

    is("@read", "@all", "readline list context");
    ok(close($fh), "close file");

    $fh = $sftp->open($drfn);
    ok($fh, "open read file 2");

    @read = ();
    while (<$fh>) {
        push @read, $_;
    }
    is("@read", "@all", "readline scalar context");
    ok(close($fh), "close file");

    $fh = $sftp->open($drfn, SSH2_FXF_CREAT|SSH2_FXF_WRITE);
    ok ($fh, "open write file");

    my $all = join('', ((@all) x 10));
    my $cp = $all;
    while (length $all) {
        $sftp->write($fh, substr($all, 0, 1 + int(rand 64000), ''));
    }
    ok (close($fh), "close write file");

    $fh = $sftp->open($drfn);
    ok($fh, "open read file 3");

    ok(!$sftp->eof($fh), "not at eof");

    while (1) {
        my $data = $sftp->read($fh, 1+int(rand 64000));
        last unless defined $data;
        $all .= $data;
    }

    is($all, $cp, "write and read chunks");

    ok(eof($fh), "at eof");

    for my $pos (0, 1000, 0, 234, 4500, 1025) {
        my $d1;
        is(seek($fh, $pos, 0), $pos, "seek");
        is(read($fh, my $data, $pos), $pos, "read");
        is($d1 = $sftp->sftpread($fh, $pos, $pos), $data, "sftpread");
        # D($d1, $data) and diag "got: $a\nexp: $b\n\n";

        my $pos1 = $pos + length $data;
        for my $off (0, -1000, 234, 4500, -200, 1025) {
            next unless $pos1 + $off >= 0;
            $pos1 += $off;

            is(seek($fh, $off, 1), $pos1, "seek - 2");
            is(tell($fh), $pos1, "tell"); # if $pos1 > 2000;
            is(read($fh, $data, $pos), $pos, "read - 2 ($pos1, $pos)");
            is($d1 = $sftp->sftpread($fh, $pos1, $pos), $data, "sftpread - 2 ($pos1, $pos)");
            # D($d1, $data) and diag "got: $a\nexp: $b\n\n";
            $pos1 += length $data;
        }
    }

    my $ctn = $sftp->get_content($drfn);
    is($ctn, $all, "get_content");
    # D($ctn, $all, -10, 30) and diag "got: $a\nexp: $b\n\n";

    is(seek($fh, 0, 0), 0, 'seek - 3');
    my $line = readline $fh;

    my $wfh = $sftp->open($drfn, SSH2_FXF_WRITE);
    ok($wfh, "open write file 3");

    ok ($sftp->sftpwrite($wfh, length $line, "HELLO\n"), "sftpwrite");
    $sftp->flush($fh);
    is (scalar getc($fh), 'H', "getc");
    is (scalar readline($fh), "ELLO\n", "readline");
    ok(close($wfh), "close");

    ok(seek($fh, -2000, 2), 'seek');
    @all = readline $fh;

    {
        local $/; undef $/;
        ok(seek($fh, -2000, 2), 'seek');
        my $all = readline $fh;
        is ($all, join('', @all), "read to end of file");
        is (length $all, 2000, "seek");
    }

    opendir DIR, $lcwd;
    my @ld = sort grep !/^\./, readdir DIR;
    closedir DIR;

    # SKIP: {
    #    skip "tied directory handles not available on this perl", 3
    #	unless eval "use 5.9.4; 1";
    #
    #    my $rd = $sftp->opendir($rcwd);
    #    ok($rd, "open remote dir");
    #
    #    my @rd = sort grep !/^\./, readdir $rd;
    #    is("@rd", "@ld", "readdir array");
    #
    #    ok (closedir($rd), "close dir");
    #
    #};

    # print STDERR "cwd: $sftp->{cwd}\n";

    my $rd = $sftp->opendir($rcwd);
    ok($rd, "open remote dir 2 - $rcwd");

    my @rd = sort grep !/^\./, (map { $_->{filename} } $sftp->readdir($rd));
    is("@rd", "@ld", "readdir array 1 - $rcwd");
    ok($sftp->closedir($rd), "close dir 2");

    my @ls = sort map { $_->{filename} } @{$sftp->ls($rcwd, no_wanted => qr|^\.|)};
    is ("@ls", "@ld", "ls");

    my @ld1 = sort('t', @ld);
    my @uns = $sftp->find($rcwd,
                          wanted => sub { $_[1]->{filename} !~ m|^(?:.*/)?\.[^/]*$| },
                          descend => sub { $_[1]->{filename} eq $rcwd } );

    push @uns, { filename => 't' } if $setcwd;

    my @find = sort map { $_->{filename} =~ m|(?:.*/)?(.*)$| && $1 } @uns;

    local $" = '|';
    is ("@find", "@ld1", "find 1");

    @ld1 = @ld;
    unshift @ld1, 't' unless $setcwd;
    @find = map { m|(?:.*/)?(.*)$|; $1 }
        $sftp->find( $rcwd,
                     names_only => 1,
                     ordered => 1,
                     no_wanted => qr|^(?:.*/)?\.[^/]*$|,
                     no_descend => qr|^(?:.*/)?\.svn$|);

    is ("@find", "@ld1", "find 2");

    my @a = glob "$lcwd/*";
    is ($sftp->glob("$rcwd/*"), scalar @a, "glob");

    unlink $drfn_l;

    alarm 0;
    ok (1, "end");

}

__DATA__

Os Pinos.

¿Qué din os rumorosos
na costa verdecente
ao raio transparente
do prácido luar?
¿Qué din as altas copas
de escuro arume arpado
co seu ben compasado
monótono fungar?

Do teu verdor cinguido
e de benignos astros
confín dos verdes castros
e valeroso chan,
non des a esquecemento
da inxuria o rudo encono;
desperta do teu sono
fogar de Breogán.

Os bos e xenerosos
a nosa voz entenden
e con arroubo atenden
o noso ronco son,
mais sóo os iñorantes
e féridos e duros,
imbéciles e escuros
non nos entenden, non.

Os tempos son chegados
dos bardos das edades
que as vosas vaguedades
cumprido fin terán;
pois, donde quer, xigante
a nosa voz pregoa
a redenzón da boa
nazón de Breogán.

  - Eduardo Pondal

