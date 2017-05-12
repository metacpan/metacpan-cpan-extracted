#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::BASE_DIR = './t/data/multiple_includes/';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;

my $template_file = 'test.tmpl';
my $template = new Petal ($template_file);


my $hash = {
	first_name => "William",
	last_name => "McKee",
	last => "Boo",
	email => 'william@knowmad.com',
};

like ($template->process ($hash), qr/william\@knowmad.com/);
unlike ($template->process ($hash), qr/Boo/);
unlike ($template->process ($hash), qr/McKee_opposite/);
