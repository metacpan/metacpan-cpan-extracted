#!/usr/bin/perl
# $Id: 01_all_call_types.t 201 2009-07-28 06:39:31Z rcaputo $
# vim: filetype=perl

use warnings;
use strict;

use Test::More tests => 19;

my $go_req;
my $key_value;

# Examine one of each call type.

{
	package Something;
	use warnings;
	use strict;
	use POE::Stage qw(:base req rsp);
	use Test::More;

	sub on_init { undef }

	sub on_do_emit {
		ok(
			ref(req) eq "POE::Request",
			"do_emit req is a POE::Request object"
		);

		ok(
			req->get_id() == $go_req->get_id(),
			"do_emit req (" .  req->get_id() .
			") should match go_req (" . $go_req->get_id() . ")"
		);

		ok(
			rsp == 0,
			"do_emit rsp is zero"
		);

		# TODO - Don't bleed the requestor's state into the requestee.

		my $req_key;
		ok(
			!defined($req_key),
			"do_emit key should not be defined" . (
				defined($req_key)
				? " (let alone be $req_key)"
				: ""
			)
		);

		my $req_newkey = my $self_original_newkey = 8675;

		req->emit(  );
		#req->emit( type => "emit" );
	}

	sub on_do_return {
		ok(
			ref(req) eq "POE::Request",
			"do_return req is a POE::Request object"
		);

		ok(
			req->get_id() == $go_req->get_id(),
			"do_return req (" . req->get_id() . ") should match go_req (" .
			$go_req->get_id() . ")"
		);

		ok(
			rsp == 0,
			"do_return rsp is zero"
		);

		# TODO - Don't bleed the requestor's state into the requestee.

		my $req_key;
		ok(
			!defined($req_key),
			"do_return req.key should not be defined" . (
				defined($req_key)
				? " (let alone be $req_key)"
				: ""
			)
		);

		my $req_newkey;
		ok(
			my $self_original_newkey == $req_newkey,
			"do_return original_newkey should match req.newkey"
		);

		req->return();
		#req->return( type => "return" );
	}
}

{
	package App;
	use warnings;
	use strict;
	use POE::Stage qw(:base req rsp expose);

	use Test::More;

	sub on_init { undef }

	sub on_run {
		my $req_something = Something->new();
		my $req_go = POE::Request->new(
			stage     => $req_something,
			method    => "do_emit",
			on_emit   => "do_recall",
			on_return => "do_return",
		);

		# Save the original req for comparison later.
		my $self_original_req = req;
		$go_req = my $self_original_sub = $req_go;
		expose $req_go => my $exposed_key;
		$key_value = my $self_original_key = $exposed_key = 309;
	}

	sub do_recall :Handler {
		ok(
			ref(req) eq "POE::Request",
			"emit req is a POE::Request object"
		);

		ok(
			ref(rsp) eq "POE::Request::Emit",
			"emit rsp is a POE::Request::Emit object"
		);

		my $self_original_req;
		ok(
			req->get_id() == $self_original_req->get_id(),
			"emit req (" . req->get_id() . ") should match original (" .
			$self_original_req->get_id() . ")"
		);

		my $self_original_sub;
		ok(
			rsp->get_id() == $self_original_sub->get_id(),
			"emit rsp (" . rsp->get_id() . ") should match original (" .
			($self_original_sub->get_id()) . ")"
		);

		my $rsp_key;
		my $self_original_key;
		ok(
			$rsp_key == $self_original_key,
			"emit rsp.key ($rsp_key) should match original ($self_original_key)"
		);

		rsp->recall( method => "do_return" );
	}

	sub do_return :Handler {
		ok(
			ref(req) eq "POE::Request",
			"ret req is a POE::Request object"
		);

		ok(
			ref(rsp) eq "POE::Request::Return",
			"ret rsp is a POE::Request::Return object"
		);

		my $self_original_req;
		ok(
			req->get_id() == $self_original_req->get_id(),
			"ret req (" . req->get_id() . ") should match original (" .
			$self_original_req->get_id() . ")"
		);

		my $self_original_sub;
		ok(
			rsp->get_id() == $self_original_sub->get_id(),
			"ret rsp (" . rsp->get_id() . ") " .
			"should match original sub (" . $self_original_sub->get_id() . ")"
		);

		my $rsp_key;
		my $self_original_key;
		ok(
			$rsp_key == $self_original_key,
			"ret key ($rsp_key) " .
			"should match original ($self_original_key)"
		);

		# Actually does nothing.
	}
}

my $app = App->new();
my $req = POE::Request->new(
	stage  => $app,
	method => "run",
);

POE::Kernel->run();
exit;
