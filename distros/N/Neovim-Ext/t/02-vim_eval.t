#!perl

use lib '.', 't/';
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

$vim->command('let g:v1 = "a"');
$vim->command('let g:v2 = [1, 2, {"v3": 3}]');
my $g = $vim->eval('g:');
is $g->{v1}, 'a';
is_deeply $g->{v2}, [1, 2, {v3 => 3}];

done_testing();
