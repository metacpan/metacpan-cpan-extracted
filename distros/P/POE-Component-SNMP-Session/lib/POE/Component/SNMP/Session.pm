package POE::Component::SNMP::Session;

use Carp;
use POE;
use POE::Session;

use POE::Component::SNMP::Session::Dispatcher;

use base 'SNMP';
# use Smart::Comments;

use warnings;
use strict;

# {{{ pod intro

=head1 NAME

POE::Component::SNMP::Session - Wrap Net-SNMP's SNMP::Session in POE

=head1 VERSION

Version 0.1202

=cut

our $VERSION = '0.1202';

=head1 SYNOPSIS

This module wraps the SNMP module from the net-snmp project within
POE's non-blocking event loop, to perform asynchronous SNMP requests.

    use POE qw/Component::SNMP::Session/;

    POE::Component::SNMP::Session->create();
    ...


NOTE: the Perl support for net-snmp is NOT installable via CPAN.  On
most linux distros, it is usually available as a companion package to
net-snmp.  The Windows port comes with an PPD package for ActiveState
Perl that must be installed manually.  

NOTE: this module is NOT based on the (mostly) pure-perl L<Net::SNMP>
module by David M. Town.  See L<POE::Component::SNMP> for an async
interface to L<Net::SNMP>.

=head1 CREATING SNMP COMPONENTS

=cut

# }}} pod intro

our $DEBUG = 0;

our $DISPATCHER;

use constant VERBOSE => 1;
*DEBUG_INFO = \*POE::Component::SNMP::Session::Dispatcher::DEBUG_INFO;

# {{{ BEGIN

BEGIN
{
    # Validate the creation of the Dispatcher object.

    if (!defined($DISPATCHER = POE::Component::SNMP::Session::Dispatcher->instance)) {
        die('FATAL: Failed to create Dispatcher instance');
    }
}

# }}} BEGIN

# {{{ create

=over 4

=item B<create> - create an SNMP session

The constructor takes the same arguments as the L<SNMP/SNMP::Session>
module, with one addition.

=over 4

=item Alias

the Alias parameter specifies the POE session alias the component will
receive.  If this parameter is not supplied, the default value is
'snmp'.  Be careful of creating duplicate sessions!  Depending on your
environment, POE might throw an error, or it might not.  So don't do
that.

=back

The C<DestHost> parameter is technically optional, and defaults to
'localhost', but you I<really> should set it.  Also, this parameter
name is Case Sensitive, so it must be supplied in mixed case as shown
here.

All other parameters are passed through to C<SNMP::Session> untouched.

NOTE: SNMPv3 session creation blocks until authorization completes.
This means that if your C<DestHost> doesn't respond, your program will
block for C<Timeout> microseconds (default 1s).  Also, if
authentication fails, the constructor will fail, so it is important to
check the return value of C<create()> in this case.

NOTE: C<Timeout> values are in I<microseconds>, not seconds.  Setting
a value like 60 and thinking it's seconds will cause your requests to
timeout before they've finished transmitting, and confusion will
ensue.

=back

=cut

sub create {
    my $class = shift;
    my @arg = @_;
    my %arg; # = @_;

    my ($alias, $hostname);

    ($alias, @arg) = _arg_scan(alias => @arg);
    $alias ||= 'snmp';
    push @arg, Alias => $alias;

    # make sure we aren't duplicating component aliases!
    if ( ! ($POE::VERSION <= 0.95 and POE::Kernel::ASSERT_DATA) and
         defined POE::Kernel->alias_resolve($alias)
       ) {
        local $Carp::CarpLevel = 4; # munge up to the right level of code
        print "-" x 40, "\n";

        croak "A ", __PACKAGE__, " instance called '$alias' already exists!";

        print "-" x 40, "\n";
    }


    # allow -hostname for compatibility, and put it in the Desthost slot automatically
    ($hostname, @arg) = _arg_scan( desthost => @arg);
    ($hostname, @arg) = _arg_scan( hostname => @arg)
      unless $hostname;

    push @arg, DestHost => $hostname if $hostname;

    # catch version
    my $version;
    ($version, @arg) = _arg_scan( version => @arg);
    $version = 2 if $version && $version eq 'snmpv2c';
    $version = 3 if $version && $version eq 'snmpv3';
    $version ||= 1;
    push @arg, Version => $version;

    %arg = @arg;

    # use YAML; warn Dump \%arg;

    # die unless we get a hostname
    unless ( (_arg_scan(desthost => %arg))[0] ) {
        croak "desthost parameter required";
    }

        # make sure we have a dispatcher!
    if (!defined($DISPATCHER = POE::Component::SNMP::Session::Dispatcher->instance)) {
            die('FATAL: Failed to create Dispatcher instance');
    }

    my (undef, @fd) = SNMP::select_info();
    @fd = () unless defined $fd[0];
    #### @fd

    my ($session, $error);
    {
        # local $SNMP::debugging = 3;
        ($session, $error) =
          SNMP::Session->new(%arg);
    }

    warn $error unless $session;
    warn $!  unless $session;
    warn $@  unless $session;
    return unless $session;

    my (undef, @new_fd) = SNMP::select_info();
    #### @new_fd

    # grab the one from @new_fd that is NOT in @fd
    my %h; @h{@new_fd} = (); delete @h{@fd}; my ($fd) = keys %h;
    DEBUG_INFO("chose fd $fd");

    POE::Session->create( inline_states => { _start        => \&_start_snmp_session,
                                             _stop         => \&_end_snmp_session,
                                             finish        => \&_close_snmp_session,

                                             get           => \&_snmp_get,
                                             getnext       => \&_snmp_getnext,
                                             bulkwalk      => \&_snmp_bulkwalk,
                                             getbulk       => \&_snmp_getbulk,

                                             # getentries    => \&_snmp_getentries,

                                             # trap          => \&_snmp_trap,
                                             # trap2c        => \&_snmp_trap2c,
                                             # inform        => \&_snmp_inform,

                                             set           => \&_snmp_set,

                                           },

                          args => [
                                   $session, $fd,
                                   $arg{desthost}
                                  ],
			);

    return $session;
}

# }}} create

# {{{ _start_snmp_session

sub _start_snmp_session {
    my ($kernel, $heap, $session, $fd, $hostname) = @_[KERNEL, HEAP, ARG0..$#_];

    my $alias = $session->{Alias};

    $kernel->alias_set($alias);

    $heap->{snmp_session}  = $session;  # SNMP::Session
    $heap->{postback_args} = [
                              $alias,
                              $hostname,
                              $session,
                             ];

    $DISPATCHER->_listen($session, $fd);

    return 1;
}

# }}} _start_snmp_session
# {{{ _close_snmp_session

sub _close_snmp_session {
    my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
    my $snmp_session = delete $heap->{snmp_session};

    return unless defined $snmp_session;

    if (0 and $snmp_session->debug & 0x08) {
        print "debug: [", __LINE__, "] ", __PACKAGE__, "::_close_snmp_session: calling __clear_pending\n";
    }

    # cancel all pending requests
    my $rv = $kernel->call($DISPATCHER->_alias => __clear_pending => $snmp_session);

    # undef $session;

    # remove our alias... since we have no more pending requests, we
    # will go away now.
    $kernel->alias_remove($_) for $kernel->alias_list( $session );

    # now the only thing keeping this session alive are any postback
    # references that have yet to be delivered.
}

# }}} _close_snmp_session
# {{{ _end_snmp_session

sub _end_snmp_session {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    # delete $heap->{snmp_session};
    my $session = delete $heap->{snmp_session};
    # WWW { sede => $session };
    # $DISPATCHER->_clear_session($session) if $session;
    # WWW $DISPATCHER;
    # $heap->{snmp_session}->close;
}

# }}} _end_snmp_session

# {{{ REQUESTS pod

=head1 REQUESTS

The requests accept a list of arguments which are passed directly to a
C<SNMP::Session> object.  See L<SNMP/SNMP::Session> for more
information on these arguments.

Requests take the form:

  $poe_kernel->post( $component_alias => $request =>
                     $callback_state => @snmp_args );


The arguments are the component alias, the request type, a callback
state in the requesting session, and then any arguments you would pass
to the SNMP::Session method of the same name.

=over 4

=item get

  $poe_kernel->post( snmp => get => $state =>
                     [ '.1.3.6.1.2.1.1.3.0' ],
                     # or
                     [ 'sysUptime.0' ],
                     # or
                     [ sysUptime => 0 ],
                     # or
                     [ 'sysUptime' ],
                   );


=item getnext

  $poe_kernel->post( snmp => getnext => $state => ['sysUpTime'] );

=item getbulk

  $poe_kernel->post( snmp => getbulk => $state =>
                     # nonrepeaters
                     1,
                     # maxrepetitions
                     8,
                     # vars
                     new SNMP::VarList (['ifNumber'], ['ifSpeed'], ['ifDescr'])
                   );


=item bulkwalk

  $poe_kernel->post( snmp => bulkwalk => $state =>
                     1, 8,
                     new SNMP::VarList (['ifNumber'], ['ifSpeed'], ['ifDescr'])
                   );

=item set

	    $poe_kernel->post( snmp => set => $state =>
                               [ 'sysContact' ] => 'sample@test.com',
	                     );


These are the request types the component knows about.  Details on the
correct parameters for each request type are available at
L<SNMP/SNMP::Session>.

There are several valid ways to specify query parameters, listed at
L<SNMP/Acceptable variable formats:>.

For sending traps, you should instantiate an SNMP::TrapSession object
directly.

=item finish

Shuts down the component instance (other SNMP sessions are
unaffected).  Any requests that are still pending will have their
respective responses/timeouts delivered, but new requests will be
discarded.

=back

=cut

# }}} REQUESTS pod

sub _snmp_get        { _snmp_request( get      => @_ ) }
sub _snmp_getnext    { _snmp_request( getnext  => @_ ) }
sub _snmp_set        { _snmp_request( set      => @_ ) }
sub _snmp_getbulk    { _snmp_request( getbulk  => @_ ) }
sub _snmp_bulkwalk   { _snmp_request( bulkwalk => @_ ) }

# sub _snmp_getable    { _snmp_request( gettable => @_ ) }

# {{{ _snmp_request

sub _snmp_request {
    # first parameter is the Net::SNMP method to call
    my $method = shift;
    # then standard POE args
    my ($kernel, $heap, $sender, $target_state, @snmp_args) = @_[KERNEL, HEAP, SENDER, ARG0..$#_];
    my $session = $heap->{snmp_session};

    # extract the request method called, for diagnostics
    # 'POE::Component::SNMP::Session::_snmp_get' => 'get'
    my $action = (caller(1))[3]; $action =~ s/POE::Component::SNMP::Session::_snmp_//;

    my (@callback_args, $callback_args);
    ($callback_args, @snmp_args) = _arg_scan(callback_args => @snmp_args);

    my $ok = 1;
    # if $callback_args is defined, we got a callback_args in the request.
    if (defined $callback_args) {
        if (ref $callback_args eq 'ARRAY') {
            @callback_args = @$callback_args;
        } else {
            $ok = 0;
            $session->{ErrorStr} = "Argument to -callback_args must be an arrayref";
            @callback_args = ($callback_args); # stash the "bad" argument to return with the error
        }
    }

    # do this before the 'set' logic to return an original copy of
    # @snmp_args to the callback.
    my @postback_args = (@{$heap->{postback_args}}, $action, @snmp_args);

    # $ok = 1;
    if ($ok) {
        if ($method eq 'set_request') {
            # string => numeric constant processing
            @snmp_args = _dwim_set_request_args(@snmp_args);
        }

        # this $postback is a closure.  it goes away after firing.
        # my $postback = $sender->postback($target_state => @postback_args);
        my $postback = $sender->callback($target_state => @postback_args);

        $ok = $DISPATCHER->_send_pdu($session => $method => \@snmp_args, $postback, \@callback_args);

    } else {
        $kernel->post( $sender => $target_state => \@postback_args,
                       [ $session, $session->{ErrorStr}, @callback_args ]
                     );
    }

    return $ok;
}

# }}} _snmp_request

# {{{ _arg_scan

# scan an array for a key matching qw/ -key key Key KEY / and fetch
# the value. return the value and the remaining arg list minus the
# key/value pair.
sub _arg_scan {
    my ($key, @arg) = @_;

    my $value;
    # scan the @arg for any keys that are callback args.
    for (0..$#arg) {
        # this pattern match likes to complain
        no warnings;
        if ($arg[$_] =~ /^-?$key$/i) {
            $value = $arg[$_ + 1];

            # splice out the key and value from @arg:
            splice @arg, $_, 2;
        }
    }

    ($value, @arg);
}

# }}} _arg_scan

# {{{ get

# =item get

# this is a subclassed get().  Automatically sends requests to POE but needs a state name as the first parameter.

# =cut


# sub get {
#     my ($session) = @_;
#     return $session->SUPER() unless defined $session->{_poe_destination};

# # sub yield {
#     # my $self = shift;
#     # $poe_kernel->post( $self->session => @_ );
# # }

#     return POE::Kernel->call($session->{Alias} => get => @_);
# }

# }}} get


# {{{ pod finish

=head1 CALLBACK STATES

 sub snmp_response {
     my($kernel, $heap, $request, $response) = @_[KERNEL, HEAP, ARG0, ARG1];

     my ($alias,   $host, $session, $cmd, @args)  = @$request;
     my ($results) = @$response;

     my $value = $results->[0][2];

     # ... stuff ...
 }



A callback state (a POE event) is invoked when the component either
receives a response or timeout.  The event receives data in its
C<$_[ARG0]> and C<$_[ARG1]> parameters.

C<$_[ARG0]> is an array reference containing: the C<SNMP::Session> object
that the component is using, the alias of the component, and the
hostname (C<DestHost>) the component is communicating with.

C<$_[ARG1]> is an array reference containing: the response value.

If the response value is defined, it will be a C<SNMP::VarList> object
containing the SNMP results.  The C<SNMP::VarList> object is a blessed
reference to an array of C<SNMP::Varbind> objects.  See
L<SNMP/Acceptable variable formats:> for more details.

If the response value is C<undef>, then any error message can be
accessed via the C<SNMP::Session> object as C<< $session->{ErrorStr}
>>.

See L<SNMP/SNMP::Session> for details.

=head1 AUTHOR

Rob Bloodgood, C<< <rdb at cpan.org> >>

=head1 CAVEATS

SNMPv3 connections automatically send a synchronous (blocking) request
to establish authorization (technically, it probes for the engineID).
If the request times out (for example if the agent is not responding),
the entire program will block for C<Timeout> microseconds.  YMMV, but
for unreliable or slow connections, you may want to try a smaller
timeout value, so you receive a failure more quickly.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-snmp-session-poe at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-SNMP-Session>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::SNMP::Session

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-SNMP-Session>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-SNMP-Session>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-SNMP-Session>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-SNMP-Session>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Rob Bloodgood, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# }}}

1; # End of POE::Component::SNMP::Session

# vi:foldmethod=marker:
