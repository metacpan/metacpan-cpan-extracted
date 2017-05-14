#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(say);

use IO::Async::Loop;
use Net::Async::Github;
use Time::Duration;

# use Log::Any::Adapter qw(Stdout);

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

$gh->users
    ->each(sub {
        printf "User [%s] has %d public repos and was last updated on %s%s\n",
            $_->login,
            $_->public_repos // 0,
            $_->updated_at ? $_->updated_at->to_string : '(unknown)',
            ($_->hireable ? " (available for hire!)" : "")
    })->await;
;


