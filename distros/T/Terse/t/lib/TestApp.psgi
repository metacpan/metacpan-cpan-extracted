#!/usr/bin/perl
use strict;
use warnings;
use Terse;
use TestApp;
sub {
	my ($env) = (shift);
	Terse->run(
		plack_env => $env,
		application => TestApp->new(),
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
