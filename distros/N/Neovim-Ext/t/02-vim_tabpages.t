#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

is scalar (@{$vim->tabpages}), 1;
ok $vim->current->tabpage == $vim->tabpages->[0];

$vim->command ('tabnew');
is scalar (@{$vim->tabpages}), 2;
is scalar (@{$vim->windows}), 2;
ok $vim->windows->[1] == $vim->current->window;
ok $vim->tabpages->[1] == $vim->current->tabpage;
$vim->current->window ($vim->windows->[0]);

ok $vim->current->tabpage == $vim->tabpages->[0];
ok $vim->current->window == $vim->windows->[0];
$vim->current->tabpage ($vim->tabpages->[1]);
ok $vim->current->tabpage == $vim->tabpages->[1];
ok $vim->current->window == $vim->windows->[1];

done_testing();
