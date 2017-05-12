#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::BASE_DIR = './t/data/';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;

my $template_file = 'split_expression.xml';
my $template = new Petal ($template_file);

like ($template->process (foo => 1, bar => 1), qr/Hello/);
