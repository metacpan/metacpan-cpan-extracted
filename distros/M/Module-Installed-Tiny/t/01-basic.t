#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use File::Temp qw(tempdir);
use Module::Installed::Tiny qw(module_source module_installed);

subtest module_installed => sub {
    ok( module_installed("Test::More"), "already loaded -> true");
    ok( module_installed("Test/More.pm"), "Foo/Bar.pm-style accepted");
    ok( module_installed("if"), "'if' is installed");
    ok(!exists($INC{"if.pm"}), "if.pm is not actually loaded");
    ok(!module_installed("Local::Foo"), "not found on filesystem -> false");
};

subtest module_source => sub {
    like(module_source("if"), qr/package if/);

    my $tempdir = tempdir(CLEANUP => $ENV{DEBUG} ? 0:1);
    note "tempdir=$tempdir";
    my $rand1 = int(rand()*4000)+1000;
    my $rand2 = int(rand()*4000)+5000;

    local @INC = (@INC, $tempdir, "$tempdir/lib2");

    my $sep = $Module::Installed::Tiny::SEPARATOR;

    {
        mkdir "$tempdir/Foo";
        my $fh;

        open $fh, ">", "$tempdir/Foo/Bar$rand1.pm" or die;
        print $fh "package Foo::Bar$rand1;\n1;\n";
        close $fh;

        mkdir "$tempdir/lib2";
        mkdir "$tempdir/lib2/Foo";
        open $fh, ">", "$tempdir/lib2/Foo/Bar$rand1.pm" or die;
        print $fh "package Foo::Bar$rand1;\n2;\n";
        close $fh;

        mkdir "$tempdir/Foo/Bar$rand2";
    }

   subtest "list context" => sub {
        my @res = module_source("Foo::Bar$rand1");
        is_deeply(\@res, [
            "package Foo::Bar$rand1;\n1;\n",
            "$tempdir${sep}Foo${sep}Bar$rand1.pm",
            $tempdir,
            $#INC-1,
            "Foo::Bar$rand1",
            "Foo/Bar$rand1.pm",
            "Foo${sep}Bar$rand1.pm",
        ]);
    };

    subtest "opt: die" => sub {
        dies_ok { module_source("Foo::Bar0117") };
        is_deeply(scalar(module_source("Foo::Bar0117", {die=>0})), undef);
    };

    subtest "opt: all" => sub {
        my $res = module_source("Foo::Bar$rand1", {all=>1});
        is_deeply($res, [
            "package Foo::Bar$rand1;\n1;\n",
            "package Foo::Bar$rand1;\n2;\n",
        ]);

        my @res = module_source("Foo::Bar$rand1", {all=>1});
        is_deeply(\@res, [
            [
                "package Foo::Bar$rand1;\n1;\n",
                "$tempdir${sep}Foo${sep}Bar$rand1.pm",
                $tempdir,
                $#INC-1,
                "Foo::Bar$rand1",
                "Foo/Bar$rand1.pm",
                "Foo${sep}Bar$rand1.pm",
            ], [
                "package Foo::Bar$rand1;\n2;\n",
                "$tempdir${sep}lib2${sep}Foo${sep}Bar$rand1.pm",
                "$tempdir${sep}lib2",
                $#INC,
                "Foo::Bar$rand1",
                "Foo/Bar$rand1.pm",
                "Foo${sep}Bar$rand1.pm",
            ],
        ]);
    };

    subtest "opt: find_prefix" => sub {
        my ($source, $path) = module_source("Foo::Bar$rand2", {die=>0});
        is_deeply($source, undef);
        is_deeply($path, undef);

        ($source, $path) = module_source("Foo::Bar$rand2", {die=>0, find_prefix=>1});
        is_deeply($source, undef);
        note "path=$path";
        ok($path);

        $path = module_source("Foo::Bar$rand2", {die=>0, find_prefix=>1});
        is(ref $path, 'SCALAR');
        note "path=\\ ".$$path;
    };

};

done_testing;
