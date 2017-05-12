#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::INPUT = 'HTML';
$Petal::BASE_DIR = './t/data/';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;

my $template = new Petal ('nbsp.html');
my $string   = $template->process;
my $nbsp     = chr (160);
my $acirc    = chr (194);

like   ($string, qr/$nbsp/);
unlike ($string, qr/$acirc/);
