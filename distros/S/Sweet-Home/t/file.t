use utf8;
use strict;
use warnings;

use Test::More tests => 26;

use File::Spec::Functions;
use File::Temp qw(tempdir);
use Sweet::Dir;

use Sweet::File;

my $test_dir = Sweet::Dir->new( path => 't' );

my $file = Sweet::File->new( name => 'file.t', dir => $test_dir );
ok $file->is_a_plain_file, 'is_a_plain_file';
ok $file->is_writable, 'is_writable';


is "$file", catfile( 't', 'file.t' ), 'stringify to path';

is $file->path, catfile( 't', 'file.t' ), 'path';
is $file->extension, 't', 'extension';
is $file->name_without_extension, 'file', 'name_without_extension';

my $file_touched = Sweet::File->new( name => 'file_touched', dir => $test_dir );
ok $file_touched->does_not_exists, 'touched file does not exists yet';
is $file_touched->encoding, 'utf8', 'default encoding';

my $file_that_do_not_exists = $test_dir->file('file_that_do_not_exists');
ok $file_that_do_not_exists->does_not_exists, 'file does not exists';

my $empty_file = $test_dir->file('empty_file');
ok $empty_file->has_zero_size, 'empty file has zero size';

my $file1 = Sweet::File->new(
    name => 'file1.txt',
    dir => $test_dir,
);
my @file1_lines = ( 'Hi,', 'I am a text file.' );

is $file1->num_lines, 2, 'num_lines';
my @got_lines = $file1->lines;
is_deeply \@got_lines, \@file1_lines, 'lines';
is $file1->line(0), $file1_lines[0], 'line(0)';
is $file1->line(1), $file1_lines[1], 'line(1)';

my @got_split_line1 = $file1->split_line->('a')->(1);
my @expected_split_line1 = ('I ', 'm ', ' text file.');
is_deeply \@got_split_line1, \@expected_split_line1,'split_line';

my $file_from_path = Sweet::File->new(path=>'t/file.t');
is $file_from_path->name, 'file.t', 'name from path';
is $file_from_path->dir->path, 't', 'dir from path';

my $utf8 = Sweet::File->new(path=>'t/utf8.txt');
is $utf8->line(0), '£¥€$', 'read utf8';

my $temp_path = tempdir();
my $temp_dir = Sweet::Dir->new( path => $temp_path )->create;

my $copied_file = $file->copy_to_dir($temp_dir);
ok $copied_file->is_a_plain_file, 'copy_to_dir';

my $copied_file1 = $file1->copy_to_dir($temp_path);
ok $copied_file1->is_a_plain_file, 'copy_to_dir coerces Str to Sweet::Dir';

my $copied_file2 = $file1->copy_to_dir([$temp_path, 'foo']);
ok $copied_file2->is_a_plain_file, 'copy_to_dir coerces ArrayRef to Sweet::Dir';

my $copied_file3 = $file->copy_to_dir($temp_dir->sub_dir('bar'));
ok $copied_file3->is_a_plain_file, 'copy_to_dir creates target dir';

my $brand_new_file1 = Sweet::File->new(
    name => 'brand_new_file1.txt',
    dir => $temp_dir,
    lines => \@file1_lines,
);
my @got_lines_in_brand_new_file1 = $brand_new_file1->lines;
is_deeply \@got_lines_in_brand_new_file1, \@file1_lines, 'lines as constructor argument';

$brand_new_file1->write;
ok $brand_new_file1->is_a_plain_file, 'write';

my @appended_lines = ('first appended line', 'second appended line');

$brand_new_file1->append(\@appended_lines);

# Create other instance of brand_new_file1.
my $new_file1 = Sweet::File->new(
  dir => $brand_new_file1->dir,
  name => $brand_new_file1->name,
);

my @got_lines_in_new_file1 = $new_file1->lines;
my @expected_lines_in_new_file1;
push @expected_lines_in_new_file1, @file1_lines;
push @expected_lines_in_new_file1, @appended_lines;
is_deeply \@got_lines_in_new_file1, \@expected_lines_in_new_file1, 'append';

my $expected_num_lines_in_new_file1 = scalar(@file1_lines) + scalar(@appended_lines);
is $brand_new_file1->num_lines, $expected_num_lines_in_new_file1, 'append updates lines';

