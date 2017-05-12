#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

my $template_file = 'omit-tag.xml';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';

my $template = new Petal ($template_file);
my $string = $template->process();
like($string, '/<b>This tag should not be omited/', "XML - XML preserve");
unlike($string, '/<b>This tag should be omited/', "XML - XML omit");

$Petal::OUTPUT = "XHTML";
$string = $template->process();

like($string, '/<b>This tag should not be omited/', "XML - XHTML preserve");
unlike($string, '/<b>This tag should be omited/', "XML - XHTML omit");


1;
