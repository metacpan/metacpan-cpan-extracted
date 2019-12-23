#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();


sub source
{
	my ($vim, $code) = @_;

	my ($fh, $filename) = tempfile();

	print $fh $code;
	close $fh;

	$vim->command ("source $filename");
	unlink $filename;
}

is $vim->funcs->join (['first', 'last'], ', '), 'first, last';

source ($vim, q/
        function! Testfun(a,b)
            return string(a:a).":".a:b
        endfunction
	/);

is $vim->funcs->Testfun (3, 'alpha'), '3:alpha';

done_testing();
