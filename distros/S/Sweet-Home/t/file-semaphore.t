use strict;
use warnings;

use Test::More tests => 3;

use File::Spec::Functions;
use File::Temp qw(tempdir);
use Sweet::Dir;
use Sweet::File;
use Sweet::File::Semaphore;

my $test_dir = Sweet::Dir->new(path => 't');

my $file = Sweet::File->new(
    name => 'file1.txt',
    dir  => $test_dir
);

my $temp_path = tempdir();
my $temp = Sweet::Dir->new(path => $temp_path)->create;

my $file1 = $file->copy_to_dir($temp);

my $semaphore1 = Sweet::File::Semaphore->new(linked_file => $file1);
my $semaphore1_path = $file1->path . '.ok';

is $semaphore1->path, $semaphore1_path, 'defaults to /path/to/file.ext.ok';
ok $semaphore1->does_not_exists, 'semaphore not created on instance';
$semaphore1->write;
ok $semaphore1->is_a_plain_file, 'write';

