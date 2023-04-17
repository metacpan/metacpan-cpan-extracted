use strict;
use Test::More;
use Mojo::SMTP::Client;
use Mojo::Exception;
use Mojo::IOLoop::TLS;
use Socket 'CRLF';
use lib 't/lib';
use Utils;

if ($^O eq 'MSWin32') {
	plan skip_all => 'fork() support required';
}

my $tls = &Mojo::IOLoop::TLS::TLS;

# 1
my ($pid, $sock, $host, $port) = Utils::make_smtp_server($tls);
my $smtp = Mojo::SMTP::Client->new(address => $host, port => $port, tls => $tls, tls_verify => 0);
syswrite($sock, join(CRLF, '220 host.net', '220 hello ok', '220 from ok', '220 to ok', '220 quit ok').CRLF);

my $resp = $smtp->send(hello => 'mymail.host', from => '', to => 'jorik@gmail.com', quit => 1);
isa_ok($resp, 'Mojo::SMTP::Client::Response');
ok(!$resp->error, 'no error') or diag $resp->error;
is($resp->code, 220, 'right response code');
is($resp->message, 'quit ok', 'right message');
is($resp->to_string, '220 quit ok'.CRLF, 'stringify message');

my @expected_cmd = (
	'CONNECT',
	'EHLO mymail.host',
	'MAIL FROM:<>',
	'RCPT TO:<jorik@gmail.com>',
	'QUIT'
);

for (0..4) {
	is(scalar(<$sock>), $expected_cmd[$_].CRLF, "right cmd was sent: $expected_cmd[$_]");
}
close $sock;
kill 15, $pid;

# 2
($pid, $sock, $host, $port) = Utils::make_smtp_server();
$smtp = Mojo::SMTP::Client->new(address => $host, port => $port, inactivity_timeout => 0.5, autodie => 1, tls_verify => 0);
eval {
	$smtp->send(quit => 1);
};
ok(my $e = $@, 'timed out');
isa_ok($e, 'Mojo::SMTP::Client::Exception::Stream');
close $sock;
kill 15, $pid;

# 3
($pid, $sock, $host, $port) = Utils::make_smtp_server();
$smtp = Mojo::SMTP::Client->new(address => $host, port => $port, autodie => 1, tls_verify => 0);
syswrite($sock, '500 host.net is busy'.CRLF);
eval {
	$smtp->send();
};
ok($e = $@, 'bad response');
isa_ok($e, 'Mojo::SMTP::Client::Exception::Response');
close $sock;
kill 15, $pid;

# 4
($pid, $sock, $host, $port) = Utils::make_smtp_server();
$smtp = Mojo::SMTP::Client->new(address => $host, port => $port, autodie => 1, tls_verify => 0);
syswrite($sock, join(CRLF, '220 host.net', '220 hello ok', '220 from ok', '220 to ok', '220 quit ok').CRLF);

$smtp->on(response => sub {
	my $cmd = $_[1];
	
	if ($cmd == Mojo::SMTP::Client::CMD_EHLO) {
		Mojo::Exception->throw("Throwed from response callback");
	}
});

eval {
	$smtp->send(hello => 'mymail.host', from => '', to => 'jorik@gmail.com', quit => 1);
};
$e = $@;
is(ref $e, 'Mojo::Exception', 'got right exception');
is($e->message, 'Throwed from response callback', 'with right message');

close $sock;
kill 15, $pid;

done_testing;
