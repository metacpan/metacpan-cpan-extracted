package Plack::App::Gearman::StatusTest;
use parent qw(Test::Class);

use strict;
use warnings;

use Carp;
use Test::More;
use Test::Exception;
use Test::TCP;
use IO::Socket::INET;

use Plack::App::Gearman::Status;

sub new_test: Test(3) {
	my ($self) = @_;

	my $app = Plack::App::Gearman::Status->new();
	isa_ok($app, 'Plack::App::Gearman::Status', 'instance created');
	is_deeply($app->job_servers(), ['127.0.0.1:4730'], 'default job server set');

	$app = Plack::App::Gearman::Status->new({
		job_servers => ['gearman.example.com:20293'],
	});
	is_deeply($app->job_servers(), ['gearman.example.com:20293'], 'job servers set');
}

sub get_status_test : Test(1) {
	my ($self) = @_;

	test_tcp(
		client => sub {
			my ($port) = @_;

			my $app = Plack::App::Gearman::Status->new({
				job_servers => ['127.0.0.1:'.$port],
			});
			is_deeply($app->get_status(), [{
				job_server => '127.0.0.1:'.$port,
				version    => '0.13',
				status     => [{
					busy    => 2,
					free    => 1,
					name    => 'add',
					queue   => 1,
					running => 3
				}],
				workers    => [{
					client_id       => '-',
					file_descriptor => 8432,
					functions       => [ 'job' ],
					ip_address      => '192.168.0.1'
				}]
			}], 'status ok');
		},
		server => sub {
			my ($port) = @_;
			$self->mock_gearman($port);
		}
	);
}


sub connection_test : Test(1) {
	my ($self) = @_;

	test_tcp(
		client => sub {
			my ($port) = @_;

			my $app = Plack::App::Gearman::Status->new();
			my $connection = $app->connection('127.0.0.1:'.$port);
			isa_ok($connection, 'Net::Telnet::Gearman', 'connection ok');
		},
		server => sub {
			my ($port) = @_;
			$self->mock_gearman($port);
		}
	);
}


sub parse_job_server_address_test : Test(20) {
	my ($self) = @_;

	my $app = Plack::App::Gearman::Status->new();

	my ($host, $port) = $app->parse_job_server_address('127.0.0.1:4730');
	is($host, '127.0.0.1', 'host ok');
	is($port, 4730, 'port ok');

	($host, $port) = $app->parse_job_server_address('127.0.0.1');
	is($host, '127.0.0.1', 'host ok');
	is($port, 4730, 'port ok');

	($host, $port) = $app->parse_job_server_address('localhost.localdomain:4730');
	is($host, 'localhost.localdomain', 'host ok');
	is($port, 4730, 'port ok');

	($host, $port) = $app->parse_job_server_address('localhost.localdomain');
	is($host, 'localhost.localdomain', 'host ok');
	is($port, 4730, 'port ok');

	($host, $port) = $app->parse_job_server_address('localhost-01.localdomain:1234');
	is($host, 'localhost-01.localdomain', 'host ok');
	is($port, 1234, 'port ok');

	($host, $port) = $app->parse_job_server_address('localhost_01.localdomain');
	is($host, 'localhost_01.localdomain', 'host ok');
	is($port, 4730, 'port ok');

	($host, $port) = $app->parse_job_server_address('[::1]:4730');
	is($host, '::1', 'host ok');
	is($port, 4730, 'port ok');

	($host, $port) = $app->parse_job_server_address('[::1]');
	is($host, '::1', 'host ok');
	is($port, 4730, 'port ok');

	for my $address (qw(:4930 []:2032 [localhost]:1039 [localhost])) {
		throws_ok(sub {
			$app->parse_job_server_address($address);
		}, qr{Unable to parse address}, 'invalid address');
	}
}


sub mock_gearman {
	my ($self, $port) = @_;

	my $sock = IO::Socket::INET->new(
		Listen    => 5,
		LocalAddr => 'localhost',
		LocalPort => $port,
		Proto     => 'tcp',
		ReuseAddr => 1,
	);
	while (my $res = $sock->accept()) {
		while (my $line = $res->getline()) {
			if (index($line, 'workers') == 0) {
				$res->print("8432 192.168.0.1 - : job\n.\n");
			}
			elsif (index($line, 'status') == 0) {
				$res->print("add 1       2       3\n.\n");
			}
			elsif (index($line, 'version') == 0) {
				$res->print("0.13\n");
			}
		}
	}
}

1;
