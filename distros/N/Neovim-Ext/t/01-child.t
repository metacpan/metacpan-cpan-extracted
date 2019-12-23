#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

if ($^O eq 'MSWin32')
{
	diag ("Not availabe");
	ok 1;
	done_testing();
	exit 0;
}


my $tester = TestNvim->new;
my $vim = $tester->start_child();

$vim->api->command ('let g:var = 3');
is $vim->api->eval ('g:var'), 3;

$vim->quit;

done_testing();
