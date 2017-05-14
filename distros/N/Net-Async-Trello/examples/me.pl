#!/usr/bin/env perl 
use strict;
use warnings;
use feature qw(say);

use IO::Async::Loop;
use Net::Async::Trello;

use JSON::MaybeXS;
# use Log::Any::Adapter qw(Stdout);

binmode STDOUT, ':encoding(UTF-8)';

my ($key, $secret, $token, $token_secret) = @ARGV;
die "need oauth app info" unless $key and $secret;
die "need oauth token" unless $token and $token_secret;

my $loop = IO::Async::Loop->new;
$loop->add(
	my $trello = Net::Async::Trello->new(
		key          => $key,
		secret       => $secret,
		token        => $token,
		token_secret => $token_secret,
	)
);

my $json = JSON::MaybeXS->new(pretty => 1);
$trello->me->then(sub {
	my ($me) = @_;
	printf "Name:     %s\n", $me->full_name;
	printf "Initials: %s\n", $me->initials;
	printf "Username: %s\n", $me->username;
	printf "Email:    %s\n", $me->email // '(none)';
	printf "Avatar:   %s\n", $me->avatar_source;
	printf "Status:   %s\n", $me->status;
	Future->done;
})->get;

