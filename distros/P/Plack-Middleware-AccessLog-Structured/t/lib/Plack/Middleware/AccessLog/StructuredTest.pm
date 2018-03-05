package Plack::Middleware::AccessLog::StructuredTest;
use parent qw(Test::Class);

use strict;
use warnings;

use Carp;
use Test::More;
use Test::Exception;
use Test::Deep;

use Plack::Test;
use HTTP::Request::Common;
use Plack::Middleware::AccessLog::Structured;
use JSON;

sub basic_log_test : Test(6) {
	my ($self) = @_;

	# App which returns array reference
	my $app = sub { [200, ['Content-Type' => 'text/plain'], ['ok']] };
	my @log;
	my $wrapped_app = Plack::Middleware::AccessLog::Structured->wrap($app,
		logger  => sub {
			push @log, @_;
		},
	);

	test_psgi($wrapped_app, sub {
		my ($cb) = @_;
		my $response = $cb->(GET '/', Referer => 'http://localhost/foo');
		is($response->code(), 200, 'application executed');
	});

	is(scalar @log, 1, 'message count ok');
	my $expected_log_message = {
		class            => 'Plack::Middleware::AccessLog::Structured',
		hostfqdn         => re('^[\w\.-]+$'),
		hostname         => re('^[\w\.-]+$'),
		http_host        => 'localhost',
		http_user_agent  => undef,
		http_referer     => 'http://localhost/foo',
		remote_user      => undef,
		pid              => $$,
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
	};
	cmp_deeply(decode_json($log[0]), $expected_log_message, 'log message ok');
	undef @log;

	# App which returns callback
	$app = sub { sub { $_[0]->([200, ['Content-Type' => 'text/plain'], ['ok']]) } };
	$wrapped_app = Plack::Middleware::AccessLog::Structured->wrap($app,
		logger  => sub {
			push @log, @_;
		},
	);
	test_psgi($wrapped_app, sub {
		my ($cb) = @_;
		my $response = $cb->(GET '/', Referer => 'http://localhost/foo');
		is($response->code(), 200, 'application executed');
	});

	is(scalar @log, 1, 'message count ok');
	cmp_deeply(decode_json($log[0]), $expected_log_message, 'log message ok');
}


sub callback_test : Test(4) {
	my ($self) = @_;

	my $app = sub { [200, [], ['ok']] };
	my @log;
	my $wrapped_app = Plack::Middleware::AccessLog::Structured->wrap($app,
		callback => sub {
			my ($env, $message) = @_;
			$message->{test_value} = 'bar';
			$message->{copied_value} = $env->{'psgi.url_scheme'};
			return $message;
		},
		logger  => sub {
			push @log, @_;
		},
	);

	test_psgi($wrapped_app, sub {
		my ($cb) = @_;
		my $response = $cb->(GET '/');
		is($response->code(), 200, 'application executed');
	});

	is(scalar @log, 1, 'message count ok');
	my $message = decode_json($log[0]);
	is($message->{test_value}, 'bar', 'test_value added');
	is($message->{copied_value}, 'http', 'value from PSGI env copied');
}


sub extra_field_test : Test(3) {
	my ($self) = @_;

	my $app = sub { [200, [], ['ok']] };
	my @log;
	my $wrapped_app = Plack::Middleware::AccessLog::Structured->wrap($app,
		extra_field => { 'psgi.url_scheme' => 'my_url_scheme' },
		logger  => sub {
			push @log, @_;
		},
	);

	test_psgi($wrapped_app, sub {
		my ($cb) = @_;
		my $response = $cb->(GET '/');
		is($response->code(), 200, 'application executed');
	});

	is(scalar @log, 1, 'message count ok');
	my $message = decode_json($log[0]);
	is($message->{my_url_scheme}, 'http', 'value from PSGI env copied');
}


sub parameter_validation_test : Test(2) {
	my ($self) = @_;

	throws_ok(
		sub {
			Plack::Middleware::AccessLog::Structured->wrap(sub {},
				callback => 'foo',
			);
		},
		qr{Passed 'callback' parameter must be a code reference},
		'callback must be undef or coderef'
	);

	throws_ok(
		sub {
			Plack::Middleware::AccessLog::Structured->wrap(sub {},
				extra_field => 'foo',
			);
		},
		qr{Passed 'extra_field' parameter must be a hash reference},
		'extra_field must be undef or hashref'
	);
}


sub delayed_duration_test : Test(3) {
	my ($self) = @_;

	my $app = sub {
		my ($env) = @_;
		return sub {
			my ($responder) = @_;
			note 'sleeping for a second';
			sleep 1;
			$responder->([ 200, [ ], ['delayed'] ]);
		}
	};
	my @log;
	my $wrapped_app = Plack::Middleware::AccessLog::Structured->wrap($app,
		logger  => sub {
			push @log, @_;
		},
	);

	test_psgi($wrapped_app, sub {
		my ($cb) = @_;
		my $response = $cb->(GET '/');
		is($response->code(), 200, 'application executed');
	});

	is(scalar @log, 1, 'message count ok');
	my $data = decode_json($log[0]);
	cmp_ok($data->{request_duration}, '>', 1000.0,
		'request_duration works for delayed responses');
}


1;
