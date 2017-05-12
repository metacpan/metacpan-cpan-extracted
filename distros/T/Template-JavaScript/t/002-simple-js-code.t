#!/usr/bin/env perl

use strict;
use warnings;

# for the time being
use Test::More qw( no_plan );
use Test::Output;

use Template::JavaScript;

my $ctx = Template::JavaScript->new();

$ctx->output( \my $out );

$ctx->tmpl_string( <<'' );
before
% for( var i = 3; i ; i-- ){
  this is a loop
% }
after

$ctx->run;

is( $out, <<'', 'can run simple JS code (loops)' );
before
  this is a loop
  this is a loop
  this is a loop
after

undef $ctx;  # safety net

my $ctx2 = Template::JavaScript->new();

$ctx2->output( \*STDOUT );

$ctx2->tmpl_string( <<'' );
% if ( true ) {
I am a lumberjack and I am OK
% }

stdout_is(
  sub { $ctx2->run },
  "I am a lumberjack and I am OK\n",
  'can write to STDERR FH'
);

undef $ctx2;  # safety net

1;
# :)
