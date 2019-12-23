#!perl

use Test::More;
use lib '.', 't/';
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

my $height = $vim->windows->[0]->height;
my $width = $vim->windows->[0]->width;
my $vsplit_pos = $width/2;
my $split_pos = $height/2;

$vim->command ('split');
$vim->command ('vsplit');
is $vim->windows->[0]->row, 0;
is $vim->windows->[0]->col, 0;
is $vim->windows->[1]->row, 0;

ok $vsplit_pos - 1 <= $vim->windows->[1]->col;
ok $vim->windows->[1]->col <= $vsplit_pos + 1;

ok $split_pos - 1 <= $vim->windows->[2]->row;
ok $vim->windows->[2]->row <= $split_pos + 1;

is $vim->windows->[2]->col, 0;

done_testing();
