#!/usr/bin/perl -w

# 01basic.t -- Basic testing. Makes a single request

# uncomment to get POE's debug output
# sub POE::Kernel::ASSERT_DEFAULT() { 1 }
# sub POE::Kernel::TRACE_DEFAULT() { 1 }

use strict;
use POE;
use POE::Component::Client::UserAgent;
use Test;

BEGIN { plan tests => 4 }

my $debuglevel = shift || 0;

POE::Component::Client::UserAgent::debug $debuglevel => '01basic.log' if $debuglevel;

my $url = 'http://www.hotmail.com/';

POE::Session -> create (
	inline_states => {
		_start => \&_start,
		_stop => \&_stop,
		response => \&response,
	},
);

$poe_kernel -> run;

warn "%%% Kernel::run returned.\n" if $debuglevel >= 3;

ok 1;

exit 0;

sub _start
{
	warn "%%% Start event arrived.\n" if $debuglevel >= 3;
	warn "%%% Starting POE::Component::Client::UserAgent...\n" if $debuglevel >= 3;
	POE::Component::Client::UserAgent -> new(env_proxy => 1);
	warn "%%% Sending a test request...\n" if $debuglevel >= 3;
	$_[KERNEL] -> post (useragent => request =>
		request => HTTP::Request -> new (GET => $url),
		response => $_[SESSION] -> postback ('response')
	);
	ok 1;
}

sub _stop
{
	warn "%%% Stop event arrived.\n" if $debuglevel >= 3;
	ok 1;
}

sub response
{
	my ($request, $response, $entry) = @{$_[ARG1]};
	LWP::Debug::trace ("\n\t$request\n\t$response\n\t$entry");
	warn "%%% Response returned.\n" if $debuglevel >= 3;
	warn "%%% Shutting down POE::Component::Client::UserAgent...\n"
		if $debuglevel >= 3;
	$_[KERNEL] -> post (useragent => 'shutdown') unless $response -> is_redirect;
	warn $request -> url -> as_string . "\n\t" . $response -> code .
		' ' . $response -> message . "\n" if $debuglevel >= 1;
	ok 1 unless $response -> is_redirect;
}
