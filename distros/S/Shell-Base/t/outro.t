#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use Shell::Base;

plan tests => 2;

use_ok("Shell::Base");

package Silly;
use base qw(Shell::Base);

$Silly::Outro = "I like cake";

sub outro { $Silly::Outro } 

package main;

my $sh = Silly->new;

is($sh->outro, $Silly::Outro,  "outro works ok: '$Silly::Outro'");
