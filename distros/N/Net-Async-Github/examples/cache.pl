#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(say);

use IO::Async::Loop;
use Net::Async::Github;
use Time::Duration;

use Log::Any::Adapter qw(Stdout), log_level => 'info';

my $token = shift or die "need a token";
my $loop = IO::Async::Loop->new;
$loop->add(
	my $gh = Net::Async::Github->new(
		token => $token,
	)
);

$gh->core_rate_limit->remaining->subscribe(sub {
    printf "Have %d Github requests remaining\n", $_;
});

say "First request should hit the API";
$gh->repos
    ->take(1)
    ->each(sub {
        printf "* %s has %d open issues and %d forks\n",
            $_->name,
            $_->open_issues_count,
            $_->forks_count;
    })
    ->await;

say "Second request should hit the cache - your rate limit quota should not be affected";
$gh->repos
    ->take(1)
    ->each(sub {
        printf "* %s has %d open issues and %d forks\n",
            $_->name,
            $_->open_issues_count,
            $_->forks_count;
    })
    ->await;

