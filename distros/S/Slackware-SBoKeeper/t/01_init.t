#!/usr/bin/perl
use 5.016;
use strict;

use Test::More tests => 1;

# Tests:
# * use Slackware::SBoKeeper

use_ok('Slackware::SBoKeeper');

diag("Testing Slackware::SBoKeeper $Slackware::SBoKeeper::VERSION, Perl $], $^X");
