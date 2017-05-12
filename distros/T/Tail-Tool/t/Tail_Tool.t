#!/usr/bin/perl

BEGIN { $ENV{TESTING} = 1 }

use strict;
use warnings;
use Test::More tests => 6 + 1;
use Test::Warnings;
use Test::Output;

my $module = 'Tail::Tool';
use_ok( $module );

my $tail = $module->new;
ok $tail, "Create a new $module object";

stdout_is( sub {$tail->default_printer('test')}, 'test', 'Outputs what was put in');
stdout_is( sub { $tail->tail(0) }, '', '');

# load a plugin
my $result = eval {Tail::Tool::_new_plugin('Spacing', {})};
diag $@ if $@;
isa_ok $result, 'Tail::Tool::Plugin::Spacing', 'Added plugin';

$result = eval {Tail::Tool::_new_plugin('+Tail::Tool::Plugin::Spacing', {})};
diag $@ if $@;
isa_ok $result, 'Tail::Tool::Plugin::Spacing', 'Added plugin';
