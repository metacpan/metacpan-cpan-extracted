#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;
use Path::Tiny;
use Test::Output;

tests "init" => sub {
    my $orig_dir = Path::Tiny->cwd;
    my $dir = Path::Tiny->tempdir;
    chdir $dir;

    stdout_is {
        mite_command(init => "Foo::Bar");
    } "Initialized mite in @{[$dir->child('.mite')->realpath]}\n";
    

    require Mite::Config;
    my $config = new_ok "Mite::Config";
    my $config_data = $config->data;
    is $config_data->{project},         "Foo::Bar";
    is $config_data->{shim},            "Foo::Bar::Mite";
    is $config_data->{source_from},     "lib";
    is $config_data->{compiled_to},     "lib";

    chdir $orig_dir;
};

done_testing;
