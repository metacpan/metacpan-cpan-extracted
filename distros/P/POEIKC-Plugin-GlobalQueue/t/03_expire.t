use strict;
use Data::Dumper;
use Test::More;
#use Test::More qw(no_plan);

eval q{ use POEIKC::Daemon };
plan skip_all => "POEIKC::Daemon is not installed." if $@;

my $path = `poeikcd -v`;
plan skip_all => "poeikcd is not installed." if $path !~ /poeikcd version/ ;

plan tests => 7;


use POEIKC::Plugin::GlobalQueue::Message;
use POEIKC::Plugin::GlobalQueue::ClientLite;

my $cmd = `poeikcd start -I=lib -M=POEIKC::Plugin::GlobalQueue -n=GlobalQueue -a=QueueServer -p=47301 -s`;
ok $cmd =~ /Started/, $cmd;
my $substance = {
	AAA=>'aaa',
	BBB=>'bbb',
};
sleep 1;

$cmd = `poikc  --alias=QueueServer --port=47301 GlobalQueue conf globalQueueClean 2`;
is $cmd, 2, Dumper($cmd);


my $message = POEIKC::Plugin::GlobalQueue::Message->new(
	$substance,
	tag=>'tagName',
	expireTime=>2
);

my $gq = POEIKC::Plugin::GlobalQueue::ClientLite->new(port=>47301);
ok $gq, Dumper($gq);

my $re = $gq->enqueue($message);
ok $re, Dumper($re);

$cmd = `poikc  --alias=QueueServer --port=47301 GlobalQueue dump`;
#ok $cmd, $cmd;
$cmd = eval "$cmd";
ok $cmd->{tagName}->[0], Dumper($cmd->{tagName}->[0]);

sleep_print(5);

$cmd = `poikc  --alias=QueueServer --port=47301 GlobalQueue dump`;
#ok $cmd, $cmd;
$cmd = eval "$cmd";
ok not($cmd->{tagName}->[0]), Dumper($cmd->{tagName}->[0]);



### stopped

$cmd = `poeikcd stop -a=QueueServer -p=47301`;
ok $cmd =~ /stopped/, $cmd;

sub sleep_print {
	my $s = shift;
	my $c = 0;
	printf "sleep %d; ", $s;
	for ( 1 .. $s ) {
		$c++;
		sleep 1;
		$c =~ /\d$/;
		print $& == 0 ? ',' : '.';
	}
	print "\n";
}
