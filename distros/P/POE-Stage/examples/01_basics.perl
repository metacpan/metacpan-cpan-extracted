#!perl
# $Id: 01_basics.perl 200 2009-07-27 05:01:45Z rcaputo $

# Simple call and return in POE::Stage.

# Define a simple class that does something and returns a value.

{
	package Helper;
	use POE::Stage qw(:base self req);

	sub on_init { undef }

	sub do_something :Handler {
		print "Helper (", self, ") is executing a request.\n";
		req->emit(args => { value => "EmitValue123" });
		req->return(args => { value => "ReturnValueXyz" });
	}
}

# Define an application class to use the helper.

{
	package App;
	use POE::Stage::App qw(:base expose);

	sub on_init { undef }

	sub on_run {
		my $req_helper = Helper->new();
		my $req_helper_request = POE::Request->new(
			stage     => $req_helper,
			method    => "do_something",
			on_return => "catch_return",
			on_emit   => "catch_emit",
		);

		my (%req_hash, @req_array);
		%req_hash = ( abc => 123, xyz => 890 );
		@req_array = qw( a e i o u y );

		print "App: Calling $req_helper via $req_helper_request\n";

		# This is passed back in the response context to $helper_request.
		expose $req_helper_request => my $hr_name;
		$hr_name = "test response context";
	}

	sub catch_return :Handler {
		my (
			$arg_value,
			$req_helper, $req_helper_request, %req_hash, @req_array,
			$rsp_name,
		);

		print(
			"App return: return value '$arg_value'\n",
			"App return: $req_helper was called via $req_helper_request\n",
			"App return: hash keys: ", join(" ", keys %req_hash), "\n",
			"App return: hash values: ", join(" ", values %req_hash), "\n",
			"App return: array: @req_array\n",
			"App return: rsp: $rsp_name\n",
		);
	}

	sub catch_emit :Handler {
		my (
			$arg_value,
			$req_helper, $req_helper_request, %req_hash, @req_array,
			$rsp_name,
		);

		print(
			"App emit: return value '$arg_value'\n",
			"App emit: $req_helper was called via $req_helper_request\n",
			"App emit: hash keys: ", join(" ", keys %req_hash), "\n",
			"App emit: hash values: ", join(" ", values %req_hash), "\n",
			"App emit: array: @req_array\n",
			"App emit: rsp name = $rsp_name\n",
		);

		$rsp_name = "modified in catch_emit";
	}
}

# Create and start the application.

App->new()->run();
exit;

__END__

App: Calling Helper=HASH(0x18d82fc) via POE::Request=ARRAY(0x181d03c)
Helper (Helper=HASH(0x18d82fc)) is executing a request.
App emit: return value 'EmitValue123'
App emit: Helper=HASH(0x18d82fc) was called via POE::Request=ARRAY(0x181d03c)
App emit: hash keys: abc xyz
App emit: hash values: 123 890
App emit: array: a e i o u y
App emit: rsp name = test response context
App return: return value 'ReturnValueXyz'
App return: Helper=HASH(0x18d82fc) was called via POE::Request=ARRAY(0x181d03c)
App return: hash keys: abc xyz
App return: hash values: 123 890
App return: array: a e i o u y
App return: rsp: modified in catch_emit
