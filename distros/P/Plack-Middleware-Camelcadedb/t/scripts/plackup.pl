#!/usr/bin/perl

use strict;
use Plack::Runner;

my $runner = Plack::Runner->new;
$runner->parse_options(@ARGV);
$runner->run;
