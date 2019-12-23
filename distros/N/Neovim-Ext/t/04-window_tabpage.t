#!perl

use Test::More;
use lib '.', 't/';
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

$vim->command ('tabnew');
$vim->command ('vsplit');
ok $vim->windows->[0]->tabpage == $vim->tabpages->[0];
ok $vim->windows->[1]->tabpage == $vim->tabpages->[1];
ok $vim->windows->[2]->tabpage == $vim->tabpages->[1];

done_testing();
