#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use Shell::Base;

plan tests => 5;

use_ok("Shell::Base");

my $line = "foo bar baz";

is(Shell::Base->precmd($line), $line, "precmd does not modify its args");
is(Shell::Base->postcmd($line), $line, "postcmd does not modify its args");

package Silly;
use base qw(Shell::Base);

sub precmd { return "<$_[1]>" }
sub postcmd { return ">$_[1]<" }

package main;

my $sh = Silly->new;
is($sh->precmd($line), "<$line>", "precmd correct");
is($sh->postcmd($line), ">$line<", "postcmd correct");
