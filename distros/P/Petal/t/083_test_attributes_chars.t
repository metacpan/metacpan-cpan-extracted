#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = './t/data/test_attributes_chars/';

my $template;


#####

$template = new Petal('test_attributes_chars1.xml');

my $string = $template->process (value1 => 'new_value1', value2 => 'new_value2');
like ($string => qr/new_value1/);
like ($string => qr/new_value2/);

__END__
