#!perl

use Test::More;
use lib '.', 't/';
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

my $hnd1 = $vim->current->window->handle;
$vim->command ('bot split');
my $hnd2 = $vim->current->window->handle;
isnt $hnd1, $hnd2;
$vim->command ('bot split');
my $hnd3 = $vim->current->window->handle;
isnt $hnd1, $hnd3;
isnt $hnd2, $hnd3;
$vim->command ('wincmd w');
is $vim->current->window->handle, $hnd1;

done_testing();
