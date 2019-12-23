#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

my $cid = $vim->channel_id;

sub setup_cb
{
	$vim->vars->{result1} = 0;
	$vim->vars->{result2} = 0;
	$vim->vars->{result3} = 0;
	$vim->vars->{result4} = 0;
	$vim->command ("let g:result1 = rpcrequest($cid, \"call\", 2)");
	is $vim->vars->{result1}, 4;
	is $vim->vars->{result2}, 8;
	is $vim->vars->{result3}, 16;
	is $vim->vars->{result4}, 32;
	$vim->stop_loop();
}

sub request_cb
{
	my ($name, $args) = @_;

	my $n = $args->[0];
	$n *= 2;

	if ($n <= 16)
	{
		if ($n == 4)
		{
			$vim->command ("let g:result2 = rpcrequest($cid, \"call\", $n)");
		}
		elsif ($n == 8)
		{
			$vim->command ("let g:result3 = rpcrequest($cid, \"call\", $n)");
		}
		elsif ($n == 16)
		{
			$vim->command ("let g:result4 = rpcrequest($cid, \"call\", $n)");
		}
	}

	return $n;
}

$vim->run_loop (\&request_cb, undef, \&setup_cb);

done_testing();

