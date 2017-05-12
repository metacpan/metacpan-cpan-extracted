#!/usr/bin/perl

# Test to see if the module loads correctly.
use warnings;
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok('Module::Starter::Plugin::CGIApp');
}

diag(
    "Testing Module::Starter::Plugin::CGIApp $Module::Starter::Plugin::CGIApp::VERSION, Perl $], $^X"
);
