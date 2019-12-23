#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

$vim->api->command ('let g:var = 3');
is $vim->api->eval ('g:var'), 3;

$vim->out_write ('hello!');

done_testing();
