#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

$vim->command ('new');

my $buffer = tied (@{$vim->current->buffer});
is $buffer->name, '';

my $new_name = $vim->eval ('resolve(tempname())');
$buffer->name ($new_name);

$vim->command ('silent w!');
ok -f $new_name;
unlink $new_name;

done_testing();
