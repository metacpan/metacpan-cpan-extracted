#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use AnyEvent::Loop;
use IO::Socket::INET;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Protocol::Dqlite;

use Data::Dumper;

my $s = IO::Socket::INET->new('127.0.0.1:9001') or die;
$s->blocking(0);

my $dqlite = Protocol::Dqlite->new();

stat "================";

syswrite $s, $dqlite->handshake();

syswrite $s, Protocol::Dqlite::request( 1, 0 );

syswrite $s, Protocol::Dqlite::request( 16, 0 );

syswrite $s, Protocol::Dqlite::request(
	Protocol::Dqlite::REQUEST_OPEN,
	'demo',
	0,
	'volatile',
);

my $db_id = 0;

syswrite $s, Protocol::Dqlite::request(
	Protocol::Dqlite::REQUEST_QUERY_SQL,
	$db_id,
	'select * from sqlite_master',
);

my $req = Protocol::Dqlite::request(
	Protocol::Dqlite::REQUEST_QUERY_SQL,
	$db_id,
	#'select 55',
		'select ?, 23 + ?',
	Protocol::Dqlite::TUPLE_FLOAT,
	7.34,
	Protocol::Dqlite::TUPLE_INT64,
	9,
);

use Data::Dumper;
$Data::Dumper::Useqq = 1;
print Dumper( msg => $req);

syswrite $s, $req;

#syswrite $s, Protocol::Dqlite::request(
#        Protocol::Dqlite::REQUEST_DUMP,
#	"demo",
#);

syswrite $s, Protocol::Dqlite::request(
	Protocol::Dqlite::REQUEST_QUERY_SQL,
	0,
	'select ?',
	Protocol::Dqlite::TUPLE_STRING, "\xe9p\xe9e",
);

shutdown $s, 1;

my $cv = AnyEvent->condvar();

my $watch;
$watch = AnyEvent->io(
	poll => 'r',
	fh => $s,
	cb => sub {
		print "==== READING\n";
		if ( sysread $s, my $buf, 512 ) {
			my @msgs = $dqlite->feed($buf);
			print Dumper( @msgs );
		}
		else {
			print "empty read; all done\n";
			undef $watch;
			$cv->();
		}
	},
);

$cv->recv();
