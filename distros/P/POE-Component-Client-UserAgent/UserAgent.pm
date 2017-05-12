package POE::Component::Client::UserAgent;
use strict;
use POE;
use LWP::Parallel;

@POE::Component::Client::UserAgent::ISA = 'LWP::Parallel::UserAgent';
$POE::Component::Client::UserAgent::VERSION = '0.08';

my $debuglevel = 0;

sub new
{
	my $class = @_ ? shift : 'POE::Component::Client::UserAgent';
	$class -> spawn (@_);
}

sub spawn
{
	my $class = @_ ? shift : 'POE::Component::Client::UserAgent';
	$class = ref $class || $class;
	my $object = $class -> SUPER::new;
	bless $object, $class;
	$object -> nonblock (0);
	my $argref = @_ & 1 ? pop @_ : { };
	my %args = (@_, %$argref);
	$args{alias} ||= 'useragent';
	LWP::Debug::trace ("Alias=$args{alias}\n\t$object");
	POE::Session -> create (
		object_states => [
			$object => {
				_start => '_pococ_ua_start',
				_stop => '_pococ_ua_stop',
				sigint => '_pococ_ua_sig_int',
				write => '_pococ_ua_write',
				read => '_pococ_ua_read',
				error => '_pococ_ua_error',
				timeout => '_pococ_ua_timeout',
				request => '_pococ_ua_request',
				shutdown => '_pococ_ua_shutdown'
			}
		],
		args => \%args
	);
	my $entry = LWP::Parallel::UserAgent::Entry -> new;
	$$entry{_permitted}{$_} = undef for qw(postback alarm_id alarm_time);
	return $object;
}

sub _pococ_ua_start
{
	my ($object, $kernel, $heap, $args) = @_[OBJECT, KERNEL, HEAP, ARG0];
	my $alias = $$args{alias};
	LWP::Debug::trace ("Alias=$alias\n\t$object\n\t$kernel");
	warn "Session '$alias' started\n" if $debuglevel >= 3;
	$kernel -> alias_set ($alias);
	$$heap{alias} = $alias;
	$object -> $_ ($$args{$_}) for grep exists ($$args{$_}),
		qw(agent from timeout redirect duplicates in_order remember_failures
		env_proxy proxy cookie_jar parse_head max_size max_hosts max_req delay);
	$kernel->sig(INT => 'sigint');
	$kernel->sig(BREAK => 'sigint');
}

sub _pococ_ua_stop
{
	my ($object, $heap) = @_[OBJECT, HEAP];
	LWP::Debug::trace ("Alias=$$heap{alias}\n\t$object");
	warn "Session '$$heap{alias}' stopped\n" if $debuglevel >= 3;
}

sub DESTROY
{
	my ($object) = @_;
	LWP::Debug::trace ("$object");
	warn "$object destroyed\n" if $debuglevel >= 3;
}

sub _pococ_ua_sig_int
{
	my ($object, $signal) = @_[OBJECT, ARG0];
	LWP::Debug::trace ("Signal=$signal\n\t$object");
	warn "Signal '$signal' arrived\n" if $debuglevel >= 3;
	$object -> _pococ_ua_cleanup();
	return 0;
}

sub _pococ_ua_shutdown
{
	my ($object, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
	LWP::Debug::trace ("Alias=$$heap{alias}\n\t$object\n\t$kernel");
	warn "Removing '$$heap{alias}' alias\n" if $debuglevel >= 3;
	$kernel -> alias_remove ($$heap{alias});
}

sub _pococ_ua_cleanup
{
	my ($object) = @_;
	LWP::Debug::trace ("$object");
	warn "Cleaning up\n" if $debuglevel >= 3;
	$object -> _remove_all_sockets;
	$poe_kernel -> alarm ('timeout');
}

sub _pococ_ua_request
{
	my ($object, @args) = @_[OBJECT, ARG0 .. $#_];
	my $argref = @args & 1 ? pop @args : { };
	my %args = (@args, %$argref);
	my ($request, $filename, $callback, $chunksize, $redirect) =
		@args{qw(request filename callback chunksize redirect)};
	LWP::Debug::trace ("$object\n\t$request");
	warn 'Request for ' . $request -> url -> as_string . "\n" if $debuglevel >= 3;
	my $register = $object -> register ($request,
		$filename || $callback, $chunksize, $redirect);
	$$object{entries_by_requests}{$request} -> postback ($args{response});
	$object -> _make_connections;
}

sub _pococ_ua_set_timeout
{
	my ($object, $entry) = @_;
	my $timeout = $object -> timeout;
	return unless defined $timeout;
	my $alarm_id = $poe_kernel -> delay_set (timeout => $timeout, $entry);
	LWP::Debug::trace ("$object\n\t$entry\n\tTimeout: $timeout\n\tAlarm ID: "
		. (defined $alarm_id ? $alarm_id : '[undef]'));
	$entry -> alarm_id ($alarm_id);
	$entry -> alarm_time (defined $alarm_id ? time() + $timeout : undef);
}

sub _pococ_ua_adjust_timeout
{
	my ($object, $entry) = @_;
	$object -> _pococ_ua_remove_timeout ($entry);
	$object -> _pococ_ua_set_timeout ($entry);
}

# alarm_adjust causes problems in POE 0.1402
#sub _pococ_ua_adjust_timeout
#{
#	my ($object, $entry) = @_;
#	my $timeout = $object -> timeout;
#	return unless defined $timeout;
#	my $alarm_id = $entry -> alarm_id;
#	return unless defined $alarm_id;	# Couldn't set alarm? Should never happen.
#	my $previous_alarm_time = $entry -> alarm_time;
#	my $new_alarm_time = time() + $timeout;
#	return if $new_alarm_time == $previous_alarm_time;
#	LWP::Debug::trace ("$object\n\t$entry\n\tTimeout: $timeout\n"
#		. "\tAlarm ID: $alarm_id\n\tPrevious Alarm Time: $previous_alarm_time\n"
#		. "\tNew Alarm Time: $new_alarm_time");
#	$poe_kernel -> alarm_adjust ($alarm_id, $new_alarm_time - $previous_alarm_time);
#	$entry -> alarm_id ($alarm_id);
#	$entry -> alarm_time ($new_alarm_time);
#}

sub _pococ_ua_remove_timeout
{
	my ($object, $entry) = @_;
	my $alarm_id = $entry -> alarm_id;
	return unless defined $alarm_id;
	LWP::Debug::trace ("$object\n\t$entry\n\tAlarm ID: $alarm_id");
	$poe_kernel -> alarm_remove ($alarm_id);
	$entry -> alarm_id (undef);
	$entry -> alarm_time (undef);
}

sub _connect
{
	my ($object, $entry) = @_;
	LWP::Debug::trace ("$object\n\t$entry\n\t" . $entry -> request -> url);
	warn 'Connecting ' . $entry -> request -> url -> as_string . "\n"
		if $debuglevel >= 3;
	my $result = $object -> SUPER::_connect ($entry);
	return $result if defined $result;
	$object -> _pococ_ua_set_timeout ($entry);
	return undef;
}

sub _add_out_socket
{
	my ($object, $socket) = @_;
	LWP::Debug::trace ("$object\n\t$socket");
	$poe_kernel -> select_write ($socket => 'write');
	$poe_kernel -> select_expedite ($socket => 'error')
		unless -f $socket;
}

sub _add_in_socket
{
	my ($object, $socket) = @_;
	LWP::Debug::trace ("$object\n\t$socket");
	$poe_kernel -> select_read ($socket => 'read');
	$poe_kernel -> select_expedite ($socket => 'error')
		unless -f $socket;
}

sub _remove_out_socket
{
	my ($object, $socket) = @_;
	LWP::Debug::trace ("$object\n\t$socket");
	$poe_kernel -> select_write ($socket);
	$poe_kernel -> select_expedite ($socket)
		unless -f $socket;
}

sub _remove_in_socket
{
	my ($object, $socket) = @_;
	LWP::Debug::trace ("$object\n\t$socket");
	$poe_kernel -> select_read ($socket);
	$poe_kernel -> select_expedite ($socket)
		unless -f $socket;
}

sub _remove_all_sockets
{
	my ($object) = @_;
	LWP::Debug::trace ("$object");
	my ($socket, $entry);
	$object -> _remove_entry_sockets ($entry)
		while ($socket, $entry) = each %{$$object{entries_by_sockets}};
	$object -> initialize;
}

sub _remove_entry_sockets
{
	my ($object, $entry) = @_;
	LWP::Debug::trace ("$object\n\t$entry");
	my $socket = $entry -> cmd_socket;
	if ( defined $socket )
	{
		$object -> _remove_out_socket ($socket);
		$entry -> cmd_socket (undef);
	}
	$socket = $entry -> listen_socket;
	if ( defined $socket )
	{
		$object -> _remove_in_socket ($socket);
		$entry -> listen_socket (undef);
	}
}

sub _pococ_ua_write
{
	my ($object, $socket) = @_[OBJECT, ARG0];
	my $entry = $$object{entries_by_sockets}{$socket};
	LWP::Debug::trace ("$object\n\t$socket\n\t$entry\n\t"
		. $entry -> request -> url);
	warn 'Writing ' . $entry -> request -> url -> as_string . "\n"
		if $debuglevel >= 3;
	$object -> _pococ_ua_adjust_timeout ($entry);
	$object -> _perform_write ($socket);
}

sub _pococ_ua_read
{
	my ($object, $socket) = @_[OBJECT, ARG0];
	my $entry = $$object{entries_by_sockets}{$socket};
	LWP::Debug::trace ("$object\n\t$socket\n\t$entry\n\t"
		. $entry -> request -> url);
	warn 'Reading ' . $entry -> request -> url -> as_string . "\n"
		if $debuglevel >= 3;
	$object -> _pococ_ua_adjust_timeout ($entry);
	$object -> _perform_read ($socket);
}

sub _pococ_ua_error
{
	my ($object, $kernel, $socket) = @_[OBJECT, KERNEL, ARG0];
	my $entry = $$object{entries_by_sockets}{$socket};
	my $request = $entry -> request;
	LWP::Debug::trace ("$object\n\t$kernel\n\t$socket\n\t$entry\n\t$request\n\t"
		. $request -> url);
	warn 'Error on ' . $request -> url -> as_string . "\n"
		if $debuglevel >= 3;
	my $response = HTTP::Response -> new (&HTTP::Status::RC_INTERNAL_SERVER_ERROR,
		'Connection was reset');
	$response -> request ($request);
	$entry -> response ($response);
	$object -> on_failure ($request, $response, $entry);
	LWP::Debug::trace ('Error while processing request ' . $request -> url);
	$object -> _remove_entry_sockets ($entry);
	$object -> _remove_current_connection ($entry);
}

sub _pococ_ua_timeout
{
	my ($object, $kernel, $entry) = @_[OBJECT, KERNEL, ARG0];
	$entry -> alarm_id (undef);
	$entry -> alarm_time (undef);
	my $request = $entry -> request;
	LWP::Debug::trace ("$object\n\t$kernel\n\t$entry\n\t$request\n\t"
		. $request -> url);
	warn 'Timeout on ' . $request -> url -> as_string . "\n"
		if $debuglevel >= 3;
	my $response = HTTP::Response -> new (&HTTP::Status::RC_REQUEST_TIMEOUT,
		'Request timeout (I/O inactivity)');
	$response -> request ($request);
	$entry -> response ($response);
	$object -> on_failure ($request, $response, $entry);
	LWP::Debug::trace ('Request timeout ' . $request -> url -> as_string);
	$object -> _remove_entry_sockets ($entry);
	$object -> _remove_current_connection ($entry);
}

sub _pococ_ua_postback
{
	my ($object, $request, $response, $entry) = @_;
	$object -> _pococ_ua_remove_timeout ($entry);
	$entry -> postback -> ($request, $response, $entry);
	if ( $entry -> redirect_ok )
	{
		# We need to skip cleanup if the response is a redirect.
		# See LWP::Parallel::UserAgent::handle_response for details.
		my $code = $response -> code;
		if ( $code == HTTP::Status::RC_MOVED_PERMANENTLY
				or $code == HTTP::Status::RC_MOVED_TEMPORARILY
				or $code == HTTP::Status::RC_FOUND
				or $code == HTTP::Status::RC_SEE_OTHER
				or $code == HTTP::Status::RC_TEMPORARY_REDIRECT
		) {
			$code = $response -> header ('Client-Warning');
			return unless defined ($code) and $code eq 'Redirect loop detected';
		}
	}
	$object -> discard_entry ($entry);
	# if the entry doesn't get discarded for whatever reason, the postback
	# may create a circular reference, depending on what the user passed
	# to Session::postback(), so we'd better break it here.
	$entry -> postback (undef);
}

sub on_return
{
	my ($object, $request, $response, $entry) = @_;
	LWP::Debug::trace ("$object\n\t$request\n\t$response\n\t$entry\n\t" .
		join "\n\t", $request -> url -> as_string,
		$response -> code, $response -> message);
	warn 'Response returned ' . $request -> url -> as_string . "\n"
		if $debuglevel >= 3;
	$object -> _pococ_ua_postback ($request, $response, $entry);
	return 0;
}

sub on_failure
{
	my ($object, $request, $response, $entry) = @_;
	LWP::Debug::trace ("$object\n\t$request\n\t$response\n\t$entry\n\t" .
		join "\n\t", $request -> url -> as_string,
		$response -> code, $response -> message);
	warn 'Request failed ' . $request -> url -> as_string . "\n"
		if $debuglevel >= 3;
	$object -> _pococ_ua_postback ($request, $response, $entry);
	return 0;
}

sub debug
{
	my $level = shift;
	$level = shift if ref $level;
	return unless defined $level;
	$debuglevel = $level;
	LWP::Debug::level '+debug' if $debuglevel >= 5;
	LWP::Debug::level '+trace' if $debuglevel >= 7;
	LWP::Debug::level '+conns' if $debuglevel >= 9;
	my $filename = shift;
	return unless $debuglevel > 0 and defined $filename;
	close STDERR;
	open STDERR, ">$filename";
}

no warnings 'redefine';

sub LWP::Debug::_log
{
	my $msg = shift;
	$msg .= "\n" unless $msg =~ /\n$/;
	my $sub = (caller (2)) [3];
	warn "$sub\n\t$msg";
}

1;

__END__

=head1 NAME

C<POE::Component::Client::UserAgent> - C<LWP> and C<LWP::Parallel> based
user agent

=head1 SYNOPSIS

    use POE;
    use POE::Component::Client::UserAgent;

    POE::Component::Client::UserAgent -> new;

    $postback = $session -> postback ('response');

    $request = HTTP::Request -> new (GET => $url);

    $poe_kernel -> post (useragent => request =>
        request => $request, response => $postback);

    sub response
    {
        my ($request, $response, $entry) = @{$_[ARG1]};
        print $response -> status_line;
        $_[KERNEL] -> post (useragent => 'shutdown');
    }

=head1 DESCRIPTION

B<Note:> C<POE::Component::Client::UserAgent> dependencies frequently
have problems installing.  This module is difficult to maintain when
the latest dependencies don't work.  As a result, we prefer to
maintain and recommend L<POE::Component::Client::HTTP>.  That client
has fewer, more actively maintained dependencies, and it tends to work
better.

C<POE::Component::Client::UserAgent> is based on C<LWP> and C<LWP::Parallel>.
It lets other tasks run while making a request to an Internet server
and waiting for response, and it lets several requests run in parallel.

C<PoCoCl::UserAgent> session is created using C<spawn> or C<new> method.
The two methods are equivalent. They take a few named parameters:

=over 2

=item C<alias>

C<alias> sets the name by which the session will be known.  If no
alias is given, it defaults to C<useragent>. The alias lets several
client sessions interact with the UserAgent component without keeping
(or even knowing) hard references to them. It is possible to create
several UserAgent components with different names.

=item C<timeout>

The component will return an error response if a connection is inactive
for C<timeout> seconds. The default value is 180 seconds or 3 minutes.

=back

The rest of the parameters correspond to various properties of
C<LWP::UserAgent> and C<LWP::Parallel::UserAgent>. For details please
refer to those modules' documentation.

=over 2

=item C<agent>

=item C<from>

=item C<redirect>

=item C<duplicates>

=item C<in_order>

=item C<remember_failures>

=item C<proxy>

=item C<cookie_jar>

=item C<parse_head>

=item C<max_size>

=item C<max_hosts>

=item C<max_req>

=item C<delay>

The C<delay> parameter is currently not used.

=back

Client sessions communicate asynchronously with C<PoCoCl::UserAgent>
by using an alias and posting events to the component. When a
request is complete, the component posts back a response event
using a postback the client provided when it made the request.

Requests are posted via the component's C<request> event. The event
takes a few named parameters:

=over 2

=item C<request>

C<request> is a reference to an C<HTTP::Request> object that the
client sets up with all the information needed to initiate the
request.

=item C<response>

C<response> is the postback the component will use to post back
a response event. The postback is created by the client using
C<POE::Session>'s C<postback()> method.

=item C<filename>

C<filename> is an optional file name. If it is specified, the
response will be stored in the file with that name.

=item C<callback>

C<callback> is an optional subroutine reference. If it is
specified, the subroutine will be called as chunks of the
response are received.

=item C<chunksize>

C<chunksize> is an optional number giving a hint for the
appropriate chunk size to be passed to the callback subroutine.
It should not be specified unless C<callback> is also specified.

=item C<redirect>

C<redirect> is an optional value specifying the redirection
behavior for this particular request. A true value will make
the UserAgent follow redirects. A false value will instruct the
UserAgent to pass redirect responses back to the client session
just like any other responses. If C<redirect> value is not
specified then the default value passed to the C<UserAgent>'s
constructor will be used. That in turn defaults to following
redirects.

=back

When a request has completed, whether successfully or not, the
C<UserAgent> component calls the postback that was supplied along
with the request. Calling the postback results in posting an
event to the session it was created on, which normally is the
session that posted the request.

The postback event parameter with the index C<ARG0> is a reference
to an array containing any extra values passed to the C<postback()>
method when creating the postback. This allows the client
session to pass additional values to the response event for
each request.

The postback event parameter with the index C<ARG1> is a reference
to an array containing three object references that are passed
back by the C<UserAgent> session. These objects are:

=over 2

=item C<HTTP::Request>

This is the object that was passed to the C<request> event.

=item C<HTTP::Response>

This is an object containing the response to the request.

=item C<LWP::Parallel::UserAgent::Entry>

This is an object containing additional information about the
request processing. For details please see the
C<LWP::Parallel::UserAgent> module and its documentation.

=back

When the client is done posting request events to the component,
it should post a C<shutdown> event, indicating that the component
can release its alias. The component will continue to operate
until it returns all responses to any pending requests.

=head1 EXAMPLE

    #!/usr/bin/perl -w
    # should always use -w flag!

    # this is alpha software, it needs a lot of testing!
    sub POE::Kernel::ASSERT_DEFAULT() { 1 }
    sub POE::Kernel::TRACE_DEFAULT() { 1 }

    use strict;
    use POE;    # import lots of constants
    use POE::Component::Client::UserAgent;

    # more debugging stuff
    my $debuglevel = shift || 0;
    POE::Component::Client::UserAgent::debug $debuglevel => 'logname';

    # create client session
    POE::Session -> create (
        inline_states => {
            _start => \&_start,
            response => \&response
        },
    );

    # now run POE!
    $poe_kernel -> run;

    # this is the first event to arrive
    sub _start
    {
        # create the PoCoCl::UserAgent session
        POE::Component::Client::UserAgent -> new;
        # hand it our request
        $_[KERNEL] -> post (
            # default alias is 'useragent'
            useragent => 'request',
            {
                # request some worthless web page
                request => HTTP::Request -> new (GET => 'http://www.hotmail.com/'),
                # let UserAgent know where to deliver the response
                response => $_[SESSION] -> postback ('response')
            }
        );
        # Once we are done posting requests, we can post a shutdown event
        # to the PoCoCl::UserAgent session. Responses will still be returned.
        $_[KERNEL] -> post (useragent => 'shutdown');
    }

    # Here is where the response arrives. Actually in this example we
    # would get more than one response, as hotmail home page is a mere
    # redirect to some address at passport.com. The component processes
    # the redirect automatically by default.
    sub response
    {
        # @{$_[ARG0]} is the list we passed to postback()
        # after the event name, empty in this example
        # @{$_[ARG1]} is the list PoCoCl::UserAgent is passing back to us
        my ($request, $response, $entry) = @{$_[ARG1]};
        print "Successful response arrived!\n"
            if $response -> is_success;
        print "PoCoCl::UserAgent is automatically redirecting the request\n"
            if $response -> is_redirect;
        print "The request failed.\n"
            if $response -> is_error;
    }

=head1 DEBUGGING

C<PoCoCl::UserAgent> has a class method called C<debug>. It can also be
called as an object method, but the settings will affect all instances.

The method accepts two parameters.
The first parameter is the debug level, ranging from 0 for no debug
information to 9 for when you want to fill up your disk quota real quick.

Levels 3 and up enable C<PoCoCl::UserAgent>'s debugging output.
Levels 5 and up additionally enable C<LWP>'s C<+debug> debugging option.
Levels 7 and up additionally enable C<LWP>'s C<+trace> debugging option.
Levels 9 and up additionally enable C<LWP>'s C<+conns> debugging option.

The second parameter, if it is specified and the first parameter
is greater than 0, gives the name of the file where to dump the
debug output. Otherwise the output is sent to standard error.

Additionally you may want to enable POE's own debugging output, using
the constant sub declarations shown in the example above. So far I
couldn't figure out how to affect it using the debug level parameter.
The POE output will also go to the log file you specify.

=head1 SEE ALSO

=over 2

=item POE

L<POE> or http://poe.perl.org/

=item LWP

L<LWP> or http://www.linpro.no/lwp/

=item LWP::Parallel

L<LWP::Parallel> or http://www.inf.ethz.ch/~langhein/ParallelUA/

=back

Also see the test programs in the C<PoCoCl::UserAgent> distribution
for examples of its usage.

=head1 BUGS

All requests containing a host name block while resolving the host name.

FTP requests block for the entire duration of command connection setup,
file request and data connection establishment.

At most one request is sent and one response is received over each TCP
connection.

All of the above problems are unlikely to be solved within the current
LWP framework. The solution would be to rewrite LWP and make it POE
friendly.

The RobotUA variety of UserAgent is not yet implemented.

L<LWP::Parallel> often cannot install due to feature mismatches with
recent versions of LWP.  This interferes with our ability to maintain
and test this module.  Please see L<POE::Component::Client::HTTP>,
which does not rely on LWP::Parallel.

=head1 BUG TRACKER

https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=POE-Component-Client-UserAgent

=head1 REPOSITORY

http://github.com/rcaputo/poe-component-client-useragent
http://gitorious.org/poe-component-client-useragent

=head1 OTHER RESOURCES

http://search.cpan.org/dist/POE-Component-Client-UserAgent/

=head1 AUTHOR AND COPYRIGHT

Copyright 2001-2010 Rocco Caputo.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
