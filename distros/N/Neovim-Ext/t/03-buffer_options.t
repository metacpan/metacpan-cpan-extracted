#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

my $buffer = tied (@{$vim->current->buffer});
is $buffer->options->{shiftwidth}, 8;
$buffer->options->{shiftwidth} = 4;
is $buffer->options->{shiftwidth}, 4;

$buffer->options->{define} = 'test';
is $buffer->options->{define}, 'test';

isnt $buffer->options->{define}, $vim->options->{define};

ok (!eval {$buffer->options->{doestnoexist}});

done_testing();

