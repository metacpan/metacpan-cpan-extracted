use strict;
use warnings FATAL => "all";
use Test::More;
use t::Util;

use Path::Maker;

subtest base_dir => sub {
    my $tempdir = tempdir;

    my $maker = Path::Maker->new( base_dir => $tempdir );

    my $file;

    $maker->write_file('write.txt', 'writer!!');
    $file = catfile($tempdir, 'write.txt');
    ok -f $file;
    like slurp($file), qr/writer!!/;

    like $maker->render('hello.mt'), qr/hello world/;

    eval { $maker->render('not_found') };
    ok $@;

    $maker->render_to_file('hello.mt' => 'hello.txt');
    $file = catfile($tempdir, 'hello.txt');
    ok -f $file;
    like slurp($file), qr/hello world/;

    $maker->render_to_file('arg.mt' => 'arg.txt', qw(foo bar));
    $file = catfile($tempdir, 'arg.txt');
    ok -f $file;
    like slurp($file), qr/foo/;
    like slurp($file), qr/bar/;

    SKIP: {
        skip "chmod 0777 doesn't work on MSWin32", 1 if $^O eq 'MSWin32';
        $maker->chmod('write.txt', 0777);
        ok -x catfile($tempdir, 'write.txt');
    }

    $maker->create_dir('dir');
    ok -d catdir($tempdir, 'dir');
};


subtest rel_dir => sub {
    my $tempdir = tempdir;
    chdir $tempdir;

    my $maker = Path::Maker->new;

    my $file;


    $maker->write_file('write.txt', 'writer!!');
    $file = 'write.txt';
    ok -f $file;
    like slurp($file), qr/writer!!/;

    like $maker->render('hello.mt'), qr/hello world/;

    eval { $maker->render('not_found') };
    ok $@;

    $maker->render_to_file('hello.mt' => 'hello.txt');
    $file = 'hello.txt';
    ok -f $file;
    like slurp($file), qr/hello world/;

    $maker->render_to_file('arg.mt' => 'arg.txt', qw(foo bar));
    $file = 'arg.txt';
    ok -f $file;
    like slurp($file), qr/foo/;
    like slurp($file), qr/bar/;

    SKIP: {
        skip "chmod 0777 doesn't work on MSWin32", 1 if $^O eq 'MSWin32';
        $maker->chmod('write.txt', 0777);
        ok -x 'write.txt';
    }

    $maker->create_dir('dir');
    ok -d 'dir';

    chdir "/";
};

done_testing;

__DATA__

@@ hello.mt
hello world

@@ arg.mt
? my ($arg1, $arg2) = @_;
arg1 = <?= $arg1 ?>, arg2 = <?= $arg2 ?>
