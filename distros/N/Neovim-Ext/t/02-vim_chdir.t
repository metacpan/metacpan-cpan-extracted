#!perl

use lib '.', 't/';
use File::Spec::Functions qw/rel2abs/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

$vim->chdir (rel2abs ('t'));

ok 1;

done_testing();
