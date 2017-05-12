#!/usr/bin/perl
# $Id: self-requesting-stage.perl 172 2008-12-05 07:57:10Z rcaputo $

# Create a very simple stage that performs a task and returns a
# mesage.  The magic here is that the stage makes its own request in
# init() so the creator isn't required to go through the two-step
# create/request dance.

{
	package SelfRequester;
	use POE::Stage qw(:base self);
	use POE::Watcher::Delay;

	# The "init" request, rather than returning immeditately, is passed
	# on to the rest of the stage for further processing.

	sub init :Handler {
		my $args = $_[1];

#		my $self_request = 
		my $req;

		warn "selfrequester on_init";

		my $passthrough_args = delete $args->{args} || {};
		use YAML; warn YAML::Dump($passthrough_args);
		$req->pass_to(
			{
				args => $passthrough_args,
				method => "set_thingy",
			}
		);
	}

	sub set_thingy :Handler {
		my $arg_seconds;
		warn "selfrequester set_thingy";

		my $req_delay = POE::Watcher::Delay->new(
			seconds     => $arg_seconds,
			on_success  => "time_is_up",
		);
	}

	sub time_is_up :Handler {
		my $req;
		warn "selfrequester time_is_up";

		$req->return(
			type => "done",
		);

		# Don't need to delete these as long as the request is canceled,
		# either by calling req->return() on ->cancel().
		#$self_auto_request = undef;
		#my $req_delay = undef;
	}
}

{
	package App;
	use POE::Stage::App qw(:base self);

	sub on_run {
		warn "app on_run";
		my $req->pass_to( { method => "spawn_requester" } );
	}

	sub on_selfrequester_done {
		warn "app do_again";
		my $req->pass_to( { method => "spawn_requester" } );
	}

	sub on_spawn_requester {
		warn "app spawn_requester";

		my $req_requester = SelfRequester->new(
			role      => "selfrequester",
			args      => {
				seconds => 0.001,
			},
		);
	}
}

package main;

App->new()->run();
exit;
