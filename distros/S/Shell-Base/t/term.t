#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use Shell::Base;

plan tests => 3;

use_ok("Shell::Base");

my $shell = Shell::Base->new;
my $term = $shell->term;
ok(defined $term, '$self->term() returns something useful');
ok($term->isa("Term::ReadLine"), '$self->term() returns something readline-ish');
