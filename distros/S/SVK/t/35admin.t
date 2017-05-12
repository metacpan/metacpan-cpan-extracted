#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;

use SVK::Util qw( can_run );

plan skip_all => 'svnadmin not in PATH'
    unless can_run('svnadmin');

plan tests => 4;

our $output;
my ($xd, $svk) = build_test('test');
is_output_like ($svk, 'admin', [], qr'SYNOPSIS', 'admin - help');

# can't catch output from system()
$svk->admin('help');
is_output ($svk, 'admin', ['lstxns'], [], 'admin - lstxns');
is_output ($svk, 'admin', ['lstxns', 'test'], [], 'admin - lstxns');
is_output ($svk, 'admin', ['rmcache'], [], 'admin - rmcache');

1;
