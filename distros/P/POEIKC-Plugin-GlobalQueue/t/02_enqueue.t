use strict;
use Data::Dumper;
use Test::More;
#use Test::More qw(no_plan);

eval q{ use POEIKC::Daemon };
plan skip_all => "POEIKC::Daemon is not installed." if $@;

my $path = `poeikcd -v`;
plan skip_all => "poeikcd is not installed." if $path !~ /poeikcd version/ ;

plan tests => 5;


use POEIKC::Plugin::GlobalQueue::Message;
use POEIKC::Plugin::GlobalQueue::ClientLite;

my $cmd = `poeikcd start -I=lib -M=POEIKC::Plugin::GlobalQueue -n=GlobalQueue -a=QueueServer -p=47301 -s`;
ok $cmd =~ /Started/, $cmd;
my $substance = {
	AAA=>'aaa',
	BBB=>'bbb',
};
sleep 1;

my $gq = POEIKC::Plugin::GlobalQueue::ClientLite->new(port=>47301);
ok $gq, Dumper($gq);

my $message = POEIKC::Plugin::GlobalQueue::Message->new(
	$substance,
	tag=>'tagName',
	expireTime=>3
);

my $re = $gq->enqueue($message);
ok $re, Dumper($re);

$cmd = `poikc  --alias=QueueServer --port=47301 GlobalQueue dump`;
$cmd = eval "$cmd";
ok keys(%$cmd), Dumper(keys %$cmd);

$cmd = `poeikcd stop -a=QueueServer -p=47301`;
ok $cmd =~ /stopped/, $cmd;

