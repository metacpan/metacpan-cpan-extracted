use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 42;
use Perlmazing qw(catdir catfile devnull splitpath splitdir catpath abs2rel rel2abs);
use File::Spec ();

my $path_1 = '/usr/bin/perl';
my $path_2 = 'C:\Windows\System32\\';
my $path_3 = 'C:\Windows\System32';
my $path_4 = '\\\\ws1';
my $path_5 = '\\\\ws1\\';
my $path_6 = '\\\\ws1\folder';
my $path_7 = '\\\\ws1\folder\\';
my $path_8 = '\\\\ws1\folder\file.txt';

for my $var ($path_1, $path_2, $path_3) {
	for my $sub (qw(catdir catfile devnull catpath abs2rel rel2abs)) {
		my $result_1 = dumped (File::Spec->$sub($var));
		my $result_2 = dumped do {
			no strict 'refs';
			&{$sub}($var);
		};
		is $result_1, $result_2, "Same return for $sub in File::Spec and Perlmazing with argument $var";
	}
}

is dumped (splitdir $path_1), '("", "usr", "bin", "perl")', 'Unix-style path splitdir OK';
is dumped (splitdir $path_2), '("C:", "Windows", "System32", "")', 'Windows-style path splitdir OK';
is dumped (splitdir $path_3), '("C:", "Windows", "System32")', 'Windows-style path 2 splitdir OK';
is dumped (splitdir $path_4), '"\\\\\\\\ws1"', 'UNC 1 splitdir OK';
is dumped (splitdir $path_5), q[("\\\\\\\\ws1", "")], 'UNC 2 splitdir OK';
is dumped (splitdir $path_6), q[("\\\\\\\\ws1", "folder")], 'UNC 3 splitdir OK';
is dumped (splitdir $path_7), q[("\\\\\\\\ws1", "folder", "")], 'UNC 4 splitdir OK';
is dumped (splitdir $path_8), q[("\\\\\\\\ws1", "folder", "file.txt")], 'UNC 5 splitdir OK';


my @splitdir_1 = splitdir $path_1;
my @splitdir_2 = splitdir $path_2;
my @splitdir_3 = splitdir $path_3;
my @splitdir_4 = splitdir $path_4;
my @splitdir_5 = splitdir $path_5;
my @splitdir_6 = splitdir $path_6;
my @splitdir_7 = splitdir $path_7;
my @splitdir_8 = splitdir $path_8;

my @splitpath_1 = splitpath $path_1;
my @splitpath_2 = splitpath $path_2;
my @splitpath_3 = splitpath $path_3;
my @splitpath_4 = splitpath $path_4;
my @splitpath_5 = splitpath $path_5;
my @splitpath_6 = splitpath $path_6;
my @splitpath_7 = splitpath $path_7;
my @splitpath_8 = splitpath $path_8;

is join(',', @splitdir_1), ',usr,bin,perl', 'Unix-style splitdir OK';
is join(',', @splitdir_2), 'C:,Windows,System32,', 'Windows-style splitdir OK';
is join(',', @splitdir_3), 'C:,Windows,System32', 'Windows-style 2 splitdir OK';
is join(',', @splitdir_4), '\\\\ws1', 'UNC splitdir 1 OK';
is join(',', @splitdir_5), '\\\\ws1,', 'UNC splitdir 2 OK';
is join(',', @splitdir_6), '\\\\ws1,folder', 'UNC splitdir 3 OK';
is join(',', @splitdir_7), '\\\\ws1,folder,', 'UNC splitdir 4 OK';
is join(',', @splitdir_8), '\\\\ws1,folder,file.txt', 'UNC splitdir 5 OK';

is join(',', @splitpath_1), ',/usr/bin/,perl', 'Unix-style splitpath OK';
is join(',', @splitpath_2), 'C:,\Windows\System32\,', 'Windows-style splitpath OK';
is join(',', @splitpath_3), 'C:,\Windows\,System32', 'Windows-style 2 splitpath OK';
is join(',', @splitpath_4), '\\\\ws1,,', 'UNC splitpath 1 OK';
is join(',', @splitpath_5), '\\\\ws1,\,', 'UNC splitpath 2 OK';
is join(',', @splitpath_6), '\\\\ws1,\,folder', 'UNC splitpath 3 OK';
is join(',', @splitpath_7), '\\\\ws1,\folder\,', 'UNC splitpath 4 OK';
is join(',', @splitpath_8), '\\\\ws1,\folder\,file.txt', 'UNC splitpath 5 OK';

