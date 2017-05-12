#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$|=1;

my $template_file = 'set_cache_fresh.xml';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
$Petal::OUTPUT = "XML";
my $template = new Petal ($template_file);

like ($template->process() => qr/hello/);
