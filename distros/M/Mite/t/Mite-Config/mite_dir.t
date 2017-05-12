#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;
use Path::Tiny;
use autodie;

use Mite::Config;

my $Orig_Dir = Path::Tiny->cwd;

tests "find_mite_dir with no .mite dir" => sub {
    my $dir = Path::Tiny->tempdir;

    my $config = new_ok 'Mite::Config';
    my $mite_dir = $config->find_mite_dir($dir);
    if( $mite_dir ) {
        isnt $mite_dir, $dir;
    }
    else {
        pass;
    }
};

tests "make_mite_dir twice" => sub {
    my $dir = Path::Tiny->tempdir;
    my $config = new_ok "Mite::Config";
    ok $config->make_mite_dir($dir);
    ok -d $dir->child($config->mite_dir_name);
    ok !$config->make_mite_dir($dir);
};

tests "find_mite_dir" => sub {
    my $dir = Path::Tiny->tempdir;
    my $subdir = $dir->child("inner");
    $subdir->mkpath;

    my $config = new_ok 'Mite::Config';
    ok $config->make_mite_dir($dir);

    is $config->find_mite_dir($dir),    $dir->child($config->mite_dir_name);
    is $config->find_mite_dir($subdir), $dir->child($config->mite_dir_name);

    $config->search_for_mite_dir(0);
    is $config->find_mite_dir($dir),    $dir->child($config->mite_dir_name);
    ok !$config->find_mite_dir($subdir);
};

tests "no mite dir" => sub {
    my $dir = Path::Tiny->tempdir;
    chdir $dir;

    my $config = new_ok "Mite::Config", [
        search_for_mite_dir => 0
    ];
    throws_ok {
        $config->mite_dir;
    } qr{^No .mite directory found.$};

    chdir $Orig_Dir;
};

done_testing;
