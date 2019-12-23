#!perl

use Test::More;
use lib '.', 't/';
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

# test_buffer
ok tied (@{$vim->current->buffer}) == tied (@{$vim->windows->[0]->buffer});
$vim->command('new');
$vim->current->window ($vim->windows->[1]);
ok tied (@{$vim->current->buffer}) == tied (@{$vim->windows->[1]->buffer});
ok tied (@{$vim->windows->[0]->buffer}) != tied (@{$vim->windows->[1]->buffer});

done_testing();
