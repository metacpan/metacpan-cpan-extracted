#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

my $buffer = $vim->current->buffer;
push @$buffer, 'a';
is_deeply $buffer, ['', 'a'];
unshift @$buffer, 'b';
is_deeply $buffer, ['b', '', 'a'];
push @$buffer, 'c', 'd';
is_deeply $buffer, ['b', '', 'a', 'c', 'd'];

done_testing();
