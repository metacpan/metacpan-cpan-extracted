#!perl
# $Id: attributes.perl 200 2009-07-27 05:01:45Z rcaputo $

# Show how lexical aliasing works in subs with the :Handler attribute.
# Sample run output is after __END__.

# Every application needs at least one POE::Stage object, and an
# initial request must be fired at it to get things rolling.

ExampleApp->new()->run();
exit;

# The example application.  It highlights POE::Stage's syntactical
# sugar.

{
	package ExampleApp;

	# The :base export adds POE::Stage to the calling package's @ISA.
	#
	# self, req, and rsp may also be exported.  These always return the
	# current POE::Stage object, the current POE::Request being handled,
	# and the current POE::Response being received (when applicable).
	#
	# They're used for method calls on those objects, in cases where you
	# don't want to declare $self, $req, or $rsp.

	use POE::Stage::App qw(:base self req expose);

	sub on_init { undef }

	sub on_run {

		# Variables with the self_ prefix expose members of the current
		# POE::Stage object.  $self_foo is the scalar member '$foo'.  The
		# duration of these members is the lifetime of the POE::Stage they
		# belong to.  The scope is any handler that's a method of that
		# stage.  Simply redeclare the variables in each handler where
		# they're needed.
		#
		# In this case, the equivalent of $self->{'$memb'} is declared and
		# initialized.

		my $self_memb = "current POE::Stage member";
		warn "run: member($self_memb)\n";

		# The req_ variable prefix allows code to declare lexicals that
		# represent data members of the currently handled POE::Request.
		# The contents of request members are availale from any method
		# executed within that request's context.
		#
		# In this case, a sub-request is created and stored in the current
		# request.  If the current request is canceled for any reason, it
		# should trigger destruction of the sub-request when the current
		# one is destroyed.

		my $req_subreq = POE::Request->new(
			stage => self,
			method => 'other',
			on_return => 'handle_return',
		);

		# The current request is given a data member ($moo), which is also
		# initialized.

		my $req_moo = "moo in the request";
		warn "run: req.moo($req_moo)\n";

		# A data member of the sub-request is exposed as $req_subreq.  The
		# expose() function takes an object and one or more lexicals.  The
		# lexicals must have prefixes, which are used to differentiate
		# them from other lexicals in the same scope.  The data members
		# exposed are the base names for the lexicals.  $foo_one,
		# @whee_two, %bishop_three expose the object's $one, @two, and
		# %three members;
		#
		# This allows a requester to tack context onto the request in such
		# a way that it's available when responses are handled.  See the
		# handle_return() use of :Rsp for details on getting the data back
		# out of a response.

		expose $req_subreq => my $exposed_moo;
		$exposed_moo = "in the sub-request";
		warn "run: subreq.moo($exposed_moo)\n";
	}

	# Handle the "other" request.  Since the method is in the same
	# POE::Stage, it will have the value previously stored within it.
	# This method is executed as a handler for a sub-request, however,
	# so its "current" request is different from that of run()'s.

	sub other :Handler {

		# $self_memb exposes a member of the current POE::Stage.  It takes
		# on the current value of self's '$memb' member because nothing is
		# assigned to it.

		my $self_memb;
		warn "other: member($self_memb)\n";

		# $req_moo is the '$moo' member of the current request.  Like
		# $self_memb above, nothing is stored into it, so it takes on the
		# member's previous value.  In this case, however, the "current"
		# request is $req_subreq from run().

		my $req_moo;
		warn "other: req.moo($req_moo)\n";

		# Return a response for the current request, along with a value
		# that will be passed to the response handler as an argument.  The
		# imported req() function represents the request itself, and it's
		# used to call methods on this request.
		#
		# The request's return() method takes at least two named
		# parameters: type and args.
		#
		# The type parameter determines the return type, and is used to
		# look up the appropriate handler.  It defaults to "return", which
		# is fine for current purposes.
		#
		# The args parameter is a hashref of named arguments that will be
		# passed to the return handler.  In this case, the following
		# handle_return() method.
		#
		# And if you haven't guessed already, handle_return() is called to
		# handle type => "return" messages because the original request
		# mapped on_return to that method.

		req->return(args => { something => "returned value" });
	}

	# Finally we handle the return value.  This example shows how to
	# accept return values and to access data stored in the context of
	# the original request.

	sub handle_return :Handler {
		# Once again, $self_memb is a member of the current POE::Stage
		# object.

		my $self_memb;
		warn "handle_return: member($self_memb)\n";

		# The arg_ prefix is used to refer to arguments passed into this
		# method.  In this case, the 'something' argument.  Unlike almost
		# everywhere else, however, the $arg member does not have a
		# leading sigil.  Otherwise you'd need to supply it in your
		# requests.

		my $arg_something;
		warn "handle_return: arg.something($arg_something)\n";

		# The current request is the one that invoked this stage's run()
		# method.

		my $req_moo;
		warn "handle_return: req.moo($req_moo)\n";

		# There is a response context since this method is invoked to
		# handle a response to a previous request.  In this case, the rsp_
		# prefix indicates that a lexical aliases members in the current
		# response object.  That object is the response to our original
		# $req_subreq.
		#
		# And so the magic cookie sent with the request is available to
		# the response's handler because we're not assigning to $rsp_moo.
		# The circle is complete.

		my $rsp_moo;
		warn "handle_return: rsp.moo($rsp_moo)\n";
	}
}

__END__

1) poerbook:~/projects/poe-stage% perl -Ilib examples/attributes.perl

run: member(current POE::Stage member)
run: req.moo(moo in the request)
run: subreq.moo(in the sub-request)
other: member(current POE::Stage member)
other: req.moo(in the sub-request)
handle_return: member(current POE::Stage member)
handle_return: arg.something(returned value)
handle_return: req.moo(moo in the request)
handle_return: rsp.moo(in the sub-request)
