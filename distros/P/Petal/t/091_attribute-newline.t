#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::BASE_DIR     = './t/data/';
$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT        = 1;

my $string = Petal->new ('attribute-newline.xml')->process ();
like ($string, '/>apple</', '');
like ($string, '/>orange</', '');
like ($string, '/>plum</', '');
like ($string, '/>pear</', '');
like ($string, '/>ay bee cee</', '');
like ($string, '/>ex why zed</', '');

