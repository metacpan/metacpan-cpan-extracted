use strict;
use POSIX qw/SIGKILL/;
use Test::More tests => 13;
use Net::Jabber::Loudmouth;

require 't/server_helper.pl';
my $pid = start_server();

ok(defined Net::Jabber::Loudmouth::SSL->is_supported(), 'is_supported() returns something defined');

SKIP: {
	skip "No SSL support available", 12 unless Net::Jabber::Loudmouth::SSL->is_supported();
	my $c = Net::Jabber::Loudmouth::Connection->new("localhost");

	my $ssl = Net::Jabber::Loudmouth::SSL->new(\&ssl_cb);
	isa_ok($ssl, "Net::Jabber::Loudmouth::SSL");

	$c->set_ssl($ssl);

	$c->set_port($Net::Jabber::Loudmouth::DefaultPortSSL);
	is($c->get_port(), 5223, 'default ssl port is right');

	ok($c->open_and_block(), 'opened connection using ssl');

	ok(defined $ssl->get_fingerprint(), 'get_fingerprint() works');

	sub ssl_cb {
		my ($ssl, $status) = @_;

		isa_ok($ssl, "Net::Jabber::Loudmouth::SSL");
		ok(defined $status, "got status message $status");

		return 'continue';
	}
}

kill SIGKILL, $pid;
