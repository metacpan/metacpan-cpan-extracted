#!/usr/bin/perl
use strict;
use warnings;

use lib ".";
use lib "lib";

use Test::More 'no_plan';

BEGIN { use_ok('RTG::Report'); };
require_ok('RTG::Report');

my $reporter = RTG::Report->new();

my $last_timestamp = 120;
my $timestamp      = 120;
my $table          = 'imaginary.table';
my $iid            = 1;
my $counter        = 10000;

ok( $reporter->timestamp_sanity($last_timestamp, $timestamp, $table, $iid, $counter), 'timestamp_sanity ok');

$last_timestamp = 220;
ok( ! eval { $reporter->timestamp_sanity($last_timestamp, $timestamp, $table, $iid, $counter) }, 'timestamp_sanity nok');
