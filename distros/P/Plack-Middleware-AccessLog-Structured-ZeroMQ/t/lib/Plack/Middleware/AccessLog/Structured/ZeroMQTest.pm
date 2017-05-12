package Plack::Middleware::AccessLog::Structured::ZeroMQTest;
use parent qw(Test::Class);

use strict;
use warnings;

use Carp;
use Test::More;
use Test::Deep;
use Test::TCP;

use AnyEvent;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Middleware::AccessLog::Structured::ZeroMQ;
use Message::Passing::Output::Test;
use Message::Passing::Filter::Decoder::JSON;
use Message::Passing::Input::ZeroMQ;

sub basic_log_test : Test(2) {
	my ($self) = @_;

	my $connect = 'tcp://127.0.0.1:'.empty_port();
	my $pid = fork();
	if ($pid) {
		my $input = $self->create_input($connect);

		is($input->output_to()->output_to()->message_count(), 1, 'message count ok');
		cmp_deeply(
			[$input->output_to()->output_to()->messages()],
			[{
				class            => 'Plack::Middleware::AccessLog::Structured::ZeroMQ',
				hostfqdn         => re('^[\w\.-]+$'),
				hostname         => re('^[\w\.-]+$'),
				http_host        => 'localhost',
				http_user_agent  => undef,
				http_referer     => 'http://localhost/foo',
				remote_user      => undef,
				pid              => $pid,
				remote_addr      => '127.0.0.1',
				request_duration => re('^\d+\.\d+$'),
				request_method   => 'GET',
				request_uri      => '/',
				response_status  => 200,
				content_length   => 2,
				content_type     => 'text/plain',
				server_protocol  => 'HTTP/1.1',
				date             => re('^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$'),
				epochtime        => re('^\d+(?:\.\d+)?$')
			}],
			'log message ok'
		);
	}
	elsif (defined $pid) {
		my $app = sub { [200, ['Content-Type' => 'text/plain'], ['ok']] };

		my $wrapped_app = Plack::Middleware::AccessLog::Structured::ZeroMQ->wrap($app,
			connect => $connect,
		);

		test_psgi($wrapped_app, sub {
			my ($cb) = @_;
			my $response = $cb->(GET '/', Referer => 'http://localhost/foo');
		});

		exit;
	}
	else {
		die 'Failed to fork';
	}
}


sub create_input {
	my ($self, $connect) = @_;

	my $cv = AnyEvent->condvar();
	my $input = Message::Passing::Input::ZeroMQ->new(
		socket_bind => $connect,
		output_to   => Message::Passing::Filter::Decoder::JSON->new(
			output_to => Message::Passing::Output::Test->new(
				cb => sub { $cv->send() },
			),
		),
	);
	$cv->recv();

	return $input;
}

1;
