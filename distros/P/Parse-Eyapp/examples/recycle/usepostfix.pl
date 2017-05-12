#!/usr/bin/perl -w
use strict;
use Postfix;

my $parser = new Postfix();
push @ARGV, '--noslurp';
$parser->main('Expression (i.e. 2*3): ');
