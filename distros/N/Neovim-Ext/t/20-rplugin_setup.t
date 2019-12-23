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

if (!-f 't/rplugin.vim')
{
	$vim->command ('UpdateRemotePlugins');
}

ok -f 't/rplugin.vim';

done_testing();

