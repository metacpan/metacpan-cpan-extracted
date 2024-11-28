use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 13;
use Perlmazing qw(catdir copy);
use File::Spec;

my $dir = 'mkdir_test_dir_'.time;
my $subdir = catdir $dir, 'another_one';
CORE::mkdir($dir) or die "Cannot create $dir: $!";
CORE::mkdir($subdir) or die "Cannot create $subdir: $!";

# We need to also test the behavior with symlinks, which should not remove contents,
# just the symlink. So we create a separate directory with some contents, which we
# will symlink to later.

my $dir_2 = "${dir}_2";
CORE::mkdir($dir_2) or die "Cannot create $dir_2: $!";
my $file = catdir $dir_2, 'some_file';
open my $out, '>', $file or die "Can't create $file: $!";
print $out "Hello world!";
close $out;
my $subdir_2 = catdir $dir_2, 'some_subdir';
CORE::mkdir($subdir_2) or die "Cannot create $subdir_2: $!";
my $symlink = 'symlink';
chdir $dir;
unless (symlink catdir('..', $dir_2), $symlink) {
  warn "Cannot create '$symlink' as a symlink: $!";
  copy(catdir('..', $dir_2), $symlink) or die "Cannot create '$symlink' as a copy: $!";
}
chdir '..';

is ((-e $dir), 1, "$dir created");
is ((-e $subdir), 1, "$subdir created");
my $symlinked_folder = catdir $dir, $symlink;
is -e $symlinked_folder, 1, "Symlinked folder exists";
my $symlinked_file = catdir $dir, $symlink, 'some_file';
is (-f $symlinked_file, 1, "File in symlink exists");
{
    open my $in, '<', $symlinked_file;
    my $data = <$in>;
    close $in;
    is $data, 'Hello world!', "Data in symlinked file looks good";
}
is rmdir($dir), 1, 'return value correct';
is -d $dir_2, 1, "Symlinked dir still exists";
is -d $subdir_2, 1, "Subdirectory in symlinked dir still exists";
is -f $file, 1, "File in symlinked dir still exists";
{
    open my $in, '<', $file or next;
    my $data = <$in>;
    close $in;
    is $data, 'Hello world!', "Data in original symlinked file still looks good";
}
is ((-e $subdir), undef, "$subdir doesn't exist");
is ((-e catdir $dir, $symlink), undef, "Symlink was removed");
is ((-e $dir), undef, "$dir removed");
rmdir $dir_2;
