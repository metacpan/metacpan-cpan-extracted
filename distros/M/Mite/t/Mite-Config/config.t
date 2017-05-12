#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;
use Path::Tiny;
use Mite::Config;

tests "write config" => sub {
    my $test_data = { foo => 23, bar => 42 };
    my $config = new_ok "Mite::Config", [data => $test_data];

    my $orig_dir = Path::Tiny->cwd;
    my $dir = Path::Tiny->tempdir;
    chdir $dir;

    $config->make_mite_dir;
    $config->write_config;
    ok -e $config->config_file;

    my $config2 = new_ok "Mite::Config";
    cmp_deeply $config2->data, $test_data;

    # Else the process ends in a temp dir and File::Temp can't clean it up
    chdir $orig_dir;
};

done_testing;
