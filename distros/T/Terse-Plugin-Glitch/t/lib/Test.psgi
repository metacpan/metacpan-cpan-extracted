#!/usr/bin/perl
use strict;
use warnings;
use Terse;
use Test::App;
my $api = Test::App->start();
sub {
	my ($env) = (shift);
	Terse->run(
		plack_env => $env,
		application => $api,
		logger => Terse->new(
			info => sub {
				warn "info log line: " . $_[1]->{message} . "\n";
			},
			err => sub {
				warn "error log line: " . $_[1]->{message} . "\n";
			}
		)
	);
}
