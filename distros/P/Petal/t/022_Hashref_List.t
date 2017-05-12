#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

my $template_file = 'hashref_list.html';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';


$Petal::OUTPUT = "XHTML";
my $template = new Petal ($template_file);

my %hash = ();
$hash{'fields'} = [
    { 'name' => 'field1', 'value' => 'value1' },
    { 'name' => 'field2', 'value' => 'value2' },
];


eval { $template->process(%hash) };
ok (!$@);
