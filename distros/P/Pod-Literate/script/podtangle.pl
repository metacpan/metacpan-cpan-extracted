#!/usr/bin/perl
use strict;
use warnings;
use Pod::Literate;

my $stdin;
@ARGV = map {($_ eq '-')&&!$stdin++?('--','-'):$_} @ARGV;

my $parser=Pod::Literate->new();
$parser->accept_targets('literate','literate:command');
$parser->expand_verbatim_tabs(0);
$parser->parse_from_file(shift(@ARGV));
