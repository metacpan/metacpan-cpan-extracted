#!perl

use Test::More;
use lib '.', 't/';
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

$vim->command ('split');
my $window = $vim->windows->[1];

$vim->current->window ($window);
ok $window->valid;
$vim->command ('q');
ok !$window->valid;

done_testing();
