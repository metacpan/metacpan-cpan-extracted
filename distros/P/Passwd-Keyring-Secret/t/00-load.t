#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    plan tests => 1;

    ok(eval { require Passwd::Keyring::Secret; 1 }, "load Passwd::Keyring::Secret");

    if ($@)
    {
        diag($@);
        BAIL_OUT("OS unsupported");
    }
}

diag("Testing Passwd::Keyring::Secret $Passwd::Keyring::Secret::VERSION, Perl $], $^X");
diag("Consider spawning 'seahorse' to observe password changes caused by the tests.");
