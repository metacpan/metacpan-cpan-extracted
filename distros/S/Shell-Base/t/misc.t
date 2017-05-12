#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use Shell::Base;

plan tests => 3;

my ($version, $prog);
use_ok("Shell::Base");

is($version = Shell::Base->version, $Shell::Base::VERSION, '$self->version() is ok');
is($prog = Shell::Base->progname, 'misc.t', '$self->progname() is ok');
