#!/usr/bin/perl

BEGIN { $ENV{TESTING} = 1 }

use strict;
use warnings;
use Test::More tests => 4 + 1;
use Test::Warnings;

my $module = 'Tail::Tool::Plugin::Highlight';
use_ok( $module );

my $hl = $module->new( regex => 'test', colourer => sub { "[$_[1]]" } );

isa_ok $hl, $module, 'Get a new hl object';

my $line    = "the test line\n";
my $hl_line = "the [test] line\n";

my $w = eval { $hl->process($line) };
diag $@ if $@;
ok !$@, 'No errors when trying to process the line';
is $w, $hl_line, 'Get the expected highlighted line back';

