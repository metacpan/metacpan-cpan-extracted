#!/usr/bin/env perl 
use strict;
use warnings;
use feature qw(say);

use IO::Async::Loop;
use Net::Async::Trello;

use JSON::MaybeXS;
use Log::Any::Adapter qw(Stdout), log_level => 'trace';

use Getopt::Long;

binmode STDOUT, ':encoding(UTF-8)';

GetOptions(
	'key=s'          => \my $key,
	'secret=s'       => \my $secret,
	'token=s'        => \my $token,
	'token_secret=s' => \my $token_secret,
	'board=s'        => \my $board_id,
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

my $cmd = shift or die 'need a command';
Future->needs_all(
    $trello->me,
    $trello->board(id => $board_id)
)->then(sub {
	my ($me, $board) = @_;
	printf "Name:     %s\n", $me->full_name;

    $board->$cmd
        ->sprintf_methods('ID %s - %s', qw(id name))
        ->say
        ->completed
})->get;

