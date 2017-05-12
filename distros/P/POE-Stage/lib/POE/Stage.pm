# $Id: Stage.pm 201 2009-07-28 06:39:31Z rcaputo $

=head1 NAME

POE::Stage - a base class for message-driven objects

=head1 SYNOPSIS

	#!/usr/bin/env perl
	{
		package App;
		use POE::Stage::App qw(:base);
		sub on_run {
			print "hello, ", my $arg_whom, "!\n";
		}
	}
	App->new()->run( whom => "world" );
	exit;

=head1 DESCRIPTION

POE::Stage is a set of base classes for message-driven objects.  It
cleanly implements standard patterns that have emerged from years of
working with POE and POE::Component modules.

As I hope the name implies, POE::Stage objects encapsulate discrete
steps, or stages, of a larger task.  Eventually they come together to
implement programs.

For example, HTTP requests are performed in four or so distinct
stages: 1. The server's address is resolved.  2. The client
establishes a connection to the server.  3. The client transmits a
request.  4. The client receives a response.

By design, POE::Stage promotes the decomposition of tasks into
multiple, smaller stages.  If these stages are generic enough, new
tasks may be handled by reusing them in different configurations.

The hypothetical HTTP client might be a single stage composed of three
smaller ones:  A DNS resolver stage, which accepts DNS requests and
returns DNS responses.  A TCP client connection factory, which takes
socket endpoint descriptions and other parameters, and eventually
returns established connections.  Finally, there would be an HTTP
protocol stage that uses established connections to send requests and
parse responses.

These stages would be encapsulated by a higher-level HTTP client
stage.  This would accept HTTP requests and return HTTP responses
after performing the necessary steps to gather them.

This will sound familiar to anyone working with objects.

These objects are asynchronous and message-driven, however.  The base
message class, POE::Request, and its subclasses, implement a standard
request/response interface between POE::Stage objects.  Where
possible, these messages attempt to mimic simpler, more direct
call/return syntax, albeit asynchronously.  POE::Stage also provides a
powerful closure-based system for maintaining request and response
state, so you don't have to.

=cut

package POE::Stage;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '0.060';

use POE::Session;

use Attribute::Handlers;
use Carp qw(croak);
use Devel::LexAlias qw(lexalias);
use PadWalker qw(var_name);

use Hash::Util::FieldHash;
use POE::Callback;

use POE::Request::Emit;
use POE::Request::Return;
use POE::Request::Recall;
use POE::Request qw(REQ_ID);

# Field hash tracks POE::Stage's out-of-band data for each object.

sub STAGE_DATA    () { 0 }  # The stage's object-scoped data.
sub COMBINED_KEYS () { 1 }  # Temporary space for iteration.
sub REQUEST       () { 2 }  # Currently active request.
sub RESPONSE      () { 3 }  # Currently active response.
sub REQ_CONTEXTS  () { 4 }  # Contexts for each request in play.
sub REQ_INIT      () { 5 }  # The init request shares the stage's lifetime.

Hash::Util::FieldHash::fieldhash(my %private);

sub _get_request  { return $private{$_[0]}[REQUEST] }
sub _get_response { return $private{$_[0]}[RESPONSE] }
sub _set_req_rsp  { $private{$_[0]}[REQUEST]  = $_[1]; $private{$_[0]}[RESPONSE] = $_[2] }
sub _set_req_init { $private{$_[0]}[REQ_INIT] = $_[1] }

sub _self_store {
	my ($self, $key, $value) = @_;
	return $private{$self}[STAGE_DATA]{$key} = $value;
}

sub _self_fetch {
	my ($self, $key) = @_;
	return $private{$self}[STAGE_DATA]{$key};
}

sub _request_context_store {
	my ($self, $req_id, $key, $value) = @_;
	return $private{$self}[REQ_CONTEXTS]{$req_id}{$key} = $value;
}

sub _request_context_fetch {
	my ($self, $req_id, $key) = @_;
	return $private{$self}[REQ_CONTEXTS]{$req_id}{$key};
}

sub _request_context_destroy {
	my ($self, $req_id) = @_;
	delete $private{$self}[REQ_CONTEXTS]{$req_id};
}

# Track classes that use() POE::Stage, and methods with explicit
# :Handler magic (so we don't wrap them twice).

my %subclass;

sub import {
	my $class = shift();
	my $caller = caller();

	strict->import();
	warnings->import();

	$subclass{$caller} = { } unless exists $subclass{$caller};

	foreach my $export (@_) {
		no strict 'refs';

		if ($export eq ":base") {
			unshift @{ $caller . "::ISA" }, $class;
			next;
		}

		# If $class can't supply $export, check for it from __PACKAGE__.

		my $which = $class;
		unless (defined *{$which . "::$export"}) {
			$which = __PACKAGE__;
		}
		unless (defined *{$which . "::$export"}) {
			croak "Neither $class nor ", __PACKAGE__, " export $export";
		}

		*{ $caller . "::$export" } = *{ $which . "::$export" };
	}
}

# At CHECK time, find (and wrap) the methods that begin with "on_"
# with :Handler magic.  If they haven't already been wrapped.
#
# But only if they don't already have it.  Must go before
# Attribute::Handlers is loaded, otherwise A::H's check comes later.

# The missing pieces:
#
# 1 - POE::Callback (was: _add_handler_magic)
# 2 - :Handler that uses POE::Callback.
# 3 - Package wrapper magic.
# 4 - track wrappers so they aren't rewrapped
# TODO 5 - Anon coderefs are wrapped when passed to POE::Stage users.
# TODO 6 - Built-in class reloader.  Wraps reloaded classes.
# 7 - Magic at CHECK time to ensure initial wrap.

sub _wrap_package {
	my $package = shift;

	no strict 'refs';
	foreach my $symbol (values %{$package . "::"}) {
		my $sub_name = *{$symbol}{NAME};
		next unless defined($sub_name) and $sub_name =~ /^on_/;

		no warnings 'redefine';
		my $full_name = $package . '::' . $sub_name;
		*{$full_name} = POE::Callback->new(
			{
				name => $full_name,
				code => *{$symbol}{CODE},
			}
		);
	}
}

CHECK {
	foreach my $subclass (sort keys %subclass) {
		# Never subclassed...
		# TODO - Would it be good to throw a warning?
		next unless $subclass->isa(__PACKAGE__);

		_wrap_package($subclass);
	}
}

# An internal singleton POE::Session that will drive all the stages
# for the application.  This should be structured such that we can
# create multiple stages later, each driving some smaller part of the
# program.

my $singleton_session_id = POE::Session->create(
	inline_states => {
		_start => sub {
			$_[KERNEL]->alias_set(__PACKAGE__);
		},

		# Handle a request.  Map the request to a stage object/method
		# call.
		stage_request => sub {
			my $request = $_[ARG0];
			$request->deliver();
		},

		# Handle a timer.  Deliver it to its resource.
		# $resource is an envelope around a weak POE::Watcher reference.
		stage_timer => sub {
			my $resource = $_[ARG0];
			eval { $resource->[0]->deliver(); };
			die if $@;
		},

		# Handle an I/O event.  Deliver it to its resource.
		# $resource is an envelope around a weak POE::Watcher reference.
		stage_io => sub {
			my $resource = $_[ARG2];
			eval { $resource->[0]->deliver(); };
			die if $@;
		},

		# Deliver to wheels based on the wheel ID.  Different wheels pass
		# their IDs in different ARGn offsets, so we need a few of these.
		wheel_event_0 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			eval { "POE::Watcher::Wheel::$1"->deliver(0, @_[ARG0..$#_]); };
			die if $@;
		},
		wheel_event_1 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			eval { "POE::Watcher::Wheel::$1"->deliver(1, @_[ARG0..$#_]); };
			die if $@;
		},
		wheel_event_2 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			eval { "POE::Watcher::Wheel::$1"->deliver(2, @_[ARG0..$#_]); };
			die if $@;
		},
		wheel_event_3 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			eval { "POE::Watcher::Wheel::$1"->deliver(3, @_[ARG0..$#_]); };
			die if $@;
		},
		wheel_event_4 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			eval { "POE::Watcher::Wheel::$1"->deliver(4, @_[ARG0..$#_]); };
			die if $@;
		},
	},
)->ID();

sub _get_session_id {
	return $singleton_session_id;
}

=head1 RESERVED METHODS

To do its job, POE::Stage requires some methods for its own.  To be
extensible, it reserves other methods for standard purposes.  To
remain useful, it reserves the least number of methods possible.

=head2 new ARGUMENT_PAIRS

new() creates and returns a new POE::Stage object.  An optional set of
named ARGUMENT_PAIRS will be passed to the object's init() callback
before new() returns.

Subclasses should not override new() unless they're careful to call
the base POE::Stage's constructor.  Object construction is customized
through the init() callback instead.

=cut

sub new {
	my $class = shift;
	croak "$class->new(...) requires an even number of parameters" if @_ % 2;

	my %args = @_;

	my $self = bless { }, $class;
	$private{$self} = [
		{ },    # STAGE_DATA
		[ ],    # COMBINED_KEYS
		undef,  # REQUEST
		undef,  # RESPONSE
		{ },    # REQ_CONTEXTS
		undef,  # REQ_INIT
	];

	# Set the context of init() to that of a new request to the new
	# object.  Any resources created in on_init() will need to be stored
	# within $self rather than $req, otherwise they won't be visible to
	# other requests.
	#
	# The target stage is weakened immediately after the request is
	# delivered.  The request's target stage refers to the stage, and
	# the stage holds a copy of the target request.  This would be a
	# circular reference.  TODO - Investigte saving the request in the
	# creator stage.
	#
	# TODO - In theory, new() could also be given parameters that are
	# passed to the hidden request.

	my %on = map { $_ => delete $args{$_} } grep /^on_/, keys %args;

	my $req = POE::Request->new_without_send(
		stage => $self,
		%on,
		method => "on_init",
		(
			exists($args{role}) ? (role => delete($args{role})) : ()
		),
		args => \%args,
	);

	$req->deliver();
	$private{$self}[REQ_INIT] = $req;
	$req->_weaken_target_stage();

	return $self;
}

=head2 init ARGUMENT_PAIRS

init() is a callback used to initialize POE::Stage objects after they
are constructed.  POE::Stage's new() constructor passes its named
ARGUMENT_PAIRS to init() prior to returning the new object.  The
values of these arguments will be available as $arg_name lexicals
within the init() callback:

  my $object = POE::Stage::Something->new( foo => 123 );

	package POE::Stage::Something;
	sub init {
		print my $arg_foo, "\n";  # displays "123\n".
	}

The init() callback is optional.

=cut

sub init {
	# Do nothing.  Don't even throw an error.
	undef;
}

# TODO - Make these internal?

sub self {
	package DB;
	my @x = caller(1);
	return $DB::args[0];
}

sub req {
	my $stage = POE::Request->_get_current_stage();
	return $stage->_get_request();
}

sub rsp {
	my $stage = POE::Request->_get_current_stage();
	return $stage->_get_response();
}


=head2 Handler

The Handler method implements an attribute handler that defines which
methods handle messages.  Only message handlers have access to the
closures that maintain state between messages.

The Handler method is used as a subroutine attribute:

	sub some_method :Handler {
		# Lexical magic occurs here.
	}

	sub not_a_handler {
		# No lexical magic happens in this one.
	}

Methods with names beginning with "on_" acquire Handler magic
automatically.

	sub on_event {
		# Lexical magic occurs here.  No :Handler necessary.
	}

=cut

sub Handler :ATTR(CODE) {
	my ($pkg, $sym, $ref, $attr, $data, $phase) = @_;

	no strict 'refs';
	my $sub_name = *{$sym}{NAME};

	return if exists $subclass{$pkg}{$sub_name};
	$subclass{$pkg}{$sub_name} = 1;

	# FIXME - Appropriate carplevel.
	# FIXME - Is there a way to wrap anonymous coderefs?  I don't think
	# so...
	unless (defined $sub_name) {
		croak ":Handler on anonymous coderefs not supported (nor needed)";
	}

	no warnings 'redefine';
	my $full_name = $pkg . '::' . $sub_name;
	*{$full_name} = POE::Callback->new(
		{
			name => $full_name,
			code => $ref,
		}
	);
}

=head2 expose OBJECT, LEXICAL [, LEXICAL[, LEXICAL ...]]

expose() is a function (not a method) that allows handlers to expose
members of specific request or response OBJECT.  Each member will be
exposed as a particular LEXICAL variable.  OBJECTs must inherit from
POE::Request.

The LEXICAL's name is significant.  The part of the variable name up
to the leading underscore is treated as a prefix and ignored.  The
remainder of the variable name must match one of the OBJECT's member
names.  The sigil is also significant, and it is treated as part of
the member name.

The following example exposes the '$cookie' member of a POE::Request
object as the '$sub_cookie' lexical variable.  The exposed variable is
then initialized.  In doing so, the value stored into it is saved
within the request's closure.  It will be available whenever that
request (or a response to it) is visible.

	use POE::Stage qw(expose);

	sub do_request :Handler {
		my $req_subrequest = POE::Request->new( ... );
		expose $req_subrequest, my $sub_cookie;
		$sub_cookie = "stored in the subrequest";
	}

LEXICAL prefixes are useful for exposing the same member name from
multiple OBJECTs within the same lexical scope.  Otherwise the
variable names would clash.

=cut

sub expose ($\[$@%];\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%]\[$@%\[$@%\[$@%]]]\[$@%]) {
	my $request = shift;

	# Validate that we're exposing a member of a POE::Request object.

	croak "Unknown request object '$request'" unless (
		UNIVERSAL::isa($request, "POE::Request")
	);

	# Translate prefixed lexicals into POE::Request member names.  Alias
	# the members to the lexicals, creating new members as necessary.

	for (my $i = 0; $i < @_; $i++) {
		my $var_reference = $_[$i];
		my $var_name = var_name(1, $var_reference);

		unless ($var_name =~ /^([\$\@\%])([^_]+)_(\S+)/) {
			croak "'$var_name' is an illegal lexical name";
		}

		my ($sigil, $prefix, $base_member_name) = ($1, $2, $3);
		my $member_name = $sigil . $base_member_name;

		# Some prefixes fail.
		croak "can't expose $var_name" if $prefix =~ /^(arg|req|rsp|self)$/;

		my $stage = POE::Request->_get_current_stage();
		my $member_ref = $stage->_request_context_fetch(
			$request->get_id(),
			$member_name,
		);

		# Autovivify a new member.

		unless (defined $member_ref) {
			if ($sigil eq '$') {
				# Because I'm afraid to say $scalar = \$scalar.
				my $new_scalar = undef;
				$stage->_request_context_store(
					$request->get_id(),
					$member_name,
					$member_ref = \$new_scalar,
				);
			}
			elsif ($sigil eq '@') {
				$stage->_request_context_store(
					$request->get_id(),
					$member_name,
					$member_ref = [],
				);
			}
			elsif ($sigil eq '%') {
				$stage->_request_context_store(
					$request->get_id(),
					$member_name,
					$member_ref = {},
				);
			}
			else {
				croak "'$var_name' has an odd sigil";
			}
		}

		# Alias that puppy.

		lexalias(1, $var_name, $member_ref);
	}
}

1;

=head1 USING

TODO - Describe how POE::Stage is used.  Outline the general pattern
for designing and subclassing.

=head1 DESIGN GOALS

POE::Stage implements the most important and common design patterns
for POE programs in a consistent and convenient way.

POE::Stage hides nearly all of POE, including the need to create
POE::Session objects and explicitly define event names and their
handlers.  The :Handler subroutine attribute defines which methods
handle messages.  There's never a need to guess which message types
they handle:

	# Handle the "foo" message.
	sub foo :Handler {
		...
	}

POE::Stage simplifies message passing and response handling in at
least three ways.  Consider:

	my $request = POE::Request->new(
		stage => $target_stage,
		method => $target_method,
		args => \%arguments,
		on_response_x => "handler_x",
		on_response_y => "handler_y",
		on_response_z => "handler_z",
	);

First, it provides standard message clasess.  Developers don't need to
roll their own, potentially non-interoperable message-passing schemes.
The named \%arguments are supplied and are available to each handler
in a standard way, which is described later in the MAGICAL LEXICAL
TOUR.

Second, POE::Stage provides request-scoped closures via $req_foo,
$rsp_foo, and expose().  Stages use these mechanisms to save and
access data in specific request and response contexts, eliminating the
need to do it explicitly.

Third, response destinations are tied to the requests themselves.  In
the above example, responses of type "response_x" will be handled by
"handler_x".  The logic flow of a complex program is more readily
apparent.  It gets better, too.  See HANDLER NAMING CONVENTIONS.

The mechanisms of message passing and context management become
implicit, allowing them to be extended transparently.  This will be
extended across processes, hopefully with few or no seams.

POE::Stage includes object-oriented classes for low-level event
watchers.  They simplify and standardize POE::Kernel's interface, and
they allow watchers to be extended cleanly through normal OO
techniques.  The lifespan of each resource is tightly coupled to the
lifespan of each object, so ownership and relevance are clearly
indicated.

POE::Stage standardizes shutdown semantics for requests and stages.
Requests are canceled by destroying their objects, and stages are shut
down the same way.

POE::Stage simplifies the cleanup of complex, multi-stage activity.
Resources for a particular request should be stored within its
closure.  Canceling the request triggers destruction of that closure
and its contents, which in turn triggers the destruction of the
resources allocated to that request.  These resources include stages
and requests created during the lifetime of the request.  They too are
canceled and freedm

=head1 MAGICAL LEXICAL TOUR

POE::Stage uses lexical aliasing to expose state data to message
handlers, which are specified by either the :Handler method attribute
or the use of an on_ prefix in the method's name.

Lexical variable prefixes indicate the data's origin.  For example,
$arg_name is the "name" argument included with a message:

	my $request = POE::Request->new(
		method => "something",
		args => { name => "ralph" },
		...,
	);

	sub something :Handler {
		my $arg_name;  # already contains "ralph"
	}

The full list of prefixes and data sources:

=head2 The "arg_" lexical prefix, e.g., $arg_foo

Argument (parameter) "xyz".  If an "args" parameter is passed to a
POE::Request constructor, its value must be a reference to a hash.
Usually it's an anonymous hashref.  Anyway, the hash's members are
named arguments to the message handler.  See above for an example.

=head2 The "req_" lexical prefix, e.g., $req_foo

An incoming request may trigger more than one handler, especially if a
POE::Stage object calls itself, or sends sub-requests to a helper
stage.  The "req_" lexical prefix refers to data members within the
current request's scope.  Their values will magically reflect the
proper request scope, regardless what that is.

TODO - Example.

=head2 The "self_" lexical prefix, e.g., $self_foo

The "self" scope refers to the currently active POE::Stage object.
Data may be stored there, in which case it's available from any and
all requests handled by that object.  This scope is useful for
"singleton" or static data that must be shared between or persistent
between all requests.

TODO - Example

=head2 The "rsp_" lexical prefix, e.g., $rsp_foo

The "rsp" scope refers to data stored in a sub-request's scope, but
from the response handler's point of view.  That is, when persisting
data between a request to a substage and its response, one should
store the data in the substage's request, then retrieve it later from
the corresponding "rsp" variable.

TODO - Example.

=head2 The $self, $req, and $rsp lexicals

Certain variables are standard:  $self refers to the current object;
it need not be initialized from @_.  $req refers to the higher-level
request we're currently handling.  When handling responses from
substages, $rsp refers to those responses.

All three variables are intended as invocatnts for method calls.
Other prefixes exist to access data members within each object's
scope.

TODO - Example.

The techniques used here have been abstracted and released as
Lexical::Persistence.

=head1 HANDLER NAMING CONVENTIONS

Message handlers are defined in one of two ways.  They may be named
anything as long as they have a :Handler attribute, or they may be
prefixed with "on_".  In both cases, they gain lexical persistence
magic, as discussed previously.

	# Handle the "foo" message.
	sub foo :Handler { ... }

	# Handle the "on_foo" and "foo" messages.
	sub on_foo { ... }

The on_foo() method above handles both "on_foo" and "foo" messages.
Given both a foo() and an on_foo(), however, on_foo() will take
precedence.

Requests include on_* parameters that map response types to response
handlers.  For example, this request expects two return types,
"success" and "failure".  On success, the handle_success() method is
called.  On failure, handle_failure() is called.

	my $req_subrequest = POE::Request->new(
		...,
		on_success => "handle_success",
		on_failure => "handle_failure",
	);

Response types are specified by the "type" parameter to $req->emit()
and $req->return().  "emit" and "return" are the default types for
emit() and return(), respectively.

Requests can also have roles, which are usually descriptive of the
transaction.  For example, consider a DNS request for a web client
component:

	my $req_resolve = POE::Request->new(
		...,
		role => "resolver",
	);

This is the role of the request, not of the stage that will handle it.
In this case, there are no on_* parameters.  Success and failure come
back to methods named "on_" . $request_role . "_" . $response_type.
In the previous example, they are:

	sub on_resolver_success { ... }
	sub on_resolver_failure { ... }

When subclassing a POE::Stage class, it's sometimes useful to
intercept emit() and return() messages.  The subclass may implement
handlers directly, or it may override or extend the response.  This is
done by defining "on_my_" . $response_type methdos in the subclass.
For example, a TCP connection stage might emit an "input" event, like
so:

	sub on_socket_readable {
		...;
		$req->emit( type => "input", input => $data );
	}

A subclass might implement the code to handle the input.  It can do so
by defining on_my_input():

	sub on_my_input {
		# send a response here
	}

Messages intercepted like this will not be rethrown automatically to
the caller.  If that's desired, on_my_input() will need to emit() or

TODO - Make a better example.  Something that can tie all these things
together conceptually.

=head1 BUGS

POE::Stage is not ready for production.  Check back here early and
often to find out when it will be.  Please contact the author if you
would like to see POE::Stage production-ready sooner.

=head1 BUG TRACKER

https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=POE-Stage

=head1 REPOSITORY

http://thirdlobe.com/svn/poe-stage/

=head1 OTHER RESOURCES

http://search.cpan.org/dist/POE-Stage/

=head1 SEE ALSO

POE::Stage is the base class for message-driven objects.
POE::Request is the base class for POE::Stage messages.
POE::Watcher is the base class for event watchers.

L<http://thirdlobe.com/projects/poe-stage/> - POE::Stage is hosted
here.

L<http://www.eecs.harvard.edu/~mdw/proj/seda/> - SEDA, the Staged
Event Driven Architecture.  It's Java, though.

=head1 AUTHORS

Rocco Caputo.

=head1 LICENSE

POE::Stage is Copyright 2005-2009 by Rocco Caputo.  All rights are
reserved.  You may use, modify, and/or distribute this module under
the same terms as Perl itself.

=cut
