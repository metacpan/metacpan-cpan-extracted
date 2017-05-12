use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;
use Perlmazing;
use File::Spec;

my $dir = 'mkdir_test_dir_'.time;
my $subdir = File::Spec->catdir($dir, 'another_one');
CORE::mkdir($dir) or die "Cannot create $dir: $!";
CORE::mkdir(File::Spec->catdir($dir, 'another_one')) or die "Cannot create $subdir: $!";

is ((-e $dir), 1, "$dir created");
is ((-e $subdir), 1, "$subdir created");
is rmdir($dir), 2, 'return value correct';
is ((-e $subdir), undef, "$subdir doesn't exist");
is ((-e $dir), undef, "$dir removed");
