#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

is scalar (@{$vim->current->buffer}), 1;
push @{$vim->current->buffer}, 'line';
is scalar (@{$vim->current->buffer}), 2;
push @{$vim->current->buffer}, 'line';
is scalar (@{$vim->current->buffer}), 3;
pop (@{$vim->current->buffer});
is scalar (@{$vim->current->buffer}), 2;
$vim->current->buffer->[-1] = undef;
$vim->current->buffer->[-1] = undef;

# There's always at least one line
is scalar (@{$vim->current->buffer}), 1;

done_testing();
