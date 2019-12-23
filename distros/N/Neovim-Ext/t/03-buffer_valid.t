#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

$vim->command ('new');

my $buffer = tied (@{$vim->current->buffer});
ok $buffer->valid;

$vim->command ('bw!');
ok (!$buffer->valid);

done_testing();

