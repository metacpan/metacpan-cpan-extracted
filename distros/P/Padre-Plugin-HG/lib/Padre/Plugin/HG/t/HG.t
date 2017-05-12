#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More tests => 3;
use FindBin qw ($Bin);
use lib ("$Bin/../../../../");
use Padre::Plugin::HG;
my @hgstatus = ( 'M dir1/test.txt',
	'? CVS',
	'? dir2/text1.txt',
	'? dir2/text2.txt',
	'? parseStatus.pm',
	'? status.txt',
	'? t/padreUtil.t',
	'? t/parseStatus.t',
	'? test1.txt');

my @files;
ok( @files = Padre::Plugin::HG::_get_hg_files(@hgstatus), "Get files from  hg status");
is ($files[0], 'dir1/test.txt', 'first file');
is ($files[8], 'test1.txt', 'last file');

print Padre::Plugin::HG::_project_root('','/home/mm/hg/test.pl');

