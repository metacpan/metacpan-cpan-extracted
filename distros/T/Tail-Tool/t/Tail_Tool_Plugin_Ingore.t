#!/usr/bin/perl

BEGIN { $ENV{TESTING} = 1 }

use strict;
use warnings;
use Test::More tests => 6 + 1;
use Test::Warnings;

my $module = 'Tail::Tool::Plugin::Ignore';
use_ok( $module );

my $ig = $module->new( regex => 'test' );

isa_ok $ig, $module, 'Get a new ignore object';

my $line    = "the test line\n";

my @w = eval { $ig->process($line) };
diag $@ if $@;
ok !$@, 'No errors when trying to process the line';
ok !@w, "Line ignored";

$line    = "the line\n";

@w = eval { $ig->process($line) };
diag $@ if $@;
ok !$@, 'No errors when trying to process the line';
ok @w, "Line not ignored";

