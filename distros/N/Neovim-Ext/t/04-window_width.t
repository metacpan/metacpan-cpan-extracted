#!perl

use Test::More;
use lib '.', 't/';
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

$vim->command ('split');
is $vim->windows->[1]->width, $vim->windows->[0]->width;
$vim->current->window ($vim->windows->[1]);
$vim->command ('vsplit');
is $vim->windows->[1]->width, $vim->windows->[0]->width / 2;
$vim->windows->[1]->width (2);
is $vim->windows->[1]->width, 2;

done_testing();
