#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::BASE_DIR = './t/data/multiple_includes';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;

my $template_file = 'register_form.tmpl';
my $template = new Petal ($template_file);

my $data_ref = $template->_file_data_ref;
$data_ref  = $template->_canonicalize;
my @count = $$data_ref =~ /(include)/gsm;
ok (scalar @count > 1);


1;
