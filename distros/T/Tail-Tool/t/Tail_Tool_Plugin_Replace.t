#!/usr/bin/perl

BEGIN { $ENV{TESTING} = 1 }

use strict;
use warnings;
use Test::More tests => 6 + 1;
use Test::Warnings;
use Tail::Tool::RegexList;

my $module = 'Tail::Tool::Plugin::Replace';
use_ok( $module );

my $rep = $module->new( regex => Tail::Tool::Regex->new( enabled => 1, regex => qr/foo/, replace => 'bar' ) );

isa_ok $rep, $module, 'Get a new replace object';

my $line    = "the test line\n";

my @w = eval { $rep->process($line) };
diag $@ if $@;
ok !$@, 'No errors when trying to process the line';
ok @w, "Line replace";

$line    = "the foo line\n";

@w = eval { $rep->process($line) };
diag $@ if $@;
ok !$@, 'No errors when trying to process the line';
is $w[0], "the bar line\n", "Line replace";

