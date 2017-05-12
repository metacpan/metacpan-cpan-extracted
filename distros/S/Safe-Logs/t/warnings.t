#!/usr/bin/perl

# Test the warning:: overrides

use Test::More tests => 2;
use warnings;
use warnings::register;
use Safe::Logs;

END { unlink "test.out"; }

sub _read
{
    open FILE, "test.out";
    my $ret = join('', <FILE>);
    close FILE;
    return $ret;
}

sub _setup
{
    open STDERR, ">test.out";
    select((select(STDERR), $|++)[0]);
}

eval 
{ 
    _setup;
  warnings::warn("escape --> \x1b\n");
};

ok(index(_read, "escape --> [esc]\n") != -1, "warnings::warn");

eval 
{ 
    _setup;
  warnings::warnif("void", "escape --> \x1b\n");
};
ok(index(_read, "escape --> [esc]\n") != -1, "warnings::warnif");
