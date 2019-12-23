#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

my $buffer = tied (@{$vim->current->buffer});

$buffer->api->set_var ('myvar', 'thetext');
is $buffer->api->get_var ('myvar'), 'thetext';
is $vim->eval ('b:myvar'), 'thetext';

$buffer->api->set_lines (0, -1, 1, ['alpha', 'beta']);
is_deeply $buffer->api->get_lines (0, -1, 1), ['alpha', 'beta'];
is_deeply [@{$vim->current->buffer}], ['alpha', 'beta'];

done_testing();
