#!perl

use Test::More;
use lib '.', 't/';
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

$vim->command ('vsplit');
is $vim->windows->[1]->height, $vim->windows->[0]->height;
$vim->current->window ($vim->windows->[1]);
$vim->command ('split');
is $vim->windows->[1]->height, $vim->windows->[0]->height / 2;
$vim->windows->[1]->height (2);
is $vim->windows->[1]->height, 2;

done_testing();
