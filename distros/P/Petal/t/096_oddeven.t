#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$|=1;

$Petal::BASE_DIR     = './t/data/';
$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT        = 1;

my $template_file = 'oddeven.xml';
my $template      = new Petal ($template_file);
my $string        = $template->process (items => ['one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten']);

like ($string, '/<odd>one</odd>/');
like ($string, '/<even>two</even>/');
like ($string, '/<odd>three</odd>/');
like ($string, '/<even>four</even>/');
like ($string, '/<odd>five</odd>/');
like ($string, '/<even>six</even>/');
like ($string, '/<odd>seven</odd>/');
like ($string, '/<even>eight</even>/');
like ($string, '/<odd>nine</odd>/');
like ($string, '/<even>ten</even>/');

__END__
