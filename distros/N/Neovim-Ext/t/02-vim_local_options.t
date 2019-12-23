#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

is $vim->windows->[0]->options->{foldmethod}, 'manual';
$vim->windows->[0]->options->{foldmethod} = 'syntax';
is $vim->windows->[0]->options->{foldmethod}, 'syntax';

done_testing();
