#!/usr/bin/env perl 
use strict;
use warnings;

use IO::Async::Loop;
use Net::Async::Trello;

use Log::Any::Adapter qw(Stdout), log_level => 'trace';

use Getopt::Long;

binmode STDOUT, ':encoding(UTF-8)';

GetOptions(
	'key=s'          => \my $key,
	'secret=s'       => \my $secret,
	'token=s'        => \my $token,
	'token_secret=s' => \my $token_secret,
);
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

$trello->boards
	->map(sub {
		sprintf "%s %-32.32s %-64.64s %s", $_->id, $_->name, $_->desc, $_->url;
	})
	->say
	->await;
