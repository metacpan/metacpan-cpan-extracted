#!perl

use Test::More;
use lib '.', 't/';
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

$vim->current->window->vars->{perl} = [1, 2, {'test' => 1}];
is_deeply $vim->current->window->vars->{perl}, [1, 2, {'test' => 1}];
is_deeply tied (%{$vim->current->window->vars})->fetch ('perl'), [1, 2, {'test' => 1}];
is_deeply $vim->eval ('w:perl'), [1, 2, {'test' => 1}];
is_deeply delete $vim->current->window->vars->{perl}, [1, 2, {'test' => 1}];

ok (!eval {delete $vim->current->window->vars->{perl}});
is tied (%{$vim->current->window->vars})->fetch ('perl', 'default'), 'default';

done_testing();
