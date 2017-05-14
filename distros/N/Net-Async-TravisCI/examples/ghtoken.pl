#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(say);

use IO::Async::Loop;
use Net::Async::TravisCI;
use Time::Duration;

use Log::Any::Adapter qw(Stdout);

my $token = shift or die "need a token";
my $loop = IO::Async::Loop->new;
$loop->add(
	my $gh = Net::Async::TravisCI->new(
	)
);

$gh->github_token(
	token => $token
)->on_done(sub {
	say "Your access token is " . shift;
})->get;
