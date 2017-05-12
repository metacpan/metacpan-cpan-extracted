#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

my $template_file = 'infinite_includes.xml';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';

my $template = new Petal ($template_file);
my $string = $template->process();
like ($string => qr/ERROR/);
