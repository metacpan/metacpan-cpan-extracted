#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

my $libdir = "$FindBin::Bin/../lib";
eval qq(use lib "$libdir");

my @classes = map {
	s!^$libdir/!!; s!/!::!g; s!\.pm$!!g;
	$_;
} "$libdir/SMB.pm", map { glob("$libdir/SMB/$_.pm") } '*', 'v[12]/*', 'v[12]/*/*';

eval qq(use Test::More tests => ) . (0 + @classes); die $@ if $@;

use_ok($_) foreach @classes;
