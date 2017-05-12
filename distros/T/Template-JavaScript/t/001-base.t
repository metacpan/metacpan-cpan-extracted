#!/usr/bin/env perl

use strict;
use warnings;

# use Test::More tests => 6;
use Test::More qw( no_plan );

my $p = 'Template::JavaScript';

use_ok($p);

can_ok($p, 'new');

my $ctx = Template::JavaScript->new();

isa_ok($ctx, $p);

my $simple = <<'';
foobar
baz

can_ok($p, 'tmpl_string');
$ctx->tmpl_string( $simple );

can_ok($p, 'output');
$ctx->output( \my $out );

can_ok($p, 'run');
$ctx->run;

is( $out, "foobar\nbaz\n", 'can parse simple string' );
