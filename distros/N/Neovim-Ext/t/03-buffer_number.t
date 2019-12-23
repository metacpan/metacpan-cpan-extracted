#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

my $buffer = tied (@{$vim->current->buffer});
my $curnum = $buffer->number;

$vim->command ('new');
$buffer = tied (@{$vim->current->buffer});
is $buffer->number, $curnum+1;

$vim->command ('new');
$buffer = tied (@{$vim->current->buffer});
is $buffer->number, $curnum+2;

done_testing();

