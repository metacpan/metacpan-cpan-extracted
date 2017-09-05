use 5.010;
use strict;
use Test::More;
use Mojo::IOLoop;
use Mojo::SMTP::Client;
use Socket 'CRLF';
use lib 't/lib';
use Utils;

if ($^O eq 'MSWin32') {
	plan skip_all => 'fork() support required';
}

# 1
my $loop = Mojo::IOLoop->singleton;
my ($pid, $sock, $host, $port) = Utils::make_smtp_server();
my $smtp = Mojo::SMTP::Client->new(address => $host, port => $port);
my $connections = 0;
$smtp->on(start => sub {
	$connections++;
});
$smtp->send(sub {
	my $resp = pop;
	ok(!$resp->error, 'no error');
	is($resp->code, 220, 'right code');
	is($resp->message, 'OK', 'right message');
	
	$smtp->send(from => 'baralgin@mail.net', to => ['jorik@40.com', 'vasya@gde.org.ru'], quit => 1, sub {
		my $resp = pop;
		ok(!$resp->error, 'no error');
		is($resp->code, 220, 'right code');
		$loop->stop;
	});
});

my $i;
my @cmd = (
	'CONNECT',
	'EHLO localhost.localdomain',
	'MAIL FROM:<baralgin@mail.net>',
	'RCPT TO:<jorik@40.com>',
	'RCPT TO:<vasya@gde.org.ru>',
	'QUIT'
);

$loop->reactor->io($sock => sub {
	my $cmd = <$sock>;
	return unless $cmd; # socket closed
	is($cmd, $cmd[$i++].CRLF, 'right cmd');
	syswrite($sock, '220 OK'.CRLF);
});

$loop->reactor->watch($sock, 1, 0);
$loop->start;
$loop->reactor->remove($sock);

is($connections, 1, 'right connections count');
close $sock;
kill 15, $pid;

# 2
($pid, $sock, $host, $port) = Utils::make_smtp_server();
$smtp = Mojo::SMTP::Client->new(address => $host, port => $port, hello => 'dragon-host.net');
$connections = 0;
$smtp->on(start => sub {
	$connections++;
});
$smtp->send(
	from => 'foo@bar.net',
	to   => 'robert@mail.ru',
	data => "From: foo\@bar.net\r\nTo: robert\@mail.ru\r\nSubject: Hello!\r\n\r\nHello world",
	quit => 1,
	sub {
		my ($smtp, $resp) = @_;
		isa_ok($smtp, 'Mojo::SMTP::Client');
		ok(!$resp->error, 'no error') or diag $resp->error;
		is($resp->code, 224, 'right code');
		is($resp->message, 'Connection closed'.CRLF.'See you again', 'right message');
		
		$smtp->send(
			auth => {login => 'jora', password => 'test'},
			from => 'jora@foo.net',
			to   => 'root@2gis.com',
			data => sub {
				read(DATA, my $buf, 64);
				return \$buf;
			},
			quit => 1,
			sub {
				my $resp = pop;
				ok(!$resp->error, 'no error') or diag $resp->error;
				$loop->stop;
			}
		)
	}
);

my $data_pos = tell(DATA);
$i = -2;
@cmd = (
	'CONNECT' => '220 CONNECT OK',
	'EHLO dragon-host.net' => '503 unknown command',
	'HELO dragon-host.net' => '221 HELO ok',
	'MAIL FROM:<foo@bar.net>' => '222 sender ok',
	'RCPT TO:<robert@mail.ru>' => '223 rcpt ok',
	'DATA' => '331 send data, please',
	'From: foo@bar.net' => '.',
	'To: robert@mail.ru' => '.',
	'Subject: Hello!' => '.',
	'' => '.',
	'Hello world' => '.',
	'.' => '220',
	'QUIT' => '224-Connection closed'.CRLF.'224 See you again',
	'CONNECT' => '220 CONNECT OK',
	'EHLO dragon-host.net' => '203 HELLO!!!!',
	'AUTH PLAIN AGpvcmEAdGVzdA==' => '230 AUTHORIZED',
	'MAIL FROM:<jora@foo.net>' => '222 sender ok',
	'RCPT TO:<root@2gis.com>' => '223 rcpt ok',
	'DATA' => '331 send data, please',
	(map { s/\s+$//; $_ => '.' } <DATA>),
	'.' => '224 Message sent',
	'QUIT' => '200 See you'
);
my @cmd_const = (
	Mojo::SMTP::Client::CMD_CONNECT,
	Mojo::SMTP::Client::CMD_EHLO,
	Mojo::SMTP::Client::CMD_HELO,
	Mojo::SMTP::Client::CMD_FROM,
	Mojo::SMTP::Client::CMD_TO,
	Mojo::SMTP::Client::CMD_DATA,
	Mojo::SMTP::Client::CMD_DATA_END,
	Mojo::SMTP::Client::CMD_QUIT,
	Mojo::SMTP::Client::CMD_CONNECT,
	Mojo::SMTP::Client::CMD_EHLO,
	Mojo::SMTP::Client::CMD_AUTH,
	Mojo::SMTP::Client::CMD_FROM,
	Mojo::SMTP::Client::CMD_TO,
	Mojo::SMTP::Client::CMD_DATA,
	Mojo::SMTP::Client::CMD_DATA_END,
	Mojo::SMTP::Client::CMD_QUIT,
);
my @responses = grep { /^\d+(?:[\s-]|$)/ } @cmd;
seek DATA, $data_pos, 0;

my $resp_cnt = 0;
$smtp->on(response => sub {
	my (undef, $cmd, $resp) = @_;
	is($cmd, $cmd_const[$resp_cnt], 'right cmd constant inside response event');
	my $resp_str;
	
	isa_ok($resp, 'Mojo::SMTP::Client::Response');
	
	is($resp, $responses[$resp_cnt].CRLF, 'right response');
	$resp_cnt++;
});
$loop->reactor->io($sock => sub {
	my $cmd = <$sock>;
	return unless $cmd; # socket closed
	$cmd =~ s/\s+$//;
	is($cmd, $cmd[$i+=2], 'right cmd');
	syswrite($sock, $cmd[$i+1].CRLF);
});

$loop->reactor->watch($sock, 1, 0);
$loop->start;
$loop->reactor->remove($sock);

is($resp_cnt, @cmd_const, 'right response count');
is($connections, 2, 'right connections count');
close $sock;
kill 15, $pid;

# 3
my ($pid1, $sock1, $host1, $port1) = Utils::make_smtp_server();
my ($pid2, $sock2, $host2, $port2) = Utils::make_smtp_server();

my $smtp1 = Mojo::SMTP::Client->new(address => $host1, port => $port1, inactivity_timeout => 0.5);
my $smtp2 = Mojo::SMTP::Client->new(address => $host2, port => $port2, inactivity_timeout => 0.5);
my $clients = 2;

$smtp1->send(
	from  => 'root1@2gis.ru',
	to    => 'jora1@2gis.ru',
	reset => 1,
	Utils::TLS ? (starttls => 1) : (),
	from  => 'foo@2gis.com',
	to    => 'bar@2gis.kz',
	data  => '123',
	quit  => 1,
	sub {
		my $resp = pop;
		ok(!$resp->error, 'no error for client 1') or diag $resp->error;
		is($resp->code, 220, 'right code for client 1');
		is($resp->message, 'OK', 'right message for client 1');
		$loop->stop unless --$clients;
	}
);

my @cmd1 = (
	'CONNECT',
	'EHLO localhost.localdomain',
	'MAIL FROM:<root1@2gis.ru>',
	'RCPT TO:<jora1@2gis.ru>',
	'RSET',
	Utils::TLS ? ('STARTTLS') : (),
	'MAIL FROM:<foo@2gis.com>',
	'RCPT TO:<bar@2gis.kz>',
	'DATA',
	'123',
	'.',
	'QUIT'
);

$smtp2->send(
	from => 'root2@2gis.ru',
	to   => 'jora2@2gis.ru',
	data => '321',
	quit => 1,
	sub {
		my $resp = pop;
		ok($resp->error, 'error for client 2');
		isa_ok($resp->error, 'Mojo::SMTP::Client::Exception::Stream', 'right error for client 2');
		is($resp->code, undef, 'no code for client 2');
		is($resp->message, undef, 'no messages for client 2');
		$loop->stop unless --$clients;
	}
);

my @cmd2 = (
	'CONNECT',
	'EHLO localhost.localdomain',
	'MAIL FROM:<root2@2gis.ru>',
	'RCPT TO:<jora2@2gis.ru>',
	'DATA',
	'321',
	'.',
	'QUIT'
);

my $recurring_cnt = 0;
$loop->recurring(0.1 => sub {
	$recurring_cnt++;
});

my $i1 = 0;
$loop->reactor->io($sock1 => sub {
	my $cmd = <$sock1>;
	return unless $cmd; # socket closed
	$cmd =~ s/\s+$//;
	
	is($cmd, $cmd1[$i1++], 'right cmd for client 1');
	syswrite($sock1, ($cmd eq 'DATA' ? '320 OK' : ($cmd eq '123' ? '.' : ($cmd eq 'STARTTLS' ? '220 OK!starttls' : '220 OK'))).CRLF);
});

my $i2 = 0;
$loop->reactor->io($sock2 => sub {
	my $cmd = <$sock2>;
	return unless $cmd; # socket closed
	$cmd =~ s/\s+$//;
	
	is($cmd, $cmd2[$i2++], 'right cmd for client 2');
	if ($cmd eq '.') {
		# make timeout
		$loop->timer(2 => sub {
			syswrite($sock2, '220 OK'.CRLF);
		});
	}
	else {
		syswrite($sock2, ($cmd eq 'DATA' ? '320 OK' : ($cmd eq '321' ? '.' : '220 OK')).CRLF);
	}
});

$loop->reactor->watch($sock1, 1, 0);
$loop->reactor->watch($sock2, 1, 0);
$loop->start;
$loop->reactor->remove($sock1);
$loop->reactor->remove($sock2);

ok($recurring_cnt > 1, 'loop was not blocked');
close $sock1;
close $sock2;
kill 15, $pid1, $pid2;

# 4
($pid, $sock, $host, $port) = Utils::make_smtp_server();
$smtp = Mojo::SMTP::Client->new(address => $host, port => $port);
$connections = 0;
$i = 0;
@cmd = (
	'CONNECT',
	'EHLO localhost.localdomain',
	'MAIL FROM:<filya@sp.ru>',
	'RCPT TO:<k1@mail.ru>',
	'RCPT TO:<k2@mail.ru>',
	'RCPT TO:<k3@mail.ru>',
	'DATA',
	'321123',
	'.',
	'CONNECT',
	'EHLO foo.bar',
	'MAIL FROM:<stepa@ru.spb>',
	'RCPT TO:<dr@sdf.net>',
	'RSET',
	'QUIT'
);

$smtp->on(start => sub {
	$connections++;
});
$loop->reactor->io($sock => sub {
	my $cmd = <$sock>;
	return unless $cmd; # socket closed
	$cmd =~ s/\s+$//;
	
	is($cmd, $cmd[$i++], 'right cmd for client');
	syswrite($sock, ($cmd eq 'DATA' ? '320 OK' : ($cmd eq '.' ? '220 OK!quit' : ($cmd eq '321123' ? '.' : "220 $cmd OK"))).CRLF);
});
$smtp->send(
	from => 'filya@sp.ru',
	to   => ['k1@mail.ru', 'k2@mail.ru', 'k3@mail.ru'],
	data => '321123',
	sub {
		my $resp = pop;
		ok(!$resp->error, 'no error') or diag $resp->error;
		is($resp->message, 'OK!quit', 'right message');
		
		Mojo::IOLoop->timer(0.2 => sub {
			$smtp->hello('foo.bar');
			$smtp->send(
				from  => 'stepa@ru.spb',
				to    => 'dr@sdf.net',
				reset => 1,
				quit  => 1,
				sub {
					my $resp = pop;
					ok(!$resp->error, 'no error');
					is($resp->message, 'QUIT OK', 'right message');
					$loop->stop;
				}
			);
		});
	}
);

$loop->reactor->watch($sock, 1, 0);
$loop->start;
$loop->reactor->remove($sock);

is($connections, 2, 'proper connections count');
close $sock;
kill 15, $pid;

# 5
($pid, $sock, $host, $port) = Utils::make_smtp_server();
$smtp = Mojo::SMTP::Client->new(address => $host, port => $port);

@cmd = (
	'CONNECT' => '220 CONNECTED',
	'EHLO localhost.localdomain' => "203-HELLO SHT\r\n203 ".(Utils::TLS ? "STARTTLS" : "NOTHING"),
	Utils::TLS ? ('STARTTLS' => '205 SECURE!starttls') : (),
	'MAIL FROM:<abc@mail.ru>' => "210 recorder",
	'RCPT TO:<def@mail.ru>' => "210 recorder",
	'RCPT TO:<xyz@mail.ru>' => "210 recorder",
	'DATA' => "321 Please continue",
	'fooo' => '.',
	'.' => '234 Oh yes'
);
$i = 0;
$loop->reactor->io($sock => sub {
	my $cmd = <$sock>;
	return unless $cmd; # socket closed
	$cmd =~ s/\s+$//;
	
	is($cmd, $cmd[$i], 'right cmd for client');
	syswrite($sock, $cmd[$i+1].CRLF);
	$i+=2;
});
$smtp->send(
	from => 'abc@mail.ru',
	to   => ['def@mail.ru'],
	to   => 'xyz@mail.ru',
	data => 'fooo',
	sub {
		my $resp = pop;
		ok(!$resp->error, 'no error') or diag $resp->error;
		is($resp->message, 'Oh yes', 'right message');
		$loop->stop;
	}
);
$smtp->on(response => sub {
	my ($smtp, $cmd, $resp) = @_;
	
	if ($cmd == Mojo::SMTP::Client::CMD_EHLO && $resp->message =~ /STARTTLS/i) {
		$smtp->prepend_cmd(starttls => 1);
	}
});

$loop->reactor->watch($sock, 1, 0);
$loop->start;
$loop->reactor->remove($sock);

close $sock;
kill 15, $pid;

# 6
($pid, $sock, $host, $port) = Utils::make_smtp_server();
$smtp = Mojo::SMTP::Client->new(address => $host, port => $port);

sub get_data {
	my $len = shift // 2;
	my $data = "LINE1\r\n"
		 . "\r\n"
		 . ".\r\n"
		 . "..\r\n"
		 . "...\n"     #intentionally only \n
		 . "....\r\n"
		 . ".LLL7\n"   #intentionally only \n
		 . "LLLLL8\n"; #intentionally only \n
	state $pos = 0;
	return '' if $pos >= length($data);
	my $rv = substr($data, $pos, $len);
	$pos += $len;
	return $rv;
};
$i = 0;
@responses = (
	['220 CONNECT OK',  undef        ], #CONNECT
	['221 HELO ok',     undef        ], #EHLO
	['222 sender ok',   undef        ], #MAIL FROM:
	['223 rcpt ok',     undef        ], #RCPT TO:
	['331 send data',   undef        ], #DATA
	['.',               "LINE1\r\n"  ], #line1
	['.',               "\r\n"       ], #line2
	['.',               "..\r\n"     ], #line3
	['.',               "...\r\n"    ], #line4
	['.',               "....\r\n"   ], #line5
	['.',               ".....\r\n"  ], #line6
	['.',               "..LLL7\r\n" ], #line7
	['.',               "LLLLL8\r\n" ], #line8
	['220',             undef        ],
);
$loop->reactor->io($sock => sub {
	my $cmd = <$sock>;
	return unless $cmd; # socket closed
	ok($cmd eq $responses[$i][1], "resp[$i]") if defined $responses[$i][1];
	syswrite($sock, $responses[$i][0].CRLF);
	$i++;
});
$smtp->send(
	from => 'abc@mail.ru',
	to   => 'xyz@mail.ru',
	data => sub { get_data(2) },
	sub { $loop->stop },
);
$loop->reactor->watch($sock, 1, 0);
$loop->start;
$loop->reactor->remove($sock);

close $sock;
kill 15, $pid;

# 7
($pid, $sock, $host, $port) = Utils::make_smtp_server();
$smtp = Mojo::SMTP::Client->new(address => $host, port => $port, hello => 'dragon-host.net');
$smtp->on(start => sub {
	die "error from start callback\n";
});

$smtp->send(
	from => 'abc@mail.ru',
	to   => 'xyz@mail.ru',
	data => 'smth useless',
	sub { 
		my $resp = pop;
		
		ok($resp->error, "Got error from the `start' callback");
		is($resp->error, "error from start callback\n", "Got right error");
		
		$loop->stop;
	}
);

$loop->start;
close $sock;
kill 15, $pid;

# 8
($pid, $sock, $host, $port) = Utils::make_smtp_server();
$smtp = Mojo::SMTP::Client->new(address => $host, port => $port, hello => 'dragon-host.net');
$smtp->on(response => sub {
	my $cmd = $_[1];
	
	if ($cmd == Mojo::SMTP::Client::CMD_EHLO) {
		die "I don't like you\n";
	}
});

$i = 0;

$smtp->send(
	from => 'abc@mail.ru',
	to   => 'xyz@mail.ru',
	data => 'smth useless',
	sub { 
		my $resp = pop;
		
		ok($resp->error, "Got error from the `response' callback");
		is($resp->error, "I don't like you\n", "Got right error");
		is($i, 2, "connect -> EHLO -> die");
		
		$loop->stop;
	}
);

$loop->reactor->io($sock => sub {
	my $cmd = <$sock>;
	return unless $cmd; # socket closed
	syswrite($sock, '220 OK'.CRLF);
	$i++;
});

$loop->reactor->watch($sock, 1, 0);
$loop->start;
$loop->reactor->remove($sock);
close $sock;
kill 15, $pid;

# 9 - AUTH LOGIN method
($pid, $sock, $host, $port) = Utils::make_smtp_server();
$smtp = Mojo::SMTP::Client->new(address => $host, port => $port);
$connections = 0;
$smtp->on(start => sub {
    $connections++;
});

@cmd = (
    'CONNECT' => '220 CONNECT OK',
    'EHLO localhost.localdomain' => '203 HELLO!!!!',
    'AUTH LOGIN' => '334 VXNlcm5hbWU6',   # 334 Username:
    'am9yYQ=='   => '334 UGFzc3dvcmQ6',   # 334 Password:
    'dGVzdA=='   => '235 Authentication succeeded',
    'MAIL FROM:<baralgin@mail.net>' => '222 sender ok',
    'RCPT TO:<jorik@40.com>' => '223 rcpt ok',
    'QUIT' => '200 See you',
);

$smtp->send(
    auth => { type => 'LOGin', login => 'jora', password => 'test' },
    from => 'baralgin@mail.net',
    to => 'jorik@40.com',
    quit => 1,
    sub {
        my $resp = pop;
        ok(!$resp->error, 'no error') or diag $resp->error;
        $loop->stop;
    }
);

$i = 0;
$loop->reactor->io($sock => sub {
    my $client_cmd = <$sock>;
    return unless $client_cmd; # socket closed
    $client_cmd =~ s/\s+$//;

    is($client_cmd, $cmd[$i], 'right cmd from client') or $loop->stop;
    syswrite($sock, $cmd[$i+1].CRLF);
    $i+=2;
});

$loop->reactor->watch($sock, 1, 0);
$loop->start;
$loop->reactor->remove($sock);

is($connections, 1, 'right connections count');
close $sock;
kill 15, $pid;

done_testing;

__DATA__
Content-Transfer-Encoding: binary
Content-Type: multipart/mixed; boundary="_----------=_1425716600166160"
MIME-Version: 1.0
X-Mailer: MIME::Lite 3.028 (F2.82; B3.13; Q3.13)
Date: Sat, 7 Mar 2015 14:23:20 +0600
From: root@home.data-flow.ru
To: root@data-flow.ru
Subject: Hello world

This is a multi-part message in MIME format.

--_----------=_1425716600166160
Content-Disposition: inline
Content-Length: 12
Content-Transfer-Encoding: binary
Content-Type: text/plain

Hello sht!!!
--_----------=_1425716600166160
Content-Disposition: attachment; filename="mime-test.pl"
Content-Transfer-Encoding: base64
Content-Type: text/plain; name="mime-test.pl"

dXNlIHN0cmljdDsKI3VzZSBsaWIgJy9ob21lL29sZWcvcmVwb3MvTUlNRS1M
aXRlL2xpYic7CnVzZSBNSU1FOjpMaXRlOwoKbXkgJG1zZyA9IE1JTUU6Okxp
dGUtPm5ldygKCUZyb20gICAgPT4gJ3Jvb3RAaG9tZS5kYXRhLWZsb3cucnUn
LAoJVG8gICAgICA9PiAncm9vdEBkYXRhLWZsb3cucnUnLAoJU3ViamVjdCA9
PiAnSGVsbG8gd29ybGQnLAoJVHlwZSAgICA9PiAnbXVsdGlwYXJ0L21peGVk
JwopOwoKJG1zZy0+YXR0YWNoKFR5cGUgPT4gJ1RFWFQnLCBEYXRhID0+ICdI
ZWxsbyBzaHQhISEnKTsKJG1zZy0+YXR0YWNoKFBhdGggPT4gX19GSUxFX18s
IERpc3Bvc2l0aW9uID0+ICdhdHRhY2htZW50JywgRW5jb2RpbmcgPT4gJ2Jh
c2U2NCcpOwoKb3BlbiBteSAkZmgsICc+JywgJy90bXAvbXNnJyBvciBkaWUg
JCE7CiRtc2ctPnByaW50KCRmaCk7CmNsb3NlICRmaDsKCiNteSBAcGFydHMg
PSAkbXNnLT5wYXJ0czsKI3dhcm4gcmVmICRfIGZvciBAcGFydHM7Cg==

--_----------=_1425716600166160--
