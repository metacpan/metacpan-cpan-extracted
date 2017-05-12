use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 3;
use Perlmazing;
use File::Spec;

my $path;
if (-d 't') {
	$path = File::Spec->catdir(qw(t test_dir));
} elsif (-d 'test_dir') {
	$path = 'test_dir';
} else {
	die 'Cannot find '.File::Spec->catdir(qw(t test_dir)).' nor test_dir in the current path, aborting test';
}

my @dir_simple = dir $path;
my @dir_deep = dir $path, 1;
my @callback_result;
dir $path, 1, sub {
	my $item = shift;
	push @callback_result, $item;
};

is scalar @dir_simple, 3, 'simple';
is scalar @dir_deep, 19, 'deep';
is dumped(@dir_deep), dumped(@callback_result), 'callback';
