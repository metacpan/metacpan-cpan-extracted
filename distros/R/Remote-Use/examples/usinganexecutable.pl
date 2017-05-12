#!/usr/bin/perl -I../lib -w
use strict;
use Remote::Use config => 'wgetwithbinconfig';
use Parse::Eyapp;
use Parse::Eyapp::Treeregexp;

$ENV{PERL5LIB} .= ":/tmp/perl5lib/files";
$ENV{PATH} .= ":/tmp/perl5lib/bin";

system('echo $PATH; eyapp -h');
