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
	$vim->command ("let g:result = rpcrequest($cid, \"client-call2\", 1, 2, 3)");
	is_deeply $vim->vars->{result}, [7, 8, 9];
	$vim->stop_loop();
}

sub request_cb
{
	my ($name, $args) = @_;
	$vim->command ('let g:result2 = [7, 8, 9]');
	return $vim->vars->{result2};
}

$vim->run_loop (\&request_cb, undef, \&setup_cb);

done_testing();

