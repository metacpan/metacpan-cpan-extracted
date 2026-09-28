# Tests: ssl input buffering

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::More;
use Socket;
use IO::Select;
use IO::Socket::SSL;
use RPC::Switch::Client::Tiny;
use RPC::Switch::Client::Tiny::Netstring;

plan skip_all => 'fork not supported' if ($^O eq 'MSWin32');
eval { require IO::Socket::SSL::Utils; IO::Socket::SSL::Utils->import('CERT_create'); 1 }
	or plan skip_all => 'IO::Socket::SSL::Utils required';

plan tests => 4;

my @msgs = map { to_netstring($_) } (
	'{"method":"test.one","jsonrpc":"2.0"}',
	'{"method":"test.two","jsonrpc":"2.0"}',
);

sub to_netstring {
	my ($str) = @_;
	return length($str) . ':' . $str . ',';
}

socketpair(my $srv, my $cl, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";

# write two messages at once, so they share one ssl record
#
my $pid = fork();
defined $pid or die "fork: $!";
unless ($pid) {
	close($cl);
	my ($cert, $key) = CERT_create(CA => 1, subject => {CN => 'rpctiny-test'});
	my $s = IO::Socket::SSL->start_SSL($srv, SSL_server => 1, SSL_cert => $cert, SSL_key => $key)
		or die "server handshake: $SSL_ERROR";
	syswrite($s, join('', @msgs));
	sysread($s, my $eof, 1); # keep connection open until the client is done
	exit 0;
}
close($srv);

my $sock = IO::Socket::SSL->start_SSL($cl, SSL_verify_mode => SSL_VERIFY_NONE)
	or die "client handshake: $SSL_ERROR";
my $client = RPC::Switch::Client::Tiny->new(sock => $sock, who => 'cl', timeout => 1);

# read the first message directly to fill the ssl input buffer
# (buffers the second message - select() will not see it)
#
my $b = RPC::Switch::Client::Tiny::Netstring::netstring_read($sock);
like($b, qr/test\.one/, 'test ssl first message');
cmp_ok($sock->pending(), '>', 0, 'test ssl pending after first message');
ok(!IO::Select->new($sock)->can_read(0), 'test ssl select misses buffered data');

# rpc_handler must not wait in select() while the ssl stack holds a message
#
my $res = eval { $client->rpc_handler(0, sub { return $_[1] }) };
my $err = $@;
is(eval { $res->{method} } || $err, 'test.two', 'test ssl buffered message read');

$sock->close(SSL_no_shutdown => 1);
waitpid($pid, 0);
