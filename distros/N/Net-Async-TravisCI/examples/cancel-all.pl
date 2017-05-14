#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(say);

use IO::Async::Loop;
use Net::Async::TravisCI;
use Time::Duration;

use Log::Any::Adapter qw(Stdout), log_level => 'info';

binmode STDOUT, ':encoding(UTF-8)';

my $token = shift or die "need a token";
my $loop = IO::Async::Loop->new;
$loop->add(
	my $gh = Net::Async::TravisCI->new(
		token => $token,
	)
);

my $json = JSON::MaybeXS->new(pretty => 1);
say "Pusher API key is " . $gh->config->get->pusher->{key};

$gh->jobs(
)->then(sub {
	Future->needs_all(
		map $gh->cancel_job($_), @_
	)
})->get;

$loop->run;
