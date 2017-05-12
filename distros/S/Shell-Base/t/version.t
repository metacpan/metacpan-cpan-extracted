#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use Shell::Base;
use File::Basename qw(basename);

plan tests => 3;

use_ok("Shell::Base");

my $sh = Shell::Base->new;
my $v = sprintf("%s v%s", basename($0), $Shell::Base::VERSION);

is($v, $sh->do_version, "do_version => '$v'");
is($sh->help_version, "Display the version.", "help_version ok");
