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

my $template = new Petal ('delete_attribute.xml');
my $string = $template->process;
unlike ($string, qr /type/);

$Petal::OUTPUT = 'HTML';
$template = new Petal ('delete_attribute.xml');
$string = $template->process;
unlike ($string, qr /type/);
like ($string, qr/\Qbar="0"\E/);

$string = $template->process ('nothing' => '');
like ($string, qr/type/);
like ($string, qr/\Qbar="0"\E/);
