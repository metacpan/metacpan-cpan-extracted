#!/usr/bin/perl
##############################################################################
# Tests the 'language' option (and 'lang' alias) to Petal->new.
# Uses t/data/language/*
#

# this is identical to t/052_Opt_language but with DISK_CACHE=1

use Test::More 'no_plan';

use warnings;
use lib 'lib';

use Petal;

$Petal::MEMORY_CACHE = 1;
$Petal::DISK_CACHE = 0;
$Petal::CACHE_ONLY = 1;

my $data_dir = 't/data';

my $file     = 'cookbook.html';
my $template = new Petal (file => $file, base_dir => $data_dir);
ok (eval {$template->process()}, 'process() CACHE_ONLY=1 without args should succeed');

$Petal::CACHE_ONLY = 0;
$Petal::MEMORY_CACHE = 0;

$file          = 'children.xml';
my $template_A = new Petal (file => $file, base_dir => $data_dir);
ok (!eval {$template_A->process()}, 'process() without args should fail');

$Petal::MEMORY_CACHE = 1;

$file          = 'children.xml';
my $template_B = new Petal (file => $file, base_dir => $data_dir, cache_only => 1);
ok (eval {$template_B->process()}, 'process() cache_only=1 without args should succeed');

