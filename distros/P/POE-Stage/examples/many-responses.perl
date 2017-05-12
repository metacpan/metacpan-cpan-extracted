#!/usr/bin/perl
# $Id: many-responses.perl 146 2007-01-07 06:51:22Z rcaputo $

# Illustrate the pattern of many responses for one request.

# We cannot use App->new()->run() here because the main App receives
# many requests before the main loop starts.  In light of the new
# syntax, we probably should have a single App->run() entry point that
# fires all the requests rather than doing it from package main.

{
	# The application is itself a POE::Stage;

	package App;

	use POE::Stage::Ticker;
	use POE::Stage::App qw(:base self);

	sub init :Handler {
		my $self_name = my $arg_name;
	}

	sub on_run {
		my ($arg_name, $arg_interval);

		my $req_ticker = POE::Stage::Ticker->new();
		my $req_name = $arg_name || "unnamed";
		my $req_interval = $arg_interval || 0.001;

		my $req_ticker_request = POE::Request->new(
			stage       => $req_ticker,
			method      => "start_ticking",
			on_tick     => "handle_tick",
			args        => {
				interval  => $req_interval,
			},
		);
	}

	sub handle_tick :Handler {
		my $arg_id;
		my $req_name;
		my $self_name;

		print(
			"app($self_name) ",
			"request($req_name) ",
			"handled tick $arg_id\n"
		);
	}
}

my $app_1 = App->new( name => "app_one" );

my $req_1_1 = POE::Request->new(
	stage   => $app_1,
	method  => "on_run",
	args    => {
		name  => "req_one",
	},
);

my $req_1_2 = POE::Request->new(
	stage   => $app_1,
	method  => "on_run",
	args    => {
		name  => "req_two",
	},
);

my $app_2 = App->new( name => "app_two" );

my $req_2 = POE::Request->new(
	stage   => $app_2,
	method  => "on_run",
	args    => {
		name  => "req_one",
	},
);

my $req_2_2 = POE::Request->new(
	stage   => $app_2,
	method  => "on_run",
	args    => {
		name  => "req_two",
	},
);

POE::Kernel->run();
exit;
