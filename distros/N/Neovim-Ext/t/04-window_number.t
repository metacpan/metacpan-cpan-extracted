#!perl

use Test::More;
use lib '.', 't/';
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

my $curnum = $vim->current->window->number;
$vim->command('bot split');
is $vim->current->window->number, $curnum+1;
$vim->command('bot split');
is $vim->current->window->number, $curnum+2;

done_testing();
