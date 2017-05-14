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
	my @chan;
	say "Total of " . (0 + @_) . " jobs";
	for my $job (@_) {
		printf "%9d %-6.6s %-12.12s %-48.48s %s %s\n",
			$job->id,
			$job->number,
			$job->state,
			$job->repository_slug,
			$job->started_at // '',
			$job->finished_at // '';
		push @chan, 'private-job-' . $job->id;
	}
	$gh->pusher_auth(
		channels => \@chan
	)->then(sub {
		my ($chan) = @_;
		$gh->pusher->then(sub {
			my ($pusher) = @_;
			Future->wait_all(
				map $pusher->open_channel(
					$_,
					auth => $chan->{$_}
				)->then(sub {
					my ($ch) = @_;
					$ch->subscribe('job:log' => sub {
						my ($ev, $data) = @_;
						print $data->{_log};
#						warn "Job log event: @_"
					})
				}), keys %$chan
			)
		})
	})
})->get;

$loop->run;
