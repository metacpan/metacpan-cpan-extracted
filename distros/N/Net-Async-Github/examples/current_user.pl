#!/usr/bin/env perl
use strict;
use warnings;

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

my $user = $gh->current_user->get;
printf "User [%s] has %d public repos and was last updated on %s%s\n",
    $user->login,
    $user->public_repos,
    $user->updated_at->to_string,
    ($user->hireable ? " (available for hire!)" : "")
;


