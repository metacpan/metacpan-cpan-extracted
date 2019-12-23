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
	$vim->command ("let g:result = rpcrequest($cid, \"client-call\", 1, 2, 3)");
	is_deeply $vim->vars->{result}, [4, 5, 6];
	$vim->stop_loop();
}

sub request_cb
{
	my ($name, $args) = @_;
	is $name, 'client-call';
	is_deeply $args, [1, 2, 3];
	return [4, 5, 6];
}

$vim->run_loop (\&request_cb, undef, \&setup_cb);

done_testing();

