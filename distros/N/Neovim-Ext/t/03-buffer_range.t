#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

@{$vim->current->buffer} = ('a', 'b', 'c', 'd', 'e');

my $range = tied (@{$vim->current->buffer})->range (1, 3);
is scalar (@$range), 3;
is $range->[0], 'a';
is $range->[1], 'b';
is $range->[2], 'c';

$range->[1] = "foo";

is_deeply [@{$vim->current->buffer}], ['a', 'foo', 'c', 'd', 'e'];

done_testing();

