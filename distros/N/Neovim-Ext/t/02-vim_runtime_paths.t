#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

my $paths1 = $vim->list_runtime_paths();
my $paths2 = [];

$vim->foreach_rtp
(
	sub
	{
		push @$paths2, shift;
		return 1;
	}
);

is_deeply $paths1, $paths2;

$vim->foreach_rtp (sub { die "Boom" });

done_testing();
