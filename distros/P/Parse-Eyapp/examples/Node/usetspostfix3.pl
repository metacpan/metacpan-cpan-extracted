#!/usr/bin/perl -w
use strict;
use TSPostfix3;

my $parser = new TSPostfix3();
$parser->Run(@ARGV);
