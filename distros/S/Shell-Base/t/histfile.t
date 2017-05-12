#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use POSIX qw(tmpnam);
use Shell::Base;

plan tests => 2;

use_ok("Shell::Base");

my $histfile = tmpnam();
my $sh = Shell::Base->new(HISTFILE => $histfile);

is($sh->args("HISTFILE"), $histfile, "History file $histfile");
