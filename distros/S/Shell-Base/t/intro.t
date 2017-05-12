#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use Shell::Base;

plan tests => 2;

use_ok("Shell::Base");

package Silly;
use base qw(Shell::Base);

$Silly::Intro = "I like cake";

sub intro { $Silly::Intro } 

package main;

my $sh = Silly->new;

is($sh->intro, $Silly::Intro,  "intro works ok: '$Silly::Intro'");
