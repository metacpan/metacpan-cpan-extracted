#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

my $template_file = 'loop_error.xml';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
$Petal::OUTPUT = "XHTML";
my $template = new Petal ($template_file);

my %hash = (
	    'array_of_nums'      => [1,2,3,],
	    'array_of_chars'     => [qw/ a b c /],
	    'array_of_stuff'     => ['!', '@', '#'],
	    'array_of_nums2'     => [9,8,7,],
	    'array_of_chars2'    => [qw/ x y z /],
	    'array_of_stuff2'    => [qw/ $ % ^ /],
	    'array_of_nums3'     => [4,5,6,],
	    'array_of_chars3'    => [qw/ g h i /],
	    'array_of_stuff3'    => [qw/ & * | /],
);

my $str = undef;
eval { $str = $template->process(%hash) };

# shouldn't be any "num=[...]" that don't have numbers inside
unlike ($str, qr/num=\[\D+\]/);

# shouldn't be any "chr=[...]" that don't have chars inside
unlike ($str, qr/chr=\[\W+\]/);

# shouldn't be any "stf=[...]" that don't have 'stuff' inside
unlike ($str, qr/stf=\[[^\W]+\]/);
