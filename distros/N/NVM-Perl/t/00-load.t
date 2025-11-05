#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my @modules= qw(
    NVMPL::Config
    NVMPL::Core
    NVMPL::Installer
    NVMPL::Remote
    NVMPL::Switcher
    NVMPL::Utils
    NVMPL::Shell::Bash
    NVMPL::Shell::Cmd
    NVMPL::Shell::Zsh
    NVMPL::Shell::PowerShell
    NVMPL::Platform::Unix
    NVMPL::Platform::Windows
);

plan tests => scalar @modules;

for my $module (@modules) {
    use_ok($module) or diag("Cannot load $module");
}

done_testing();