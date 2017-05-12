#!/usr/bin/perl

use lib qw(../lib);

use POE qw(Component::EasyDBI);

$|++;

die "setup a database (see the bottom of this file)\n";

# Set up the DBI
if (1) {
	# postgresql
	POE::Component::EasyDBI->new(
		alias		=> 'EasyDBI',
		dsn			=> 'DBI:Pg:dbname=template1',
		username	=> 'postgres',
		password	=> '',
		max_retries => -1,
		ping_timeout => 10,
		no_connect_failures => 1,
		reconnect_wait => 4,
		connect_error => [ 'test', 'connect_error' ],
		connected => [ 'test', 'connected' ],
		no_warnings => 1, # undocumented, will not warn about database errors
	);
} else {
	# mysql
	POE::Component::EasyDBI->new(
		alias		=> 'EasyDBI',
		dsn			=> 'DBI:mysql:db=test;host=localhost',
		username	=> 'mysql',
		password	=> '',
		max_retries => -1,
		ping_timeout => 10,
		no_connect_failures => 1,
		reconnect_wait => 4,
		connect_error => [ 'test', 'connect_error' ],
		connected => [ 'test', 'connected' ],
		no_warnings => 1, # undocumented, will not send warn about database errors
	);

}

# Create our own session to communicate with EasyDBI
POE::Session->create(
	inline_states => {
		_start => sub {
			my $kernel = $_[KERNEL];
			$kernel->alias_set('test');
			
			$kernel->post( 'EasyDBI',
				do => {
					sql => 'DELETE FROM testing',
					event => 'deleted_handler',
				}
			);
	
			$kernel->yield('insert');
		},
		insert => sub {
			my $kernel = $_[KERNEL];
			
			$kernel->post( 'EasyDBI',
				insert => {
					sql => 'INSERT INTO testing (testid,sendtime) VALUES(?,?)',
					event => 'insert_handler',
					placeholders => [ $heap->{session}++, time() ],
					extra_data => 2021,
				}
			);
			print ".";
			$kernel->delay_set('insert' => 2);
		},
		deleted_handler => sub {
			my $i = $_[ARG0];
			if ($i->{error}) {
				die "$i->{error}";
			}
			print "deleted $i->{result} rows\n";
		},
		insert_handler => sub {
			my $i = $_[ARG0];
			if ($i->{error}) {
				print "$i->{error}\n";
			}
			# extra data is in $i->{extra_data} (from insert event)
			print ":";
		},
		connect_error => sub {
			$_[HEAP]->{connected} = 0;
			$_[HEAP]->{disconnect_time} = time() unless defined($_[HEAP]->{disconnect_time});
			print "connect error $_[ARG0]->{error}\n";
			if (defined($_[HEAP]->{disconnect_time})
				&& (time() - $_[HEAP]->{disconnect_time}) > 30
				&& !defined($_[HEAP]->{email_sent})) {
				print "HELP, HELP, HELP!  I've been disconnected for more than 30 seconds\n";
				print "This is where I would email the admin\n";
				$_[HEAP]->{email_sent} = 1;
			}
		},
		connected => sub {
			$_[HEAP]->{connected} = 1;
			delete $_[HEAP]->{disconnect_time};
			delete $_[HEAP]->{email_sent};
			print "connected\n";
		},
	},
);
	
$poe_kernel->run();

exit;

__DATA__

--
-- PostgreSQL database dump
--

--
-- TOC entry 6 (OID 18517)
-- Name: testing; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE testing (
    testid character varying(100) DEFAULT ''::character varying NOT NULL,
    sendtime integer DEFAULT 0 NOT NULL,
);


