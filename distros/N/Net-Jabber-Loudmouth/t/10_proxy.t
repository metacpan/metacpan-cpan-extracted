use strict;
use POSIX qw/SIGKILL/;
use Test::More tests => 16;
use Net::Jabber::Loudmouth;

require 't/server_helper.pl';
require 't/proxy_helper.pl';
my $server_pid = start_server();
#my $proxy_pid = start_proxy();

my $c = Net::Jabber::Loudmouth::Connection->new("localhost");

my $proxy = Net::Jabber::Loudmouth::Proxy->new('none');
isa_ok($proxy, "Net::Jabber::Loudmouth::Proxy");

is($proxy->get_server(), undef, 'default server is undef');

$proxy->set_server("localhost");
is($proxy->get_server(), "localhost", 'set_server() works');

is($proxy->get_type(), 'none', 'type is none');
$proxy->set_type('http');
is($proxy->get_type(), 'http', 'set_type() works');

is($proxy->get_port(), 0, 'default port is 0');
$proxy->set_port(8080);
is($proxy->get_port(), 8080, 'set_port() works');

is($proxy->get_username(), undef, 'default username is undef');
$proxy->set_username('foo');
is($proxy->get_username(), 'foo', 'set_username() works');

is($proxy->get_password(), undef, 'default password is undef');
$proxy->set_password('bar');
is($proxy->get_password(), 'bar', 'set_password() works');

undef $proxy;

$proxy = Net::Jabber::Loudmouth::Proxy->new_with_server('http', 'localhost', 4143);

is($proxy->get_type(), 'http', 'new_with_server() works');
is($proxy->get_server(), 'localhost', 'new_with_server() works');
is($proxy->get_port(), 4143, 'new_with_server() works');
is($proxy->get_username(), undef, 'new_with_server() works');
is($proxy->get_password(), undef, 'new_with_server() works');

$c->set_proxy($proxy);

TODO: {
	local $TODO = "HTTP::Proxy seems to be b0rked";
#	ok($c->open_and_block(), 'try to open the connection using a proxy');

#	ok($c->is_open(), 'opened');

#	ok($c->authenticate_and_block('foo', 'bar', 'TestSuite'), 'try authentication over the proxy');
#	ok($c->is_authenticated(), 'authenticated');
}

kill SIGKILL, $server_pid;
#kill SIGKILL, $proxy_pid;
