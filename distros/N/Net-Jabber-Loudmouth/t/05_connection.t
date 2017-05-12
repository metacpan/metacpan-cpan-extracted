use strict;
use POSIX qw/SIGKILL/;
use Test::More tests => 55;
use Test::Exception;
use Glib;
use Net::Jabber::Loudmouth;

require 't/server_helper.pl';
my $pid = start_server();

my $c = Net::Jabber::Loudmouth::Connection->new("foobar");
isa_ok($c, "Net::Jabber::Loudmouth::Connection");

is($c->get_server(), "foobar", 'get_server() works');

dies_ok {$c->open_and_block()} 'open_and_block() fails with invalid server';

$c->set_server("localhost");
is($c->get_server(), "localhost", 'get_server() works');

is($c->get_jid(), undef, 'jid is initialized with undef');
$c->set_jid('foo@localhost');
is($c->get_jid(), 'foo@localhost', 'set_jid() works');

is($c->get_port(), 5222, 'default port is correct / get_port() works');
$c->set_port(4333);
is($c->get_port(), 4333, 'set_port() works');
$c->set_port(5222);

is($c->get_ssl(), undef, 'ssl is undef by default / get_ssl() works');
$c->set_ssl(Net::Jabber::Loudmouth::SSL->new(sub {}));
ok($c->get_ssl(), 'set_ssl() works');
$c->set_ssl(undef);
is($c->get_ssl(), undef, 'removing ssl object works');

is($c->get_proxy(), undef, 'proxy is undef by default / get_proxy*( works');
$c->set_proxy(Net::Jabber::Loudmouth::Proxy->new('http'));
ok($c->get_proxy(), 'set_proxy() works');
$c->set_proxy(undef);
is($c->get_proxy(), undef, 'removing proxy object works');

undef $c;
$c = Net::Jabber::Loudmouth::Connection->new("localhost");

my $m = Net::Jabber::Loudmouth::Message->new('foo@localhost', 'message');
$m->get_node->add_child('body', 'bar');

dies_ok {$c->close()} 'closing closed connection dies';
dies_ok {$c->authenticate()} 'authenticating closed connection dies';
dies_ok {$c->send($m)} 'sending over closed connection dies';
dies_ok {$c->send_with_reply($m)} 'sending with reply over closed connection dies';
dies_ok {$c->send_with_reply_and_block($m)} 'blocking send with reply over closed connection dies';
dies_ok {$c->send_raw($m->get_node->to_string())} 'send_raw() over closed connection dies';

is($c->get_state(), 'closed', 'connection is closed by default / get_state() works');
ok(!$c->is_open(), 'connection isn\'t opened by default / is_open() works');
ok($c->open_and_block(), 'open_and_block() returns true');
is($c->get_state(), 'open', 'connection state is open after successful open_and_block()');
ok($c->is_open(), 'is_open() works');
ok(!$c->is_authenticated(), 'we\'re not yet authenticated');
ok($c->close(), 'closing works');
ok(!$c->is_open(), 'we\'re not open anymore');

my $loop = Glib::MainLoop->new();
ok($c->open(\&open_cb), 'open() returns true');
$loop->run();

sub open_cb {
	my ($connection, $success) = @_;
	ok(1, 'open callback gets called');
	isa_ok($connection, "Net::Jabber::Loudmouth::Connection");
	ok($success, 'open was successful');
	ok($connection->is_open(), 'is_open() returns true');
	is($connection->get_state(), 'open', 'state is open');
	ok(!$connection->is_authenticated(), 'we\'re not authenticated yet');
	$loop->quit();
}

dies_ok {$c->authenticate_and_block("alnsldabsdasd", "", "TestSuite")} 'wrong authentication fails';

ok($c->authenticate_and_block("foo", "bar", "TestSuite"), 'authentication works fine');
is($c->get_state(), 'authenticated', 'state is authenticated after authenticate_and_block()');
ok($c->is_authenticated(), 'is_authenticated() returns true after authenticate_and_block()');
ok($c->close(), 'closing works');
ok(!$c->is_authenticated(), 'closed connection isn\'t authenticated');
ok($c->open_and_block(), 'open_and_block() works');

ok($c->authenticate("foo", "bar", "TestSuite", \&auth_cb), 'authenticate returns true');
$loop->run();

sub auth_cb {
	my ($connection, $success) = @_;
	ok(1, 'auth callback gets called');
	isa_ok($connection, "Net::Jabber::Loudmouth::Connection");
	ok($success, 'authed successful');
	ok($connection->is_authenticated(), 'is_authenticated() works');
	$loop->quit();
}

$c->set_keep_alive_rate(20);

my $handler = Net::Jabber::Loudmouth::MessageHandler->new(sub {});
isa_ok($handler, "Net::Jabber::Loudmouth::MessageHandler");

my $retval = $c->register_message_handler('message', 'normal', $handler);
isa_ok($retval, "Net::Jabber::Loudmouth::MessageHandler");

$c->unregister_message_handler('message', $handler);

$retval = $c->register_message_handler('message', 'normal', sub {});
isa_ok($retval, "Net::Jabber::Loudmouth::MessageHandler");

$c->unregister_message_handler('message', $retval);

$retval = $c->register_message_handler('message', 'normal', sub {}, 1);
isa_ok($retval, "Net::Jabber::Loudmouth::MessageHandler");

$c->unregister_message_handler('message', $retval);

dies_ok {$c->register_message_handler('message', 'normal', $handler, 1)} 'register_message_handler() with a MessageHandler object and user_data dies';
dies_ok {$c->register_message_handler('message', 'normal', 1)} 'register_message_handler() with something that\'s not a MessageHandler or a code reference dies';

$c->register_message_handler('message', 'normal', \&message_cb);

ok($c->send($m), 'send() works');
ok($c->send_raw($m->get_node->to_string()), 'send_raw() works');

$c->set_disconnect_function(sub {});

kill SIGKILL, $pid;
