use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 3;
use Perlmazing;
use File::Spec;

my $path;
if (-d 't') {
	$path = File::Spec->catdir(qw(t test_dir));
} elsif (-d 'test_dir') {
	$path = 'test_dir';
} else {
	die 'Cannot find '.File::Spec->catdir(qw(t test_dir)).' nor test_dir in the current path, aborting test';
}

my $path2 = "${path}_2";
copy $path, $path2;
empty_dir $path2;
is -d $path2, 1, 'directory exists';

my @dir = dir $path2, 1;
is scalar(@dir), 0, 'directory is empty';

rmdir $path2;
is -e $path2, undef, 'directory is gone';