#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

is scalar (@{$vim->windows}), 1;
ok $vim->windows->[0] == $vim->current->window;

$vim->command ('vsplit');
$vim->command ('split');
is scalar (@{$vim->windows}), 3;
ok $vim->windows->[0] == $vim->current->window;
$vim->current->window ($vim->windows->[1]);
ok $vim->windows->[1] == $vim->current->window;

done_testing();

