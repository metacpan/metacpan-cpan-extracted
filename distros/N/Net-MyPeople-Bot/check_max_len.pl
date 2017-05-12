#!/usr/bin/env perl 

use strict;
use warnings;
use 5.010;
use utf8;
use lib qw(./lib);

use Net::MyPeople::Bot;
use Data::Printer;
use Encode;
my $APIKEY = $ENV{MYPEOPLE_APIKEY}; 

my $bot = Net::MyPeople::Bot->new(apikey=>$APIKEY, web_proxy_base=>'http://localhost:8080/proxy/');
my $from = 0;
my $to = 5000;

my $before=0;
while($to != $from ){
	my $half = $from + int(($to - $from) / 2);
	last if( $before == $half );
	say "$from..$to - send $half";
	my $res;
	my $msg = '한' x $half;
	$res = $bot->send('BU_wqPHjxmJKIxKcIrAQu-JiA00', $msg, undef, 1 );
	#$res = $bot->groupSend('GID_WZrl1', 'X' x $half );
	if( $res->{code} eq '200' ){
		$from = $half;
	}
	else{
		$to = $half;
	}
	$before = $half;
}
say "MAX LENGTH : ".$before;
