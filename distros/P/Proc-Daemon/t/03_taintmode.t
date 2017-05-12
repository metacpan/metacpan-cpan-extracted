#!/usr/bin/perl -T

use strict;
use warnings;

use Cwd;

# Try to make sure we are in the test directory
my $cwd = Cwd::cwd();
chdir 't' if $cwd !~ m{/t$};
$cwd = Cwd::cwd();
$cwd = ($cwd =~ /^(.*)$/)[0]; # untaint

# re-run 02_testmodule.t with taint mode on
require "$cwd/02_testmodule.t";
