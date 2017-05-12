use strict;
use warnings;

use Test::More tests => 8;

use Sweet::Dir;
use Sweet::File::DSV;

my $test_dir = Sweet::Dir->new( path => 't' );

my $file1 = Sweet::File::DSV->new(
    name      => 'file1.dat',
    dir       => $test_dir,
    separator => '|',
);

my @file1_fields = ('FIELD_A', 'FIELD_B');
my @file1_rows   = ('foo|bar', '2|3');
my @file1_cells = (['foo', 'bar'], ['2', '3']);

is $file1->header, 'FIELD_A|FIELD_B', 'header';

my @got_rows = $file1->rows;
is_deeply \@got_rows, \@file1_rows, 'rows';

is $file1->num_rows,scalar(@file1_rows);

my @got_fields = $file1->fields;
is_deeply \@got_fields, \@file1_fields, 'fields';

is $file1->field(0), $file1_fields[0], 'field(0)';
is $file1->field(1), $file1_fields[1], 'field(1)';

my @got_cells1 = $file1->split_row->(0);
my @got_cells2 = $file1->split_row->(1);

is_deeply \@got_cells1, $file1_cells[0], 'split_row 1';
is_deeply \@got_cells2, $file1_cells[1], 'split_row 2';

