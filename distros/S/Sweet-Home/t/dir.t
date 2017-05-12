use strict;
use warnings;

use Test::More tests => 9;

use File::Temp qw(tempdir);
use Sweet::Dir;
use Sweet::File::CSV;

my $test_dir = Sweet::Dir->new( path => 't' );

ok $test_dir->is_a_directory, 't/ is a directory';

my $sub_dir1 = $test_dir->sub_dir( 'foo', 'bar' );
my $sub_dir2 = $test_dir->sub_dir( [ 'foo', 'bar' ] );

my $dir1 = $test_dir->sub_dir('dir1');

is $sub_dir1->path, $sub_dir2->path, "both sub_dir('foo','bar') and sub_dir(['foo','bar']) work";

my $file = $test_dir->file('file');
isa_ok $file , 'Sweet::File';
ok $file->does_not_exists, 'file() returns a reference to a file without creating it';

my $file2 = $test_dir->file('file', sub {
        my ( $dir, $name ) = @_;

        my $file = Sweet::File::CSV->new(
            dir       => $dir,
            name      => $name,
        );

        return $file;
});
isa_ok $file2, 'Sweet::File::CSV', 'file() accepts an optional reference to a sub builder';

my $temp_dir = Sweet::Dir->new( path => tempdir() )->sub_dir('created');
ok $temp_dir->does_not_exists, 'to be created dir does not exists';
$temp_dir->create;
ok $temp_dir->is_a_directory, 'created dir now exists';

my @expected_files1 = sort qw(file1.csv  file1.dat  file1.txt file2 file2.ext);
my @got_files1 = sort $dir1->file_list;
is_deeply \@got_files1, \@expected_files1, 'file_list';

my @expected_files2 = sort qw(file1.csv  file1.dat  file1.txt);
my @got_files2 = sort $test_dir->file_list('file\d\.\w\w\w');
is_deeply \@got_files2, \@expected_files2, 'file_list(regexp)';

