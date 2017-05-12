use strict;
use warnings;

use Test::More tests => 8;

use File::Temp qw(tempdir);
use Sweet::Dir;
use Sweet::File::CSV;

my $test_dir = Sweet::Dir->new(path => 't');

my $temp_path = tempdir();
my $temp_dir = Sweet::Dir->new(path => $temp_path)->create;

my $file1 = Sweet::File::CSV->new(
    name => 'file1.csv',
    dir  => $test_dir,
);

is $file1->separator, ',', 'separator';

my @file1_rows   = ('1,2',    '3,4');
my @file1_fields = ('FIELDA', 'FIELDB');

is $file1->header, 'FIELDA,FIELDB', 'header';

my @got_rows = $file1->rows;
is_deeply \@got_rows, \@file1_rows, 'rows';

my @got_fields = $file1->fields;
is_deeply \@got_fields, \@file1_fields, 'fields';

is $file1->field(0), $file1_fields[0], 'field(0)';
is $file1->field(1), $file1_fields[1], 'field(1)';

my @file2_fields = qw(Name Age);
my $file2        = Sweet::File::CSV->new(
    name   => 'file_that_does_not_exists.csv',
    dir    => $temp_dir,
    fields => \@file2_fields,
);

my @got_fields2 = $file2->fields;
is_deeply \@got_fields2, \@file2_fields, 'fields from init_arg';
is $file2->header, join(',', @file2_fields), 'header from fields';

