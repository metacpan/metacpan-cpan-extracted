#!/usr/bin/env perl
use strict;
use warnings;
use lib "lib";

use Test::More tests => 8;
use Capture::Tiny qw/capture/;

BEGIN { use_ok 'Shell::Verbose'; }
use Shell::Verbose qw/verboseSystem vsys/;

# Basic usage of verboseSystem() & vsys()
my ($stdout, $stderr) = capture {
    verboseSystem("echo 'foo'");
};
my $expected = "echo 'foo'\nfoo\n";
ok $stdout eq $expected;

($stdout, $stderr) = capture {
    vsys("echo 'foo'");
};
ok $stdout eq $expected;

# Check the simplified return value
my $ret = vsys("true");
ok $ret == 1;

$ret = vsys("false");
ok $ret == 0;

# Prefix
Shell::Verbose->prefix('===> ');
$expected = "===> echo 'foo'\nfoo\n";
($stdout, $stderr) = capture {
    vsys("echo 'foo'");
};
ok $stdout eq $expected;
Shell::Verbose->prefix('');

# Before line
Shell::Verbose->before('above');
$expected = "above\necho 'foo'\nfoo\n";
($stdout, $stderr) = capture {
    vsys("echo 'foo'");
};
ok $stdout eq $expected;
Shell::Verbose->before('');

# After line
Shell::Verbose->after('below');
$expected = "echo 'foo'\nfoo\nbelow\n";
($stdout, $stderr) = capture {
    vsys("echo 'foo'");
};
ok $stdout eq $expected;
Shell::Verbose->after('');
