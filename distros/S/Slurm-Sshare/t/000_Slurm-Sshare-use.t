#!/usr/bin/env perl
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 000_Slurm-Sshare-use.t'
#
#Just check module loads

use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Slurm::Sshare' ) || print "Bail out!\n";
}

diag( "Testing Slurm::Sshare $Slurm::Sshare::VERSION, Perl $], $^X" );
