#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

my $buffer = tied (@{$vim->current->buffer});

$buffer->vars->{perl} = [1, 2, {'test' => 1}];
is_deeply $buffer->vars->{perl}, [1, 2, {'test' => 1}];
is_deeply tied (%{$buffer->vars})->fetch ('perl'), [1, 2, {'test' => 1}];
is_deeply $vim->eval ('b:perl'), [1, 2, {'test' => 1}];
is_deeply delete $buffer->vars->{perl}, [1, 2, {'test' => 1}];
is $vim->eval ('exists("b:perl")'), 0;
ok (!exists ($buffer->vars->{perl}));

is tied (%{$buffer->vars})->fetch ('perl', 'default'), 'default';

done_testing();
