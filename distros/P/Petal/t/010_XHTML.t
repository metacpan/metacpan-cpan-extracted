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
$Petal::OUTPUT = 'XHTML';

my $template = new Petal ('xhtml.html');
my $string = $template->process;

unlike ($string, qr/<\/link>/);
unlike ($string, qr/<\/br>/);
unlike ($string, qr/<\/hr>/);
unlike ($string, qr/<\/input>/);
