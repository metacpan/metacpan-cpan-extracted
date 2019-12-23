#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

is $vim->options->{background}, 'dark';
$vim->options->{background} = 'light';
is $vim->options->{background}, 'light';

done_testing();
