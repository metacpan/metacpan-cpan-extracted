# Tests: client

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

# cpantester: strawberry perl defaults to JSON::PP and has blessing problem with JSON::true objects
BEGIN { $ENV{PERL_JSON_BACKEND} = 'JSON::backportPP' if ($^O eq 'MSWin32'); }

use Test::More;
use JSON;
use Socket;
use Encode;
use IO::Socket;
use RPC::Switch::Client::Tiny;
use RPC::Switch::Client::Tiny::Netstring;
use Data::Dumper;
use Time::HiRes qw(sleep time);
use POSIX qw(strftime);

plan tests => 39;

my $main_pid = $$;
my ($who, $token, $auth_method, $method, $method2) = ('cl', 'cltoken', 'password', 'test.ping', 'test.tick');

sub new_client_pipe_test_out {
	socketpair(my $out, my $in, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
	my $client = RPC::Switch::Client::Tiny->new(sock => $out, who => $who, token => $token, auth_method => $auth_method);
	return ($out, $in, $client);
}

sub new_client_pipe_test_in {
	my ($msg, $opts) = @_;
	socketpair(my $out, my $in, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
	RPC::Switch::Client::Tiny::Netstring::netstring_write($out, $msg);
	$out->close();
	my $client = RPC::Switch::Client::Tiny->new(sock => $in, who => $who, token => $token, auth_method => $auth_method, timeout => 1, %$opts);
	return ($in, $client);
}

# test client hello
#
my ($out, $in, $client) = new_client_pipe_test_out();
my $want = to_json({id => "$client->{id}", method => "rpcswitch.hello", params => {who => $who, token => $token, method => $auth_method}, jsonrpc => "2.0"}, {canonical => 1});
my $msg = {method => 'rpcswitch.greetings', jsonrpc => '2.0'};
my $res = eval { $client->client($msg, $method, {}, undef) };
my $err = $@;
is($err, '', 'test client greeting result');
my $b = eval { RPC::Switch::Client::Tiny::Netstring::netstring_read($in) };
$b = to_json(from_json($b), {canonical => 1});
is($b, $want, 'test client greeting');
$out->close();
$in->close();

# test bad msg
#
$msg = "{bad_json}";
($in, $client) = new_client_pipe_test_in($msg, {});
$res = eval { $client->work('name', {}) };
$err = $@;
isnt($err, '', 'test client bad json result');
like($err, qr/^jsonrpc error:/, 'test client bad json err');
$in->close();

# test utf8 input
#
my $ue_utf8 = "\xC3\xBC"; # utf8 input
my $ue_latin1 = "\xfc";   # latin1 needs conversion first

socketpair($out, $in, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
$client = RPC::Switch::Client::Tiny->new(sock => $out, who => $who, token => $token, auth_method => $auth_method, client_encoding_utf8 => 1);
$msg = {val => $ue_utf8};
$res = eval { $client->rpc_send_call('rpcswitch.ping', $msg, undef) };
$err = $@;
is($err, '', 'test client utf8 input result');
$b = eval { RPC::Switch::Client::Tiny::Netstring::netstring_read($in) };
like($b, qr/"val":"$ue_utf8"/, 'test client utf8 input');
$out->close();
$in->close();

# test utf8 output
#
my $msgid = '777';
$msg = '{"id": "'.$msgid.'", "jsonrpc": "2.0", "result": {"val1": "'.$ue_utf8.'", "val2": "'.encode('utf8', $ue_latin1).'"}}';
($in, $client) = new_client_pipe_test_in($msg, {client_encoding_utf8 => 1});
$client->{reqs}{$msgid} = 'rpcswitch.ping'; # hack: set status to wait for response
$res = eval { $client->call($method, {}) };
$err = $@;
is($err, '', 'test client utf8 output result');
is($res->{val1}, $ue_utf8, 'test client utf8 output val1');
is($res->{val2}, $ue_utf8, 'test client utf8 output val2');
$in->close();

# test nonblocking
#
unless ($^O eq 'MSWin32') { # cpantester: strawberry perl does not support blocking() call
socketpair($out, $in, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
$out->blocking(0);
$client = eval { RPC::Switch::Client::Tiny->new(sock => $out, who => $who, token => $token, auth_method => $auth_method) };
$err = $@;
like($err, qr/nonblocking socket not supported/, "test blocking");
$out->close();
$in->close();
} else {
is('', '', "skip test blocking");
}

# test against mock server
#
my $test_rpc = {
	'rpcswitch.hello' => [JSON::true, 'welcome to the rpc mock'],
	$method => ['RES_OK', { msg => 'pong' }],
	'test.classerr' => ['RES_ERROR', { class => 'soft', text => 'test for classerror' }],
	'test.scalar' => ['RES_OK', 'xx'],
	'test.array' => ['RES_OK', 'aa', 'bb', 'cc'],
	'test.gone' => ['RES_WAIT', '999'],
	# worker
	'rpcswitch.announce' => [JSON::true, {msg => 'success', worker_id => '1@2'}],
	'rpcswitch.withdraw' => 1,
};

sub mock_send($$) {
	my ($s, $msg) = @_;
	my $str = to_json($msg, {canonical => 1});
	print ">> mockserver snd: $str\n";
	RPC::Switch::Client::Tiny::Netstring::netstring_write($s, $str);
}

my $udp = IO::Socket::INET->new(LocalAddr => 'localhost', Proto => 'udp') or die "socket listen: $@";
my $tcp = IO::Socket::INET->new(LocalAddr => 'localhost', Proto => 'tcp', Listen => 1, Reuse => 1) or die "socket listen: $@";
my $port = $tcp->sockport();
#print ">> listen $port\n";
my $pid = fork(); 
if ($pid == 0) {
	my $greet = {method => 'rpcswitch.greetings', params => {version => '1.0', who => 'rpcswitch'}, jsonrpc => '2.0'};
	ACCEPT: while (1) {
		$| = 1;
		my $b;
		my %req;
		my $req_id = 333;
		my $s = $tcp->accept() or die "socket accept: $@";
		#print ">> mockserver accept\n";
		mock_send($s, $greet);

		while ($b = RPC::Switch::Client::Tiny::Netstring::netstring_read($s)) {
			print ">> mockserver rcv: $b\n";
			my $msg = eval { from_json($b) }; if ($@) { warn "mockserver json: $@"; last };
			if (exists $msg->{method} && exists $test_rpc->{$msg->{method}}) {
				mock_send($s, {id => $msg->{id}, result => $test_rpc->{$msg->{method}}, rpcswitch => {vci => '3@4<->1@2'}, jsonrpc => '2.0'});
				if ($msg->{method} =~ /\.gone$/) {
					mock_send($s, {method => 'rpcswitch.channel_gone', params => { channel => '3@4<->1@2' }, jsonrpc => '2.0'});
				}
			}

 			# send worker test-req
			#	
			if (exists $msg->{method} && ($msg->{method} eq 'rpcswitch.announce') && (scalar keys %req == 0)) {
				my ($cnt) = $msg->{params}{workername} =~ /^test_worker.* (\d+)$/;
				$cnt = 0 unless $cnt;
				for (my $i = 0; $i < $cnt; $i++) {
					my %session = ($msg->{params}{method} eq $method2) ? (session => {id => '1234'}) : ();
					mock_send($s, {id => "$req_id", method => $msg->{params}{method}, params => {val => "test-req $i", %session}, rpcswitch => {vci => '3@4<->1@2', vcookie => 'eatme', worker_id => '1@2'}, jsonrpc => '2.0'});
					$req{$req_id++} = 1;
				}
			}
 			# recv worker test-results
 			#
			my $rsp_id;
			if (exists $msg->{method} && ($msg->{method} eq 'rpcswitch.result')) {
				$rsp_id = $msg->{params}[1];
			} elsif (exists $msg->{id} && exists $req{$msg->{id}}) {
				if (exists $msg->{result} && ($msg->{result}[0] ne 'RES_WAIT')) {
					$rsp_id = $msg->{id};
				}
			}
			if (defined $rsp_id && exists $req{$rsp_id}) {
				delete $req{$rsp_id};
				if (scalar keys %req == 0) {
					print ">> mockserver exit\n";
					$s->shutdown(2);
					$s->close();
					next ACCEPT;
				}
			}
		}
		$s->close();
	}
	exit;
}
$tcp->close(); # for parent

sub new_mock_client {
	my $rpchost = "localhost:$port";
	my $s = new IO::Socket::INET(PeerAddr => $rpchost, Proto => 'tcp', Timeout => 30) or die "connect $rpchost failed";
	my $client = RPC::Switch::Client::Tiny->new(sock => $s, who => $who, token => $token, auth_method => $auth_method);
	return ($s, $client);
}

sub trace_cb {
	my ($direction, $msg) = @_;
	printf "%s: %s\n", $direction, to_json($msg, {canonical => 1});
}

my $s;

# test requests against mock server
# 
($s, $client) = new_mock_client();
$res = eval { $client->call($method, {val => '123'}) };
$err = $@;
#print Dumper($res);
is($err, '', "test rpctiny call err");
is($res->{msg}, 'pong', "test rcptiny call");

$res = eval { $client->call($method, {val => '456'}) };
$err = $@;
is($err, '', "test rpctiny 2nd call err");
is($res->{msg}, 'pong', "test rcptiny 2nd call");

# test error class return against mock server
# 
$res = eval { $client->call('test.classerr', {val => '789'}) };
$err = $@;
isnt($err, '', "test rpctiny classerr err");
is($err->{class}, 'soft', "test rcptiny classerr class");

# test timeout against mock server
# 
$res = eval { $client->call('test.classtmo', {val => '789'}, {timeout => 0.5}) };
$err = $@;
isnt($err, '', "test rpctiny classtmo err");
is($err->{type}, 'jsonrpc', "test rcptiny classtmo type");
is($err->{message}, 'receive timeout', "test rcptiny classtmo message");

# test scalar return against mock server
#
$res = eval { $client->call('test.scalar', {val => '004'}) };
$err = $@;
is($err, '', "test rpctiny scalar return err");
is($res, 'xx', "test rcptiny scalar return");

# test array return against mock server
#
my @list = eval { $client->call('test.array', {val => '005'}) };
$err = $@;
is($err, '', "test rpctiny array return err");
is(join(' ', @list), 'aa bb cc', "test rcptiny array return");

# test array scalar return against mock server
#
$res = eval { $client->call('test.array', {val => '006'}) };
$err = $@;
is($err, '', "test rpctiny array scalar return err");
is($res, 'aa', "test rcptiny array scalar return");

# test channel_gone against mock server
#
$res = eval { $client->call('test.gone', {val => '007'}) };
$err = $@;
isnt($err, '', "test rpctiny channel_gone err");
is($err->{type}, 'rpcswitch', "test rcptiny channel_gone type");
like($err->{message}, qr/^rpcswitch.channel_gone for request/, "test rcptiny channel_gone message");
$s->close();

# test worker against mock server
# 
($s, $client) = new_mock_client();

sub test_worker {
	my ($params, $rpcswitch) = @_;
	return {success => 1, msg => "test_worker $params->{val}"};
}

my $methods = {$method => {cb => \&test_worker, doc => {}}};
eval { $client->work('test_worker 1', $methods); };
$err = $@;
is($err, '', "test rpctiny work eos");
$s->close();

# test multiple async worker against mock server
# 
($s, $client) = new_mock_client();

sub test_worker_multi {
	my ($params, $rpcswitch) = @_;
	#print ">> test_worker_multi[$$] rcv: $params->{val}\n";
	return {success => 1, msg => "test_worker $params->{val}"};
}

eval { $client->work('test_worker 4', {$method => {cb => \&test_worker_multi}}, {max_async => 4}) };
$err = $@;
is($err, '', "test async rpctiny work eos");
$s->close();

# test worker error against mock server
# 
($s, $client) = new_mock_client();

sub test_workererr {
	my ($params, $rpcswitch) = @_;
	die {class => 'hard', text => "test_workererr $params->{val}"};
}

$res = eval { $client->work('test_workererr 1', {$method => {cb => \&test_workererr}}) };
$err = $@;
is($err, '', "test rpctiny workererr eos");
$s->close();

# test multi announce worker error against mock server
# 
($s, $client) = new_mock_client();

$methods = {
	$method => {cb => \&test_worker, doc => {}},
	$method2 => {cb => \&test_worker, doc => {}}
};
eval { $client->work('test_workermulti 1', $methods); };
$err = $@;
is($err, '', "test rpctiny multi work eos");
$s->close();

# test async worker signal
#
($s, $client) = new_mock_client();
#$client->{trace_cb} = \&trace_cb;

sub test_worker_signal {
	my ($params, $rpcswitch) = @_;
	# create dummy pipe to raise sigpipe
	pipe(my $rd, my $wr) or die "pipe err $!";
	$SIG{PIPE} = sub { print ">> test_worker_signal[$$] PIPE!\n"; close($wr) };
	close($rd);
	$client->{sock} = $wr; # raises sigpipe when result is written on closed pipe
	return {success => 1};
}

eval { $client->work('test_worker_signal 1', {$method => {cb => \&test_worker_signal}}, {max_async => 1}) };
$err = $@;
is($err, '', "test async rpctiny work signal");
$s->close();

# test multiple async worker overflow against mock server
#
($s, $client) = new_mock_client();
$client->{trace_cb} = \&trace_cb;
$client->{timeout} = 2;

sub test_worker_sleep {
	my ($params, $rpcswitch) = @_;
	sleep(0.1);
	return {success => 1, msg => "test_worker $params->{val}"};
}

eval { $client->work('test_worker 4', {$method => {cb => \&test_worker_sleep}}, {max_async => 2}) };
$err = $@;
is($err, '', "test async overflow rpctiny work eos");
$s->close();

# test multiple async worker flowcontrol against mock server
#
($s, $client) = new_mock_client();
#$client->{trace_cb} = \&trace_cb;
$client->{timeout} = 2;
$client->{flowcontrol} = 1;

eval { $client->work('test_worker 5', {$method => {cb => \&test_worker_sleep}}, {max_async => 2}) };
$err = $@;
is($err, '', "test async flowcontrol rpctiny work eos");
$s->close();

# test sigpipe on after shutdown
#
($s, $client) = new_mock_client();

$SIG{PIPE} = sub { print ">> sigtest PIPE!\n" };
$s->shutdown(1);
$res = eval { $client->rpc_send_call('rpcswitch.ping', {}, undef) };
$err = $@;
is($err, '', "test sigpipe after shutdown error");
is($res, undef, "test sigpipe after shutdown result");
$SIG{PIPE} = 'DEFAULT';
$s->close();

# test worker session handling against mock server
#
($s, $client) = new_mock_client();
#$client->{trace_cb} = \&trace_cb;
my $s_reuse = 0;

sub test_worker_session {
	my ($params, $rpcswitch) = @_;
	$s_reuse++;
	return {success => 1, msg => "test_session reuse $s_reuse", set_session => {id => '1234'}};
}

$res = eval { $client->work('test_worker_session 4', {$method2 => {cb => \&test_worker_session}}, {max_async => 2, max_session => 4, session_expire => 60}) };
$err = $@;
is($err, '', "test rpctiny worker session");
$s->close();

# test worker session expire against mock server
#
($s, $client) = new_mock_client();
#$client->{trace_cb} = \&trace_cb;

sub test_worker_expire {
	my ($params, $rpcswitch) = @_;
	my $time = time() - 1;
	my $expires = strftime('%Y-%m-%dT%H:%M:%SZ', gmtime($time));
	return {success => 1, msg => "test_session reuse $s_reuse", set_session => {id => '1234', expires => $expires}};
}

$res = eval { $client->work('test_worker_expire 2', {$method2 => {cb => \&test_worker_expire}}, {max_async => 2, max_session => 4, session_expire => 1}) };
$err = $@;
is($err, '', "test rpctiny worker session expire");
$s->close();

END {
	# note: for cpantester strawberry perl pid can be negative
	kill 9, $pid if (($main_pid == $$) && defined $pid && $pid);
}

