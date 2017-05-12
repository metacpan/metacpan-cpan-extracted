#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use File::Spec;
use Test::More tests => 19;
use Cwd;   


use lib ("./lib");
use_ok ('Padre::Plugin::HG');
my $hg = Padre::Plugin::HG->object_for_testing();
ok (`hg`, 'Found hg');
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
ok( @files = $hg->_get_hg_files(@hgstatus), "Get files from  hg status");
is ($files[0]->[0], 'M', 'first file Status');
is ($files[0]->[1], 'dir1/test.txt', 'First file Name');
is ($files[8]->[0], '?', 'Last file Status');
is ($files[8]->[1], 'test1.txt', 'Last file Name');

my $hg_file = File::Spec->catdir((getcwd() ,'t','hg_test_dir', 'dir1'));
my $root = File::Spec->catdir((getcwd(), 't','hg_test_dir'));
is($hg->_project_root($hg_file ),$root, 'Determined Project root');

#Parse the history log

my $log_string = q !changeset:   14:f9a3b28f269c
user:        mm@mm-laptop
date:        Fri Oct 30 08:41:24 2009 +1100
summary:     Implement Better Diff Viewing

changeset:   3:80d72b2a4751
user:        bill@microsoft.com
date:        Fri Oct 16 07:05:27 2009 +1100
summary:     Added files for CPAN distribution

changeset:   3:80d72b2a4751
user:        bill@microsoft.com
date:        Fri Oct 16 07:05:27 2009 +1100
summary:     Tricky Comment summary: CPAN distribution

changeset:   3:80d72b2a4751
user:        bill@microsoft.com
date:        Fri Oct 16 07:05:27 2009 +1100
summary:     

!;

my @log;
ok ( @log = $hg->parse_log($log_string), 'Parse the Log String');

is ($log[0]->{user}, 'mm@mm-laptop', 'first User Log');
is ($log[0]->{changeset}, '14:f9a3b28f269c', 'first changeset Log');
is ($log[0]->{date}, 'Fri Oct 30 08:41:24 2009 +1100', 'first date Log');
is ($log[0]->{summary}, 'Implement Better Diff Viewing', 'first summary Log');
is ($log[1]->{user}, 'bill@microsoft.com', 'Second User Log');
is ($log[1]->{changeset}, '3:80d72b2a4751', 'Second chageset Log');
is ($log[1]->{date}, 'Fri Oct 16 07:05:27 2009 +1100', 'Second date Log');
is ($log[1]->{summary}, 'Added files for CPAN distribution', 'Second summary Log');

is ($log[2]->{summary}, 'Tricky Comment summary: CPAN distribution', 'Tricky summary Log');

is ($log[3]->{summary}, '', 'Blank');


