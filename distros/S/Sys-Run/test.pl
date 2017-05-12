#!perl
use strict;
use warnings;
use Sys::Run;
use Log::Tree;

my $Run = Sys::Run->new({'logger'=>Log::Tree->new('test')});

$Run->run_cmd('/bin/true');

