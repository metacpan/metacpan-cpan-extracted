#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    plan tests => 1;
    require_ok('Passwd::Keyring::Secret') or BAIL_OUT("Cannot load Passwd::Keyring::Secret");
}

diag("Testing Passwd::Keyring::Secret $Passwd::Keyring::Secret::VERSION, Perl $], $^X");
diag("Consider spawning 'seahorse' to observe password changes caused by the tests.");
