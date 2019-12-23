#!perl

use Test::More;
use lib '.', 't/';
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

# test_buffer
is_deeply $vim->current->window->cursor, [1, 0];
$vim->command ("normal ityping\033o  some text");
# TODO: check buffer lines

is_deeply $vim->current->window->cursor, [2, 10];
$vim->current->window->cursor ([2, 6]);
$vim->command ("normal i dumb");
# TODO: check buffer lines

done_testing();
