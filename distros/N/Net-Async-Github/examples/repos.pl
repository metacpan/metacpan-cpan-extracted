#!/usr/bin/env perl
use strict;
use warnings;

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

# Show lots of information about repos
my $user = $gh->current_user->get;
my $repos = $gh->repos(
    owner => $user->login
)
# ... and aggregate stats
    ->apply(sub {
        $_->sprintf_methods("* %s has %d open issues and %d forks", qw(name open_issues_count forks_count))
            ->say
    }, sub {
        $_->count
            ->each(sub {
                printf "Total of %d repos found\n", $_;
            })
    }, sub {
        $_->map('open_issues_count')
            ->sum
            ->each(sub {
                printf "Total of %d open issues found\n", $_;
            })
    }, sub {
        $_->map('forks_count')
            ->sum
            ->each(sub {
                printf "Total of %d forks found\n", $_;
            })
    })
# also get branch info
    ->apply(sub {
        $_->flat_map('branches')
            ->sprintf_methods("=> has a branch called %s", qw(name))
            ->say;
    })
    ->await;

