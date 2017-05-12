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

my $template = new Petal (file => 'translate.xml');
my $string   = $template->process;
my $res = Petal::I18N->process ($string);

unlike ($res, '/\$\{1\}/');
unlike ($res, '/\$\{2\}/');
like ($res, '/download\.gna\.org/');
