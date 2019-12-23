#!perl

use lib '.', 't/';
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

is $vim->command_output('echo "test"'), 'test';

done_testing();
