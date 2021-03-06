#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

my $template_file = 'comments.xml';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';

my $template = new Petal ($template_file);
my $string = $template->process();

like ($string => qr/<!-- This is a comment -->/);
unlike ($string => qr/<!--? This is a petal comment -->/);

