#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use Shell::Base;

plan tests => 16;
my ($cmd, $env, @args);

use_ok("Shell::Base");

($cmd, $env, @args) = Shell::Base->parseline("foo bar baz");
is($cmd, "foo", "parsing command");
is(scalar @args, 2, "parsing args");
is(scalar keys %$env, 0, "parsing 0 env vars");

($cmd, $env, @args) = Shell::Base->parseline("FOO=bar foo bar baz");
is($cmd, "foo", "parsing command");
is(scalar @args, 2, "parsing args");
is(scalar keys %$env, 1, "parsing 1 env var");

($cmd, $env, @args) = Shell::Base->parseline("foo bar 'baz quux'");
is($cmd, "foo", "parsing command");
is(scalar @args, 2, "parsing args, with embedded spaces and quotes");
is(scalar keys %$env, 0, "parsing 0 env vars");

($cmd, $env, @args) = Shell::Base->parseline("ls -ltr");
is($cmd, "ls", "parsing command");
is(scalar @args, 1, "parsing switches");
is(scalar keys %$env, 0, "parsing 0 env vars");

($cmd, $env, @args) = Shell::Base->parseline("FOO='bar baz' quux");
is($cmd, "quux", "parsing command");
is(scalar @args, 0, "parsing args");
is(scalar keys %$env, 1, "parsing 1 env var with spaces: '$env->{FOO}'");

