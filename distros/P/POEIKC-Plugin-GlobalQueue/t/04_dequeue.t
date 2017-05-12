use strict;
use Data::Dumper;
use Test::More;
#use Test::More qw(no_plan);

eval q{ use POEIKC::Daemon };
plan skip_all => "POEIKC::Daemon is not installed." if $@;

my $path = `poeikcd -v`;
plan skip_all => "poeikcd is not installed." if $path !~ /poeikcd version/ ;

plan tests => 11;


use POEIKC::Plugin::GlobalQueue::Message;
use POEIKC::Plugin::GlobalQueue::ClientLite;

my $cmd;

$cmd = `poeikcd start -I=lib -M=POEIKC::Plugin::GlobalQueue -n=GlobalQueue -a=QueueServer -p=47301 -s`;
ok $cmd =~ /Started/, $cmd;
sleep 1;

my $gq = POEIKC::Plugin::GlobalQueue::ClientLite->new(port=>47301);
ok $gq, Dumper($gq);

my $re;
$re = $gq->enqueue(POEIKC::Plugin::GlobalQueue::Message->new({AAA=>'aaa',BBB=>'bbb',},tag=>'tagName1',));
$re = $gq->enqueue(POEIKC::Plugin::GlobalQueue::Message->new({CCC=>'ccc',DDD=>'ddd',},tag=>'tagName1',));
$re = $gq->enqueue(POEIKC::Plugin::GlobalQueue::Message->new({EEE=>'eee',FFF=>'fff',},tag=>'tagName1',));
$re = $gq->enqueue(POEIKC::Plugin::GlobalQueue::Message->new({IROHA=>'iroha',AIU=>'AIU',},tag=>'tagName2',));

$cmd = `poikc  --alias=QueueServer --port=47301 GlobalQueue length`;
ok $cmd, ($cmd);

my $le = $gq->length();
ok $le, Dumper($le);

$le = $gq->length('tagName1');
is $le, 3, q/gq->length('tagName1')/;

$cmd = `poikc  --alias=QueueServer --port=47301 GlobalQueue dequeue tagName1 1`;
ok $cmd, ($cmd);
#$cmd = eval "$cmd";
#ok $cmd, Dumper($cmd);

$le = $gq->length('tagName1');
is $le, 2, q/gq->length('tagName1')/;

my $de = $gq->dequeue('tagName1',1);
ok $de, Dumper($de);

$le = $gq->length('tagName1');
is $le, 1, q/gq->length('tagName1')/;

$cmd = `poikc  --alias=QueueServer --port=47301 GlobalQueue length`;
ok $cmd, ($cmd);

$cmd = `poeikcd stop -a=QueueServer -p=47301`;
ok $cmd =~ /stopped/, $cmd;

