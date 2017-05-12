use strict;
use Data::Dumper;
use Test::More;
#use Test::More qw(no_plan);

eval q{ use POEIKC::Daemon };
plan skip_all => "POEIKC::Daemon is not installed." if $@;

my $path = `poeikcd -v`;
plan skip_all => "poeikcd is not installed." if $path !~ /poeikcd version/ ;

plan tests => 13;


use POEIKC::Plugin::GlobalQueue::Message;

my $substance = {
	AAA=>'aaa',
	BBB=>'bbb',
};

my $message = POEIKC::Plugin::GlobalQueue::Message->new(
	$substance,
	tag=>'tagName',
	expireTime=>3
);

ok $message, Dumper($message);
is $message->substance->{AAA}, 'aaa', Dumper($message->substance);

sleep 1;

$message = POEIKC::Plugin::GlobalQueue::Message->new(
	undef, %{$message},
	gqId=>123,
	);

ok $message, Dumper($message);
is $message->substance->{AAA}, 'aaa', Dumper($message->substance);

ok $message->createTime, '$message->createTime';
ok $message->expireTime, '$message->expireTime';
ok $message->createTime > (time-$message->expireTime);

my @list;
push @list, $message->expire;
ok @list;
@list = ();
ok $message->expire, $message->expire;
sleep 2;
ok not $message->expire, $message->expire;
push @list, $message->expire;
ok not @list;

$message = POEIKC::Plugin::GlobalQueue::Message->new(
	$substance,
);
ok $message, Dumper($message);
@list = ();
push @list, $message->expire;
ok @list, Dumper($list[0]);
