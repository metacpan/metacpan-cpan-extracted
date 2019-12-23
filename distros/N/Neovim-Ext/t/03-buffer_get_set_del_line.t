#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

is $vim->current->buffer->[0], '';
$vim->current->buffer->[0] = 'line1';
is $vim->current->buffer->[0], 'line1';
$vim->current->buffer->[0] = 'line2';
is $vim->current->buffer->[0], 'line2';
$vim->current->buffer->[0] = undef;
is $vim->current->buffer->[0], '';

@{$vim->current->buffer} = ('line1', 'line2', 'line3');
is $vim->current->buffer->[2], 'line3';
delete $vim->current->buffer->[0];
is $vim->current->buffer->[0], 'line2';
is $vim->current->buffer->[1], 'line3';
delete $vim->current->buffer->[-1];
is $vim->current->buffer->[0], 'line2';
is scalar (@{$vim->current->buffer}), 1;

done_testing();
