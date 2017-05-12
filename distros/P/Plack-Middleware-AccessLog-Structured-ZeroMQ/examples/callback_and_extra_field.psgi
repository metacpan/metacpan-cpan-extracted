#!/usr/bin/env plackup

use warnings;
use strict;

use Plack::Middleware::AccessLog::Structured::ZeroMQ;

my $app = sub {
	my ($env) = @_;
	$env->{'some.application.field'} = 'Example Value';
	[200, ['Content-Type' => 'text/plain'], ['ok']]
};

Plack::Middleware::AccessLog::Structured::ZeroMQ->wrap($app,
	connect     => 'tcp://127.0.0.1:5552',
	callback    => sub {
		my ($env, $message) = @_;
		$message->{foo} = 'bar';
		return $message;
	},
	extra_field => {
		'some.application.field' => 'log_field',
		'some.psgi-env.field'    => 'another_log_field',
	},
);
