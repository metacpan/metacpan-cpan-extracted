#!perl

use lib '.', 't/';
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

ok (!eval {$vim->current->window->cursor (-1, -1)});

done_testing();
