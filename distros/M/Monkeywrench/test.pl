#!/usr/bin/perl -w

use strict;
use lib 'lib';
use HTTP::Monkeywrench;
use Data::Dumper;

my $session1 = [
	{
		name			=> 'Main Yahoo Page',
		url				=> 'http://www.yahoo.com/',
		params			=> {},
		method			=> '',
		auth			=> [],
		success_res		=> [qr/Yahoo/i,qr/Privacy Policy/i],
		error_res		=> [qr/404/i],
		#cookies			=> [],
		cookies			=> [['0', 'B', 'drpf3kksomm3l&b=2&f=s', '/','.yahoo.com', '', '', '', '2000-08-05 17:15:15Z', '']],
		acceptcookie 	=> 0,
		sendcookie 		=> 1,
		showhtml		=> 0
	},
	{
		name			=> 'Search Results Page (monkey)',
		url				=> 'http://search.yahoo.com/bin/search',
		params			=> {	p	=> 'monkey',	# search for monkey
								y	=> 'y'			# search all of yahoo
						   },
		method			=> 'GET',
		auth			=> [],
		success_res		=> [qr/Monkey/i],
		error_res		=> [qr/Found 0/i,qr/search failed/i],
		cookies			=> [],
		acceptcookie 	=> 0,
		sendcookie 		=> 0,
		showhtml		=> 0
	}
];

my $session2 = [
	{
		name			=> 'Monkey Page',
		url				=> 'http://dir.yahoo.com/Entertainment/Humor/Animals/Monkeys/',
		params			=> { },
		method			=> 'GET',
		auth			=> [],
		success_res		=> [qr/Monkeys/i],
		error_res		=> [qr/Invalid category selection/i],
		cookies			=> [],
		acceptcookie 	=> 0,
		sendcookie 		=> 0,
		showhtml		=> 0
	}
];

my $settings = {
	match_detail	=> 1,
	show_cookies	=> 0,
	smtp_server		=> undef,
	send_mail		=> undef,
	send_if_err		=> undef,
	print_results	=> 0 
};

print "1..1\n";
my $output = HTTP::Monkeywrench->test($settings,$session1,$session2);
if ((ref($output) eq 'HASH') && ($output->{'totaltime'} > 0)) {
	print "ok\n";
} else {
	print "not ok\n";
};

