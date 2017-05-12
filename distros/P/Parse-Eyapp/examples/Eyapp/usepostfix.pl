#!/usr/bin/perl -w
use strict;
use Postfix;

my $parser = new Postfix();
$parser->Run;
