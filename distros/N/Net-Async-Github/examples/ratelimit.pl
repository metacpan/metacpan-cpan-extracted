#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(say);

use IO::Async::Loop;
use Net::Async::Github;
use Time::Duration;

use Log::Any::Adapter qw(Stdout), log_level => 'INFO';

my $token = shift or die "need a token";
my $loop = IO::Async::Loop->new;
$loop->add(
	my $gh = Net::Async::Github->new(
		token => $token,
	)
);

$gh->rate_limit->on_done(sub {
	my $limit = shift;
	my $core = $limit->core;
	say "There are " . $core->remaining . " requests left, and limit will expire " . from_now($core->seconds_left);
})->get;
