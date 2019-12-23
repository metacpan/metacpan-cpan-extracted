#!perl

use Test::More;
use lib '.', 't/';
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

$vim->current->window->options->{colorcolumn} = '4,3';
is $vim->current->window->options->{colorcolumn}, '4,3';
# global-local option
$vim->current->window->options->{statusline} = 'window-status';
is $vim->current->window->options->{statusline}, 'window-status';
is $vim->options->{statusline}, undef;

ok (!eval {$vim->current->window->options->{doesnotexist}});

done_testing();
