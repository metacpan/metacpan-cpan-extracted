#!/usr/bin/perl

use strict;
use warnings;

use Test::More; # 'no_plan';
BEGIN { plan tests => 10 };

use English;

BEGIN {
	use_ok ( 'Net::TacacsPlus::Client' ) or exit;
	use_ok ( 'Net::TacacsPlus::Constants' ) or exit;
}

my $client = Net::TacacsPlus::Client->new(
	'host' => 'localhost',
	'key'  => 'test',
);

isa_ok($client, 'Net::TacacsPlus::Client');

#online test to create ::Client object and connect to tacacs server
SKIP: {

	skip "skipping online tests. set TACACS_SERVER, TACACS_SECRET, TACACS_USER environmental variables to activate them.", 7
		if (!$ENV{'TACACS_SERVER'}
			or !$ENV{'TACACS_SECRET'}
			or !$ENV{'TACACS_USER'}
		);

	my $tacacs_server = $ENV{'TACACS_SERVER'};
	my $tacacs_secret = $ENV{'TACACS_SECRET'};

	my $client = Net::TacacsPlus::Client->new(
		'host' => $tacacs_server,
		'key'  => $tacacs_secret,
	);
	
	isa_ok($client, 'Net::TacacsPlus::Client');


	diag('Authentication tests.');

	if ($ENV{'TACACS_PAP_PASSWORD'}) {
		ok($client->authenticate(
				$ENV{'TACACS_USER'},
				$ENV{'TACACS_PAP_PASSWORD'},
				TAC_PLUS_AUTHEN_TYPE_PAP
			),
			'do PAP authentication '.$EVAL_ERROR
		);
		ok(!$client->authenticate(
				$ENV{'TACACS_USER'},
				$ENV{'TACACS_PAP_PASSWORD'}.'x',
				TAC_PLUS_AUTHEN_TYPE_PAP
			),
			'do PAP authentication with wrong password '.$EVAL_ERROR
		);
	}
	else {
		diag('skipping PAP authentication test, TACACS_PAP_PASSWORD enviromental variable not set');
		ok(1);
		diag('skipping PAP authentication test, TACACS_PAP_PASSWORD enviromental variable not set');
		ok(1);
	}

	if ($ENV{'TACACS_ASCII_PASSWORD'}) {
		ok($client->authenticate(
				$ENV{'TACACS_USER'},
				$ENV{'TACACS_ASCII_PASSWORD'},
				TAC_PLUS_AUTHEN_TYPE_ASCII
			),
			'do ASCII authentication '.$EVAL_ERROR
		);
		ok(!$client->authenticate(
				$ENV{'TACACS_USER'},
				$ENV{'TACACS_ASCII_PASSWORD'}.'x',
				TAC_PLUS_AUTHEN_TYPE_ASCII
			),
			'do ASCII authentication with wrong password '.$EVAL_ERROR
		);
	}
	else {
		diag('skipping ASCII authentication test, TACACS_ASCII_PASSWORD enviromental variable not set');
		ok(1);
		diag('skipping ASCII authentication test, TACACS_ASCII_PASSWORD enviromental variable not set');
		ok(1);
	}


	diag('Accounting tests.');

	if ($ENV{'TACACS_CMD'} and exists $ENV{'TACACS_CMD_ARG'}) {
	    my @args = ( 'service=shell', 'cmd='.$ENV{'TACACS_CMD'}, 'cmd-arg='.$ENV{'TACACS_CMD_ARG'} );
	    ok($client->account($ENV{'TACACS_USER'}, \@args), 'account: '.join(' ', @args));
	}
	else {
		diag('skipping accounting test, set TACACS_CMD and TACACS_CMD_ARG to activate it.');
		ok(1);
	}


	diag('Authorization tests.');
	
	if ($ENV{'TACACS_CMD'} and exists $ENV{'TACACS_CMD_ARG'}) {
	    my @args = ( 'service=shell', 'cmd='.$ENV{'TACACS_CMD'}, 'cmd-arg='.$ENV{'TACACS_CMD_ARG'} );
	    my @args_response;

		ok($client->authorize($ENV{'TACACS_USER'}, \@args, \@args_response), 'authorize: '.join(' ', @args).' '.$client->errmsg);

	    diag('# Authorization response arguments: '.join(' ', @args_response));
	}
	else {
		diag('skipping authorization test, set TACACS_CMD and TACACS_CMD_ARG to activate it.');
		ok(1);
	}

}
