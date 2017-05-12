#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use Test::More tests => 1;

use SQL::Easy;

my $version = $SQL::Easy::VERSION;

$version = "(unknown version)" if not defined $version;

ok(1, "Testing SQL::Easy $version, Perl $], $^X" );
