#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

push @{$vim->current->buffer}, 'a', 'bit of', 'text';
$vim->current->window->cursor ([3, 4]);
$vim->command ('mark V');

is_deeply tied (@{$vim->current->buffer})->mark ('V'), [3, 0];

done_testing();

