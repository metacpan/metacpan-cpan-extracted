#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use Shell::Base;

plan tests => 5;

use_ok("Shell::Base");

my $sh = Shell::Base->new;
my @comps = $sh->completions();
my %comps = map { ($_ => 1) } @comps;

is(scalar @comps, 3, "Found 3 completions");

ok(defined $comps{'help'}, "Found help");
ok(defined $comps{'version'}, "Found do_version");
ok(defined $comps{'warranty'}, "Found do_warranty");
