#!/usr/bin/perl -w
use Test::More tests => 18;

BEGIN { use_ok('Net::Rendezvous') };

use strict;
use Net::DNS;

my $entry;
ok( $entry = Net::Rendezvous::Entry->new(), 	'constructor');
ok( $entry->fqdn('server._test._tcp.local'), 	'fqdn set');
ok( $entry->fqdn eq 'server._test._tcp.local', 	'fqdn get');
ok( $entry->name('server.local'),		'name set');
ok( $entry->name eq 'server.local',		'name get');
ok( $entry->port('1234'),			'port set');
ok( $entry->port == 1234, 			'port get');
ok( $entry->hostname('server.local'),		'hostname set');
ok( $entry->hostname eq 'server.local',		'hostname get');
ok( $entry->address('127.0.0.1'),		'address set');
ok( $entry->address eq '127.0.0.1',		'address get');
ok( $entry->attribute('text1', 'value'), 	'attribute set');
ok( $entry->attribute('text1') eq 'value', 	'attribute get');
ok( $entry->all_attrs,				'attribute reload');
ok( $entry->dnsrr,				'dnsrr PTR');
ok( $entry->dnsrr('srv'),			'dnsrr SRV');
ok( $entry->dnsrr('txt'),			'dnsrr TXT');
