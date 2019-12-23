#!perl

use lib '.', 't/';
use File::Spec::Functions qw/rel2abs/;
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

my $vim = $tester->start();

ok -f 't/rplugin.vim';

is $vim->call ('TestFunction'), 'hello!';
ok (!eval {$vim->call ('TestFunctionToBeDeleted')});

done_testing();

