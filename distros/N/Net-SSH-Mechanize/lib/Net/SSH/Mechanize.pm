package Net::SSH::Mechanize;
#use AnyEvent::Log;
#use Coro;
use Moose;
use AnyEvent;
use Net::SSH::Mechanize::ConnectParams;
use Net::SSH::Mechanize::Session;
use AnyEvent::Subprocess;
#use Scalar::Util qw(refaddr);
use Carp qw(croak);
our @CARP_NOT = qw(AnyEvent AnyEvent::Subprocess Coro::AnyEvent);

# Stop our carp errors from being reported within AnyEvent::Coro
@Coro::AnyEvent::CARP_NOT = qw(AnyEvent::CondVar);

our $VERSION = '0.1.3'; # VERSION

#$AnyEvent::Log::FILTER->level("fatal");


my @connection_params = qw(host user port password);

# An object which defines a connection.
has 'connection_params' => (
    isa => 'Net::SSH::Mechanize::ConnectParams',
    is => 'ro',
    handles => \@connection_params,
);


has 'session' => (
    isa => 'Net::SSH::Mechanize::Session',
    is => 'ro',
    lazy => 1,
    default => sub {
        shift->_create_session;
    },
    handles => [qw(login login_async capture capture_async sudo_capture sudo_capture_async logout)],
);

# The log-in timeout limit in seconds
has 'login_timeout' => (
    is => 'rw',
    isa => 'Int',
    default => 30,
);


# This wrapper exists to map @connection_params into a
# Net::SSH::Mechanize::ConnectParams instance, if one is not supplied
# explicitly.
around 'BUILDARGS' => sub {
    my $orig = shift;
    my $self = shift;

    my $params = $self->$orig(@_);

    # check for connection_params paramter
    my $cp;
    if (exists $params->{connection_params}) {
        # Prevent duplication of parameters - if we have a connection_params
        # parameter, forbid the shortcut alternatives.
        foreach my $param (@connection_params) {
            croak "Cannot specify both $param and connection_params parameters"
                if exists $params->{$param};
        }

        $cp = $params->{connection_params};
        $cp = Net::SSH::Mechanize::ConnectParams->new($cp)
                if ref $cp eq 'HASH';
    }
    else {
        # Splice the short-cut @connection_params out of %$params and into %cp_params
        my %cp_params;
        foreach my $param (@connection_params) {
            next unless exists $params->{$param};
            $cp_params{$param} = delete $params->{$param};
        }

        # Try and construct a ConnectParams instance
        $cp = Net::SSH::Mechanize::ConnectParams->new(%cp_params);
    }

    return {
        %$params, 
        connection_params => $cp,
    };
};


######################################################################
# public methods



sub _create_session {
    my $self = shift;

    # We do this funny stuff with $session and $job so that the on_completion
    # callback can tell the session it should clean up
    my $session;
    my $job = AnyEvent::Subprocess->new(
        run_class => 'Net::SSH::Mechanize::Session',
        delegates => [
            'Pty', 
            'CompletionCondvar',
            [Handle => {
                name      => 'stderr',
                direction => 'r',
                replace   => \*STDERR,
            }],
        ],
        on_completion => sub {
            my $done = shift;
            
#            printf "xx completing child PID %d _error_event %s is %s \n",
#                $session->child_pid, $session->_error_event, $session->_error_event->ready? "ready":"unready"; #DB
            my $stderr = $done->delegate('stderr');
            my $errtext = $stderr->rbuf;
            my $msg = sprintf "child PID %d terminated unexpectedly with exit value %d",
                $session->child_pid, $done->exit_value, $errtext? "\n$errtext" : '';
            $session->_error_event->send($msg);
            undef $session;
        },
        code  => sub { 
            my $cmd = shift->{cmd};
            exec @$cmd;
        },
    );
    $session = $job->run({cmd => [$self->connection_params->ssh_cmd]});
    
    # Tack this on afterwards, mainly to supply the password.  We
    # can't add it to the constructor above because of the design of
    # AnyEvent::Subprocess.
    $session->connection_params($self->connection_params);

    # And set the login_timeout
    $session->login_timeout($self->login_timeout);

    # turn off terminal echo
    $session->delegate('pty')->handle->fh->set_raw;

    # Rebless $session into a subclass of AnyEvent::Subprocess::Running
    # which just supplies extra methods we need.
#    bless $session, 'Net::SSH::Mechanize::Session';

    return $session;
}



__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Net::SSH::Mechanize - asynchronous ssh command invocation 

=head1 VERSION

version 0.1.3

=head1 SYNOPSIS

Somewhat like C<POE::Component::OpenSSH>, C<SSH::Batch>,
C<Net::OpenSSH::Parallel>, C<App::MrShell> etc, but:

=over 4

=item *

It uses the asynchonous C<AnyEvent> event framework.

=item *

It aims to support sudoing smoothly.

=back

Synchronous usage:

    use Net::SSH::Mechanize;

    # Create an instance. This will not log in yet.
    # All but the host name below are optional.
    # Your .ssh/config will be used as normal, so if you 
    # define ssh settings for a host there they will be picked up.
    my $ssh = Net::SSH::Mechanize->new(
        host => 'somewhere.com',
        user => 'jbloggs',
        password => 'secret',
        port => 22,
    );

    my $ssh->login;

    my $output = $ssh->capture("id");

    # If successful, $output now contains something like:
    # uid=1000(jbloggs) gid=1000(jbloggs) groups=1000(jbloggs)

    $output = $ssh->sudo_capture("id");

    # If successful, $output now contains something like:
    # uid=0(root) gid=0(root) groups=0(root)

    $ssh->logout;

As you can see, C<Net::SSH::Mechanize> instance connects to only
I<one> host. L<Net::SSH::Mechanize::Multi|Net::SSH::Mechanize::Multi>
manages connections to many.

See below for further examples, and C<script/gofer> in the
distribution source for a working, usable example.

This is work in progress.  Expect rough edges.  Feedback appreciated.

  
=head1 DESCRIPTION

The point about using C<AnyEvent> internally is that "blocking" method
calls only block the current "thread", and so the above can be used in
parallel with (for example) other ssh sessions in the same process
(using C<AnyEvent>, or C<Coro>). Although a sub-process is spawned for
each ssh command, the parent process manages the child processes
asynchronously, without blocking or polling.

Here is an example of asynchronous usage, using the
C<<AnyEvent->condvar>> API.  Calls return an C<<AnyEvent::CondVar>>
instance, which you can call the usual C<< ->recv >> and C<< ->cb >>
methods on to perform a blocking wait (within the current thread), or
assign a callback to be called on completion (respectively).  See
L<AnyEvent>.

This is effectively what the example in the synopsis is doing, behind
the scenes.

    use Net::SSH::Mechanize;

    # Create an instance, as above.
    my $ssh = Net::SSH::Mechanize->new(
        host => 'somewhere.com',
        user => 'jbloggs',
        password => 'secret',
        port => 22,
    );

    # Accessing ->capture calls ->login automatically.
    my $condvar = AnyEvent->condvar;
    $ssh->login_async->cb(sub {
        my ($session) = shift->recv;
        $session->capture_async("id")->cb(sub {
            my ($stderr_handle, $result) = shift->recv;

            $condvar->send($result);
        });
    });

    # ... this returns immediately.  The callbacks assigned will get
    # invoked behind the scenes, and we just need to wait and collect
    # the result handed to our $condvar.

    my $result = $convar->recv;

    # If successful, $output now contains something like:
    # uid=1000(jbloggs) gid=1000(jbloggs) groups=1000(jbloggs)

    $ssh->logout;

You would only need to use this asynchronous style if you wanted to
interface with C<AnyEvent>, and/or add some C<Expect>-like interaction
into the code.

However, see also C<Net::SSH::Mechanize::Multi> for a more convenient
way of running multiple ssh sessions in parallel.  It uses Coro to
provide a (cooperatively) threaded model.

=head2 gofer

The C<script/> sub-directory includes a command-line tool called
C<gofer> which is designed to accept a list of connection definitions,
and execute shell commands supplied in the arguments in parallel on
each.  See the documentation in the script for more information.


=head1 JUSTIFICATION

The problem with all other SSH wrappers I've tried so far is that they
do not cope well when you need to sudo.  Some of them do it but
unreliably (C<SSH::Batch>), others allow it with some help, but then
don't assist with parallel connections to many servers (C<Net::OpenSSH>).
The I tried C<POE::Component::OpenSSH>, but I found the
C<POE::Component::Generic> implementation forced a painful programming
style with long chains of functions, one for each step in an exchange
with the ssh process.

Possibly I just didn't try them all, or hard enough, but I really
needed something which could do the job, and fell back to re-inventing
the wheel.  Initial experiments with C<AnyEvent> and C<AnyEvent::Subprocess>
showed a lot of promise, and the result is this.

=head1 CLASS METHODS

=head2 C<< $obj = $class->new(%params) >>

Creates a new instance.  Parameters is a hash or a list of key-value
parameters.  Valid parameter keys are:

=over 4

=item C<connection_params>

A L<Net::SSH::Mechanize::ConnectParams> instance, which defines a host
connection.  If this is given, any individual connection parameters
also supplied to the constructor (C<host>, C<user>, C<port> or
C<password>), will be ignored.

If this is absent, a C<Net::SSH::Mechanize::ConnectParams> instance is
constructed from any other individual connection parameters - the
minimum which must be supplied is C<hostname>.  See below.

=item C<host>

The hostname to connect to.  Either this or C<connection_params> must
be supplied.

=item C<user>

The user account to log into.  If not given, no user will be supplied
to C<ssh> (this typically means it will use the current user as
default).

=item C<port>

The port to connect to (C<ssh> will default to 22 if this is not
specificed).

=item C<password>

The password to connect with.  This is only required if authentication
will be performed, either on log-in or when sudoing.

=item C<login_timeout>

How long to wait before breaking a connection (in seconds). It is
passed to C<AnyEvent->timer> handler, whose callback will terminate
the session if the period is exceeded. This avoids hung connections
when the remote end isn't answering, or isn't answering in a way that
will allow C<Net::SSH::Mechanize> to terminate.

The default is 30.

=back


=head1 INSTANCE ATTRIBUTES

=head2 C<< $params = $obj->connection_params >>

This is a read-only accessor for the C<connection_params> instance
passed to the constructor (or equivalently, constructed from the
constructor parameters).

=head2 C<< $session = $obj->session >>

This is read-only accessor to a lazily-instantiated
C<Net::SSH::Mechanize::Session> instance, which represents the C<ssh>
process.  Accessing it causes the session to be created and the remote
host to be logged into.

=head2 C<< $obj->login_timeout($integer) >>
=head2 C<< $integer = $obj->login_timeout >>

This is a read-write accessor to the log-in timeout parameter passed
to the constructor.

It is passed to C<Net::SSH::Mechanize::Session>'s constructor, so if
you plan to modify it, do so before C<< ->session >> has been
instantiated or will not have any effect on anything thereafter.

=head1 INSTANCE METHODS

=head2 C<login>
=head2 C<login_async>
=head2 C<capture>
=head2 C<capture_async>
=head2 C<sudo_capture>
=head2 C<sudo_capture_async>
=head2 C<logout>

These methods exist here for convenience; they delegate to the
equivalent C<Net::SSH::Mechanize::Session> methods.


=head1 KNOWN ISSUES

=over 4

=item "unexpected stderr from command: stderr output" in test output

Something I haven't yet figured out how to banish properly. However,
it does appear to be harmless. Patches welcome.

=back

=head1 SEE ALSO

There are a lot of related tools, and this is just in Perl.  Probably
the most similar are C<SSH::Batch>, C<POE::Component::OpenSSH>, and
C<App::MrShell> (which at the time of writing, I've not yet tried.)  None
use C<AnyEvent>, so far as I can tell.

L<SSH::Batch>, L<Net::OpenSSH>, L<Net::OpenSSH::Parallel>, L<Net::SSH>, L<Net::SSH2>,L<
Net::SSH::Expect>, L<Net::SSH::Perl>, L<POE::Component::OpenSSH>, L<App::MrShell>.

=head1 AUTHOR

Nick Stokoe  C<< <wulee@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, Nick Stokoe C<< <wulee@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
