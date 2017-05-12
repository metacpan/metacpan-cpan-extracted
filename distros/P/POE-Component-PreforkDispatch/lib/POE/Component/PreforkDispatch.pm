package POE::Component::PreforkDispatch;

our $VERSION = 0.101;

=cut

=head1 NAME

POE::Component::PreforkDispatch - Preforking task dispatcher

=head1 DESCRIPTION

Applications that require lots of asynchronous tasks going at once may suffer a performance hit from repeating the fork/die process over and over again with each enqueued job.  Similar to how Apache forks, this dispatcher will maintain a pool of available forks and a queue of pending tasks.  Each task (request) will be handled in turn, and will return to the callback when done.

=head1 SYNOPSIS

    use POE qw(Component::PreforkDispatch);

    POE::Session->create(
        inline_states => {
            _start => \&start,
            do_slow_task => \&task,
            do_slow_task_cb => \&task_cb,
        },
    );

    $poe_kernel->run();

    sub start {
        POE::Component::PreforkDispatch->create(
            max_forks => 4,
            pre_fork  => 2,
        );
        foreach (1..5) {
            print "Enqueued request $_\n";
            $poe_kernel->post(PreforkDispatch => 'new_request', {
                method      => 'do_slow_task',
                upon_result => 'do_slow_task_cb',
                params      => [ 'a value', $_, ],
            });
        }
    }

    sub task {
        my ($kernel, $heap, $from, $param1, $param2) = @_[KERNEL, HEAP, ARG0 .. $#_];

        # ... do something slow
        print STDERR "Task running with '$param1', '$param2'\n";
        sleep 10;

        # Return hashref or arrayref
        return { success => 1 };
    }

    sub task_cb {
        my ($kernel, $heap, $request, $result) = @_[KERNEL, HEAP, ARG0, ARG1];

        print STDERR "Task with param ".$request->{params}[1]." returned "
            .($result->{success} ? 'successful' : 'failure')."\n";
    }

=cut

use strict;
use warnings;
use POE qw/Wheel::Run Filter::Reference/;
use IO::Capture::Stdout;
use Error qw(:try);
use Data::Dumper;
use Params::Validate;


### Class Methods ##

=cut

=head1 USAGE

=head2 Methods

=head3 Constructor

Call ->create() like with any other C<POE::Session>, passing a list of named parameters.

=over 4

=item * methods => \%methods

=item * classes => \@classes

=item * xmlrpc_server_parent => $session_name

Provide an optional means of finding a method to dispatch a request to.  If none are provided, the request itself needs to indicate it's method.

  methods => {
    'do_something' => \&do_something,
    'do_else'      => 'do_else_state',
  },

Methods will be searched for by name and will call either the state or the subroutine.  See below for how either is called.

  classes => [ 'My::Class' ],

Methods will be attempted in each namespace provided, and called as subroutines.

  xmlrpc_server_parent => 'XMLRPC_Session_Alias',

Requests will be wrapped in a pseudo-transaction capable of being passed onto a L<POE::Component::Server::XMLRPC> session for handling.

=item * upon_result => $subref || $state_name

If provided, used as a fallback result function to send completed requests to.

=item * max_forks => $num

Number of forks, max, to spawn off to handle requests.

=item * pre_fork => $num

How many forks to start out with.  The rest are spawned as needed, with a 2 sec delay between new forks.

=item * max_requests => $num

How many requests each fork can handle before being slayed and respawned (if necessary).

=item * verbose => $num (defaults 0)

=item * talkback => sub { }

The dispatcher logs certain events, and can be verbose about it.  The talkback function will be passed a single arg of a log line.  This defaults to printing to STDOUT.

=item * fork_name => $name

In process lists on a POSIX system, you can change the name of the forked children so you can at a glance know that they're dispatcher forks and not the parent process.  Will be renamed to "$name child".

=item * alias => $session_name

Provide a session name.  Defaults to 'PreforkDispatch'.

=back

=cut

sub create {
    my $class = shift;

    my %param = validate(@_, {
        methods => 0,
        classes => 0,
        xmlrpc_server_parent => 0,

        max_forks => 0,
        pre_fork  => 0,
        max_requests => 0,
        talkback  => { default => sub { print $_[0] . "\n" } },
        fork_name => 0,
        alias     => { default => 'PreforkDispatch' },
        upon_result => { default => 'dispatch_result' },
        verbose   => 0,
    });

    my $session = POE::Session->create(
        package_states => [
            $class => [
                qw/_start _stop init kill new_request return_result process_queue child_exited/,
                # Callbacks from forked wheels
                qw/fork_input fork_debug fork_closed fork_error/,
            ],
        ],
        heap => {
            %param,
            request_queue => [],
            # takes form: [
            # 	{	
            # 		method_name => '...',
            #		from => '...',
            #		params => [ { ... } | ..., ... ],
            #	},
            # ]

            forks => [],
            # takes form: [
            # 	{
            # 		id => $wheel_id,
            #		wheel => POE::Wheel::Run->new(),
            #		status => 'idle|waiting_response',
            #		active_request => { ... },
            #		started_request => time,
            #	},
            # ]
        },
    );
    return $session;
}

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    $kernel->alias_set( $heap->{alias} ? $heap->{alias} : 'RPCDispatch' );

    $heap->{talkback}("Started prefork dispatcher");

    # Register signal for rpc forks exiting
    $kernel->sig(CHLD => "child_exited");

    # Do preforking if requested
    my $prefork = $heap->{pre_fork};
    $prefork ||= 0;

    for (my $i = 1; $i <= $prefork; $i++) {
        my $fork = fork_new($heap);
        $heap->{talkback}("Pre spawning fork " . $fork->{id});
    }
}

sub _stop {
    my $kernel = $_[KERNEL];
    $kernel->alias_remove();
}

sub init {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
}

sub kill {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    foreach my $fork (@{ $heap->{forks} }) {
        $fork->{wheel}->kill(9);
    }
}

=cut

=head2 Session States

=head3 new_request (\%param)

The primary interface to enqueueing requests.  Takes the following arguments in a hashref.

  $poe_kernel->post( PreforkDispatch => 'new_request', {
    method_name => 'do_something',
    params => [ 'Computer 3' ],
  });

=over 4

=item * method_name

Provide a method name for searching for an appropriate method to dispatch to.  Most akin to XMLRPC's method_name.

=item * method => $subref || $session_state

Instead of using the method_name, you can provide the method session state or subref to use as a request handler.

=item * upon_result => $subref || $session_state

Instead of using the global upon_result, provide a per-request callback.

=item * params => $arrayref

An arrayref, this is where you put your payload of the request.

=item * from

An XMLRPC value, this is not used typically for a single-host application.

=back

=cut

sub new_request {
    my ($kernel, $heap, $session, $sender, $request) = @_[KERNEL, HEAP, SESSION, SENDER, ARG0];

    $request->{from}   ||= 'local';
    $request->{params} ||= [];
    $request->{method_name} ||= $request->{method} && ! ref($request->{method}) ? $request->{method} : 'anonymous method';

    # Record where it came from
    $request->{session} = $sender->ID;

    # Handle asynchronously
    if ($heap->{max_forks}) {
        # Enqueue the request and yield to fork queue checker
        push @{ $heap->{request_queue} }, $request;
        $kernel->yield('process_queue');

        return;
    }

    $heap->{talkback}("Handling request $$request{method_name} synchronously") if $heap->{verbose};
    $request->{result} = handle_request_wrapper($heap, $request);
    $kernel->call($session, 'return_result', $request);
}

=cut

=head2 Request to response

After a new_request() is issued, the dispatcher will process it in a FIFO queue, using forks if available, or handling it synchronously otherwise.  Handling a request is done by searching for a valid method, either picking the $request->{method}, or if not available, searching the dispatcher methods, classes and finally the xmlrpc_server_parent for something to handle $request->{method_name}.

If the method given is a subref, it will be passed ($from, @args).  If a POE session state name, the calling session will have this state posted to with the same args ($from, @args):

  my ($from, @args) = @_;

or

  my ($kernel, $heap, $from, @args) = @_[KERNEL, HEAP, ARG0 .. $#_];

Once the request is handled, successfully or not, a response is sent to either the request's 'upon_result', or the dispatchers.  If the method is a subref, it will be handed ($request, $response).  Similar for session state.  The request will be the same as passed, but with the additional key/value of 'elapsed' containing the seconds the request took to process.  The response will be the response value of the method that handled the request, or in the case of an error, a hashref with the key 'error'.

=head2 Special methods

There are some methods that are special and can be used to control child fork behavior

=over 4

=item * _precall

=item * _postcall

Not sure if these are useful, but will be called before and after the named method.  Can be used as universal constructor/destructors for method calls.  Passed the main method params.

=item * _fork_preinit

=item * _fork_postinit

Code to be called before and after actually forking (in the parent process).

=item * _fork_init

Not passed anything, this permits the fork to do something that's better done after forking (opening handles and such).

=back

=cut

sub return_result {
    my ($kernel, $heap, $request) = @_[KERNEL, HEAP, ARG0];

    my $result = delete $request->{result};

    if (! defined $result) {
        # The method was not found
        $result = { error => "Could not handle method '".$request->{method_name}."'; no means found" };
    }

    my $return_to = $request->{upon_result} || $heap->{upon_result};
    if (ref($return_to)) {
        $return_to->($request, $result);
    }
    else {
        $kernel->post(delete $request->{session}, $return_to, $request, $result);
    }
}

sub handle_request_wrapper {
    my ($heap, $request) = @_;

    my $result;
    try {
        $result = handle_request($heap, $request);
    }
    otherwise {
        my ($ex) = @_;
        $result = {
            error =>
                "Method '$$request{method_name}' threw exception: " .
                ( ref($ex) && $ex->can('stringify') ? $ex->stringify() : $ex )
        };
    };
    return $result;
}

sub handle_request {
    my ($heap, $request) = (shift, shift);

    my $method_name = $request->{method_name};
    my @args = ($request->{from}, @{ $request->{params} });

    call_method($heap, '_precall', \@args);
    my $result = call_method($heap, $method_name, \@args, $request);
    call_method($heap, '_postcall', \@args);

    return $result;
}

sub call_method {
    my ($heap, $method_name, $args, $request) = @_;

    # Find a method to handle this

    my $method = $heap->{methods} ? $heap->{methods}{$method_name} : undef;
    $method ||= $request->{method};

    if ($method) {
        if (ref($method)) {
            return $method->(@$args);
        }
        else {
            return $poe_kernel->call( $request->{session}, $method, @$args );
        }
    }
    elsif ($heap->{classes}) {
        foreach my $class (@{ $heap->{classes} }) {
            # TODO - see if class has function $method_name
        }
        return { error => "Class-based method calls not yet implemented" };
    }
    elsif ($heap->{xmlrpc_server_parent}) {
        my $from = shift @$args;
        my $transaction = POE::Component::PreforkDispatch::PseudoXMLRPCTransaction->new(@$args);
        $poe_kernel->call( $heap->{xmlrpc_server_parent}, $method_name, $transaction );
        return { error => "Couldn't call XMLRPC method $method_name on session ".$heap->{xmlrpc_server_parent} } if $!;
        return $transaction->result();
    }
    else {
        return { error => "Unknown XMLRPC method $method_name" };
    }
}


## RPC methods

sub process_queue {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    # Do nothing if queue is empty
    return if $#{ $heap->{request_queue} } < 0;

    # Find a fork to use

    # Check for available, not busy existing forks.
    # Choose the fork that's been waiting the longest
    my @avail_forks = 
        sort { $a->{finished_request} <=> $b->{finished_request} }
        grep { $_->{status} eq 'idle' }
        @{ $heap->{forks} };

    my $use_fork = $avail_forks[0] ? $avail_forks[0] : undef;

    # If no fork found, create a new one if possible.  Otherwise, wait.
    if (! $use_fork) {
        if (int @{ $heap->{forks} } == $heap->{max_forks}) {
            # Already forked the max number; have to wait for one to return
            $heap->{talkback}("All forks are busy; will wait to handle request after a fork returns") if $heap->{verbose};
            return;
        }

        # Don't forkbomb; delay before spawning another fork
        if ($heap->{last_fork_created} && time - $heap->{last_fork_created} < 5) {
            $heap->{talkback}("Delaying 2 sec on creating another fork") if $heap->{verbose};
            $kernel->delay('process_queue', 2);
            return;
        }
        $use_fork = fork_new($heap);
        $heap->{talkback}("Creating new fork " . $use_fork->{id});
        $heap->{last_fork_created} = time;
    }

    ## With a fork found, hand off the first request in queue to this fork

    my $request = shift @{ $heap->{request_queue} };

    $heap->{talkback}("Handling request " . $request->{method_name} . " with fork " . $use_fork->{id}) if $heap->{verbose};

    $use_fork->{active_request} = $request;
    $use_fork->{status} = 'waiting_response';
    $use_fork->{started_request} = time;

    $use_fork->{wheel}->put( $request );
}

sub fork_new {
    my ($heap) = @_;

    call_method($heap, '_fork_preinit');

    # Create a new fork
    my $wheel = POE::Wheel::Run->new(
        Program => sub { fork_main($heap) },
        StdinFilter => POE::Filter::Reference->new(),
        StdoutFilter => POE::Filter::Reference->new(),
        StdoutEvent => 'fork_input',
        StderrEvent => 'fork_debug',
        CloseEvent => 'fork_closed',
        ErrorEvent => 'fork_error',
    );
    my $fork = {
        status => 'idle',
        wheel => $wheel,
        id => $wheel->ID,

        active_request => undef,
        started_request => 0,
        finished_request => 0,
    };
    push @{ $heap->{forks} }, $fork;
    call_method($heap, '_fork_postinit', $fork);
    return $fork;
}

sub fork_main {
    my ($heap) = @_;
    my $raw;
    my $size   = 4096;
    my $filter = POE::Filter::Reference->new();
    my $request_counter = 0;
    my $request_max = $heap->{max_requests} || 0;

    # Set my `ps aux` name if desired
    $0 = "$$heap{fork_name} child" if $heap->{fork_name};

    # Do init (if needed)
    call_method($heap, '_fork_init');

    READ:
    while (sysread( STDIN, $raw, $size )) {
        my $requests = $filter->get( [$raw] );
        foreach my $request (@$requests) {
            # Need to capture STDOUT so the handle_request doesn't accidently write
            # to the STDOUT (reserved for communications with the control)
            my $capture = IO::Capture::Stdout->new();
            $capture->start();

            my $result = handle_request_wrapper($heap, $request);

            # Stop the STDOUT capture.  If it said anything, spit it out via
            # STDERR to display to the controlling terminal (or piped log)
            $capture->stop();
            while (my $line = $capture->read) {
                chomp $line;
                print STDERR "$line\n";
            }

            # Re-freeze the data structure and spit it out

            print STDOUT @{ $filter->put( [ $result ] ) };

            $request_counter++;
        }
        if ($request_max && $request_counter >= $request_max) {
            print STDERR "Closing fork as requests $request_counter >= max $request_max\n";
            return 1;
        }
    }
}

sub child_exited {
    my ($kernel, $heap, $sig_name, $child_id) = @_[KERNEL,HEAP,ARG0,ARG1];

    $heap->{talkback}("Child exited with signal $sig_name ($child_id)");
}

sub fork_input {
    my ($kernel, $heap, $input, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    my ($fork) = grep { $wheel_id == $_->{id} } @{ $heap->{forks} };
    die "Got fork input from an unknown wheel id" if ! $fork;

    if ($fork->{status} eq 'idle') {
        $heap->{talkback}("Got input from an idle fork");
        print STDERR Dumper($input, $fork);
        $kernel->yield('fork_closed', $wheel_id);
        return;
    }

    $fork->{status} = 'idle';
    $fork->{finished_request} = time;

    # Reply to the original request
    my $request = delete $fork->{active_request};
    $request->{result} = $input;
    $request->{elapsed} = $fork->{finished_request} - $fork->{started_request};
    $kernel->yield('return_result', $request);

    # Continue more requests if any
    $kernel->yield('process_queue');
}

sub fork_debug {
    my ($kernel, $heap, $input, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    my ($fork) = grep { $wheel_id == $_->{id} } @{ $heap->{forks} };
    die "Got fork error from an unknown wheel id" if ! $fork;

    my $method_name = $fork->{active_request}{method_name};
    $method_name ||= "(unknown)";

    $heap->{talkback}("STDERR:$wheel_id $method_name: $input");
}

sub fork_error {
    my ($kernel, $heap, $syscall, $errno, $errstr, $wheel_id, $handle) =
    @_[KERNEL, HEAP, ARG0 .. $#_];

    my ($fork) = grep { $wheel_id == $_->{id} } @{ $heap->{forks} };
    die "Got fork error from an unknown wheel id" if ! $fork;

    my $method_name = $fork->{active_request}{method_name};
    $method_name ||= "(unknown)";

    $heap->{talkback}("$handle:$wheel_id $method_name: Generated $syscall error $errno: $errstr");
}

sub fork_closed {
    my ($kernel, $heap, $wheel_id) = @_[KERNEL, HEAP, ARG0];

    my ($fork) = grep { $wheel_id == $_->{id} } @{ $heap->{forks} };
    die "Got fork closed from an unknown wheel id" if ! $fork;

    $heap->{talkback}("Fork $wheel_id closed");

    # Forks shouldn't close unless there's an error.  May also want to clean up after
    # zombies somehow... and reprocess requests that died...

    if ($fork->{active_request}{method_name}) {
        unshift @{ $heap->{request_queue} }, $fork->{active_request};
    }

    $fork->{wheel}->kill(9);

    # Remove the fork from the list
    my @new_list = grep { $wheel_id != $_->{id} } @{ $heap->{forks} };
    $heap->{forks} = \@new_list;

    # Continue more requests if any
    $kernel->yield('process_queue');
}

# hide from CPAN
package
    POE::Component::PreforkDispatch::PseudoXMLRPCTransaction;

use strict;
use warnings;

sub new {
    my ($class, @params) = @_;
    my %self = ( params => \@params );
    return bless \%self, $class;
}

sub params {
    my $self = shift;
    return $self->{params};
}

sub return {
    my ($self, $result) = @_;
    $self->{result} = $result;
}

sub result {
    my $self = shift;
    return $self->{result};
}

=head1 SEE ALSO

L<POE>, L<POE::Component::Pool::Thread>, L<POE::Component::JobQueue>

=head1 TODO

=over 4

=item * Class-based method discovery

=item * More tests

=back

=head1 AUTHOR

Eric Waters <ewaters@uarc.com>

=head1 COPYRIGHT

Copyright (c) 2007 Eric Waters and XMission LLC (http://www.xmission.com/). All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut

1;
