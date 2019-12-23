#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

is $vim->current->line, '';
$vim->current->line ('abc');
is $vim->current->line, 'abc';

done_testing();
