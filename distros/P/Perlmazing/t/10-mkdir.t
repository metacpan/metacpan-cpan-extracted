use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 3;
use Perlmazing;
use File::Spec;

my $dir = 'mkdir_test_directory';

if (-e $dir) {
	rmdir $dir;
	die "Cannot rmdir $dir: $!" if -e $dir;
}

is ((-e $dir), undef, "$dir doesn't exist");

mkdir File::Spec->catdir(qw(mkdir_test one two three));
my $content = join "\n", dir 'mkdir_test', 1;

my $should_be = '';
$should_be .= File::Spec->catdir(qw(mkdir_test one))."\n";
$should_be .= File::Spec->catdir(qw(mkdir_test one two))."\n";
$should_be .= File::Spec->catdir(qw(mkdir_test one two three));

is $content, $should_be, 'directories created succesfully';

if (-e $dir) {
	rmdir $dir;
	die "Cannot rmdir $dir: $!" if -e $dir;
}

is ((-e $dir), undef, "$dir deleted successfully");