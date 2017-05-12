#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;
use Test::Output;

tests "help" => sub {
    stdout_like {
        mite_command "help";
    } qr/Available commands/;

    ok !$INC{"Mite/App.pm"}, "does not pollute the current process";
};

tests "can capture message on failure" => sub {
    stderr_like {
        ok !eval { mite_command("init"); };
    } qr{Usage: };
};

done_testing;
