#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

$vim->vars->{perl} = [1, 2, {'test' => 1}];
is_deeply $vim->vars->{perl}, [1, 2, {'test' => 1}];
is_deeply tied (%{$vim->vars})->fetch ('perl'), [1, 2, {'test' => 1}];
is_deeply $vim->eval ('g:perl'), [1, 2, {'test' => 1}];
is_deeply delete $vim->vars->{perl}, [1, 2, {'test' => 1}];

ok (!eval {delete $vim->vars->{perl}});
is tied (%{$vim->vars})->fetch ('perl', 'default'), 'default';

done_testing();
