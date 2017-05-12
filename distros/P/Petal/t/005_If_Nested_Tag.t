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

my $template_file = 'if.xml';
my $template = new Petal ($template_file);
unlike ($template->process, qr/\<p\>/);
like ($template->process (error => 'Some error message'), qr/Some error message/);
