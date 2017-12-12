package Net::Async::Beanstalk;

our $VERSION = '0.002';
$VERSION = eval $VERSION;

=head1 NAME

Net::Async::Beanstalk - Non-blocking beanstalk client

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Net::Async::Beanstalk;

    my $loop = IO::Async::Loop->new();

    my $client = Net::Async::Beanstalk->new();
    $loop->add($client);

    $client->connect(host => 'localhost', service => '11300')->get();
    $client->put("anything")->get();

    $loop->run();

=head1 BUGS

=over

=item * Receiving on_disconnect after sending quit might not work.

In fact disconnecting hasn't been tested at all, even ad-hoc.

=item * This document is even longer.

=item * There are no tests

See if it's appropriate to steal the tests out of L<Beanstalk::Client>.

=back

=cut

use Moo;
use strictures 2;

use Carp;
use IO::Async::Stream;
use List::Util qw(any);
use MooX::EventHandler;
use Net::Async::Beanstalk::Constant qw(:state @GENERAL);
use YAML::Any  qw(Dump Load);
use namespace::clean;

=head1 DESCRIPTION

Implements the client-side of the beanstalk 1.10 protocol described in
L<https://raw.githubusercontent.com/kr/beanstalkd/v1.10/doc/protocol.txt>
using L<IO::Async> to provide an asynchronous non-blocking API.

Net::Async::Beanstalk is based on L<Moo> and
L<IO::Async::Stream>. Refer to those modules' documentation for basic
usage. In particular L<IO::Async::Loop/connect>.

=head1 ATTRIBUTES

Includes the command stack from L<Net::Async::Beanstalk::Send>.

=cut

with 'Net::Async::Beanstalk::Stack';

=over

=item default_priority (10,000)

=item defauly_delay (0)

=item default_ttr (120)

Default values to associate with a job when it is L</put> on the
beanstalk server. The defaults here are arbitrary; they have been
chosen to match the default values from L<AnyEvent::Beanstalk>.

=cut

has default_priority => is => lazy => builder => sub { 10_000 }; # Totally arbitrary

has default_delay    => is => lazy => builder => sub { 0 };

has default_ttr      => is => lazy => builder => sub { 120 };    # 2 minutes

=item decoder (&YAML::Load)

=item encoder (&YAML::Dump)

A coderef which will be used to deserialise or serialise jobs as they
are retreived from or sent to a beanstalk server.

This is not related to how the result of C<list> or C<stats> commands
are deserialised. This is always done using L<YAML/Load>.

=cut

# TODO: has codec => ...; ?

has decoder          => is => lazy => builder => sub { \&Load };

has encoder          => is => lazy => builder => sub { \&Dump };

=item using

The name of the tube which was recently L<use>d.

=cut

has using => is => rwp => init_arg => undef, default => 'default';

=item _watching

A hashref who's keys are the tubes which are being C<watch>ed. The
values are ignored.

Use the accessor C<watching> to get the list of C<watch>ed tubes
instead of using the attribute directly.

=cut

has _watching => is => rwp => init_arg => undef, default => sub {+{ default => 1 }};

sub watching { keys %{ $_[0]->_watching } }

=back

=cut

=head1 CLASS

A Net::Async::Beanstalk object represents a single connection to a
beanstalkd server. Once a connection has been established (see
L</CONNECTING>) commands may be submitted by calling the objects
methods (see L</COMMAND METHODS>).

The command methods all return a L<Future> which will either be
completed (marked C<done>) with the result if the command was a
success or failed with the error.

The command methods are named after the L<beanstalk
API|https://raw.githubusercontent.com/kr/beanstalkd/v1.10/doc/protocol.txt>
command that they implement, with the hyphens changed to an underscore
(C<s/-/_/g>). All command methods but L</put> take the same options in
the same order as the respective API command. L</reserve> also has an
option added to it so that it can be used to make reservations with or
without a timeout.

Some events may happen without a command having been sent or in spite
of a command being actively executed. These invoke the events
documented below and do I<not> complete or fail the associated
L<Future>. See the documentation of each error (there aren't many) for
the details in L</ERRORS>.

Although this class implements a non-blocking beanstalk client, the
protocol itself is not asynchronous. Each command sent will receive a
response before the next command will be processed although in
practice network buffering makes it appear that commands can be sent
while waiting for a previous command's response.

Ordinarily this is irrelevant as all the commands except C<reserve>
and C<reserve-with-timeout> respond quickly enough that any delay will
be negligible and this class' internal L<command
stack|Net::Async::Beanstalk::Stack> smooths over the times where
that's not the case.

When any command which blocks the server has been sent, other commands
will be stacked up waiting to be sent to the server but will not be
handled (that is, not even put on the wire) until the running command
command has completed (perhaps with a timeout).

If this is a concern, the beanstalkd server is explicitly written to
support multiple connections with low overhead, so there is no need to
perform all operations using the same client object. Just be aware
that the list of active tubes is not copied (by default) from one
client to another. Each client starts off using and watching the
C<default> tube.

When a job has been reserved by a client (which remains connected)
that job is invisible to any other clients. It cannot, for example, be
deleted except over the same connected in which it was reserved and if
that connection is closed the job will return to the ready queue and
may be reserved by another client.

=head1 CONNECTING

Voodoo.

=head1 ERRORS

=for comment Move this to ::Receive

There are not many error conditions described by the beanstalk
protocol. L<Net::Async::Beanstalk::Receive> also defines errors in the
event of bugs revealing mistakes in this code or communication
failures. Each will cause either the current L<Future> to fail, raise
an event, or both.

See each error's description but by and large the errors that happen
because a command failed (which is not the same thing thing as "while
a command was active") fail the L<Future> while the error conditions
that arise spontaneously invoke an C<on_error> event (defined in
L<IO::Async::Notifier>). If the Net::Async::Beanstalk object (or its
parent) is created without an C<on_error> handler then the default
C<on_error> handler will be used which calls L<die|perlfunc/die>.

Except where noted each error or failure includes the arguments which
were sent with the command to the server (not including the command
itself). If you call a command such as this

    my $give_it_a_rest = $beanstalk->bury(0x6642, 9_001);

then $give_it_a_rest will hold a L<Future> which will eventually fail
and call its handler with:

    $h->("...buried: 26180 not found", "beanstalk-peek", 0x6632, 9_001);

The exceptional errors are:


=for comment = find all three errors.

=over

=item C<Protocol error: Bad format>

Category: C<beanstalk-internal>

Arguments: The buffer which was written into the communication stream.

This error invokes an C<on_error> event and fails the active L<Future>.

The server received a command line that was not well-formed. This
should never happen and when it does it indicates an error in this
module. Please report it so that it can be repaired.

=item C<Protocol error: Internal error>

Category: C<beanstalk-server>

Arguments: Everything.

This error invokes C<on_error> only.

The server suffered from an internal error. This should never happen
and when it does it indicates an error in the server. Please report it
to the L<beanstalk maintainer|http://kr.github.com/beanstalkd/> so
that it can be repaired.

This error does not attempt to fail the current or any pending
L<Future>s, however the server's probably about to crash so your code
should deal with that and the pending L<Future>s gracefully.

=item C<Protocol error: Out of memory>

Category: C<beanstalk-server>

Arguments: The command name and then the arguments as usual.

This error only fails the active L<Future>.

The server ran out of memory. This happens sometimes but generally it
should not. Please report it to your system administrator so that he
can be repaired.

=item C<Protocol error: Unknown command>

Category: C<beanstalk-internal>

Arguments: The command name and then the arguments as usual.

This error invokes an C<on_error> event and fails the active L<Future>.

This module sent a command the server did not understand. This should
never happen and when it does it indicates an error in the server or a
protocol mismatch between the server and client.

=item C<Protocol error: Unknown response>

Category: C<beanstalk-server>

Arguments: The buffer which was received from the communication stream
as an arrayref of each received chunk.

This error invokes C<on_error> only.

The server sent a message this client did not understand. This should
never happen and when it does it indicates an error in the server or a
protocol mismatch between the server and client.

This error does not attempt to fail the current or any pending
L<Future>s, however the server's speaking gibberish so nobody knows
what's going to happen next. Your code should deal with that and the
pending L<Future>s gracefully.

=back

In order to make the command stack work, each L<Future> is created
with an C<on_ready> handler which sends the next pending command. In
the event of an error the pending commands may become invalid. This
class makes no attempt to deal with that.

One other protocol error (C<Expected cr+lf>) can be received only in
response to a L</put> command (it does not invoke an L<on_error>
event).

=head1 COMMAND METHODS

=for comment Move this to ::Send

Methods which initiate a command on the server are implemented in
L<Net::Async::Beanstalk::Send>. The server response is processed by
the event handlers in L<Net::Async::Beanstalk::Receive>. Every command
method returns a L<Future> which will complete with the server's
response to that command, whether success or failure.

With few exceptions, documented below, each method expects exactly the
arguments that the respective command requires. The commands which
expect to receive a YAML structure as the response (primarily the
C<list-*> commands) deserialise the response before returning it as a
(non-reference) list or hash.

The methods are named with a C<_> where the API command has a C<->.

See
L<the protocol documentation|https://raw.githubusercontent.com/kr/beanstalkd/v1.10/doc/protocol.txt>
for further details on each command. They are:

=over

=item put ($job, %options) or put (%options)

Put a job onto the currently C<use>d tube. The job data can be passed
as the method's first argument or in C<%options>.

The job's C<priority>, C<delay> or C<ttr> can be set by including
those values in C<%options>. If they are not then the object's default
value is used (see above).

The job may be passed as the method's first or only argument or as
C<data> in C<%options>. It will be serialised using L</encoder> if
it's a reference and does not overload the stringify (C<"">) operator.

The job may instead be passed as C<raw_data> in C<%options> if it has
already been serialised.

Regardless of whether C</encoder> is used to serialise the job it is
changed to a string of bytes using L<utf8::encode|utf8/encode>.

It is an error to pass the job data in more than one form or to
included unknown options and C<put> will L<croak|Carp/croak>.

Possible failures:

=over

=item C<Protocol error: Expected cr+lf>

Category: C<beanstalk-put>

Arguments: As with C<bad format>, this should but does not include the
buffer which was sent.

This error only fails the active L<Future>.

The client sent badly-formed job data which was not terminated by a
CR+LF pair. This should never happen and when it does it indicates an
error in this module. Please report it so that it can be repaired.

=item C<Invalid job: too big>

Category: C<beanstalk-put>

The client sent job data which was rejected by the server for being
too large. The job has not beed stored in any queue.

=item C<Job was inserted but buried (out of memory): ID $id>

Category: C<beanstalk-put>

The job was successfully received by the server but it was unable to
allocate memory to put it into the ready queue and so the job has been
buried.

=item C<Job was not inserted: Server is draining>

Category: C<beanstalk-put>

The server is currently being drained and is not accepting new
jobs. The job has not been stored in any queue.

=back

=item reserve (%options)

Reserve the next available job. C<timeout> may be passed in
C<%options> in which case the C<reserve-with-timout> command is sent
instead. C<timeout> may be C<0>.

The data returned by the server is transformed into a string of
characters with L<utf8/decode> then deserialised using C</decoder>.

If the C<asis> option is set to a true value then the data returned by
the server is transformed into characters but is not deserialised.

If the C<raw> option is set to a true value then the data is left
completely untouched.

Possible failures:

=over

=item C<No job was reserved: Deadline soon>

Category: C<beanstalk-reserve>

A job which was previously reserved by this client and has not been
handled is nearing the time when its reservation will expire and the
server will restore it to the ready queue.

=back

=item reserve_with_timeout ($time, %options)

Implemented by calling L</reserve> with a C<timeout> option. C<$time>
may be 0 which will cause the L<Future> to fail immediately with a
C<Timed out> error if there are no jobs available.

Possible failures:

=over

=item C<No job was reserved: Timed out>

Category: C<beanstalk-reserve>

The number of seconds specified in the timeout value to
C<reserve-with-timeout> has expired without a job becoming ready to
reserve.

=back

In addition all the failures possible in response to the L</reserve>
command can be received in response to C<reserve_with_timeout>.

=item bury ($job_id)

Possible failures:

=over

=item C<The job could not be buried: $id not found>

Category: C<beanstalk-job>

The job with ID C<$id> could not be buried because it does not exist
or has not been previously reserved by this client.

=for comment TODO: Can a job be buried if it is reserved by _no_ client?

=back

=item delete ($job_id)

Possible failures:

=over

=item C<The job could not be deleted: $id not found>

Category: C<beanstalk-job>

The job with ID C<$id> could not be deleted because it does not exist,
has not been previously reserved by this client or is not in a
C<ready> or C<buried> state.

=back

=item ignore ($tube_name)

Possible failures:

=over

=item C<The last tube cannot be ignored: $tube>

Category: C<beanstalk-tube>

The client attempted to ignore the only tube remaining in its watch
list.

=for comment Is it an error to ignore a tube which is not being watched?

=back

=item kick_job ($job_id)

Possible failures:

=over

=item C<The job could not be kicked: $id not found>

Category: C<beanstalk-job>

The job with ID C<$id> could not be kicked because it "is not in a
kickable state".

=for comment The documentation is vague and includes the possibility
of "internal errors".

=back

=item kick ($max)

This command should not fail.

=item list_tubes ()

This command should not fail.

=item list_tubes_watched ()

This command should not fail.

=item list_tube_used ()

This command should not fail.

=item pause_tube ($tube_name, $delay)

Possible failures:

=over

=item C<The tube could not be paused: $tube not found>

Category: C<beanstalk-tube>

The tube could not be paused because it doesn't exist.

=back

=item peek ($job_id)

Possible failures:

=over

=item C<The job could not be peeked at: $id not found>

Category: C<beanstalk-peek>

The specified job could not be retrieved because it does not exist.

=back

=item peek_buried ()

Possible failures:

=over

=item C<The next buried job could not be peeked at: None found>

Category: C<beanstalk-peek>

The next job in a buried state could not be retrieved because one does
not exist.

=back

=item peek_delayed ()

Possible failures:

=over

=item C<The next delayed job could not be peeked at: None found>

Category: C<beanstalk-peek>

The next job in a delayed state could not be retrieved because one
does not exist.

=back

=item peek_ready ()

Possible failures:

=over

=item C<The next ready job could not be peeked at: None found>

Category: C<beanstalk-peek>

The next job in a ready state could not be retrieved because one does
not exist.

=back

=item quit ()

In theory this will raise an C<on_disconnect> in addition to
completing the L<Future> it returns. In practice I haven't written it
yet.

=item release ($job_id, $priority, $delay)

Possible failures:

=over

=item C<The job could not be released: $id not found>

Category: C<beanstalk-job>

The job with ID C<$id> could not be released because it does not exist
or has not been previously reserved by this client.

=for comment TODO: What if an attempt is made to release a released job?

=item C<The job could not be released (out of memory): ID $id>

Category: C<beanstalk-job>

The job with ID C<$id> could not be released because the server ran
out of memory.

=back

=item stats ()

This command should not fail.

=item stats_job ($job_id)

Possible failures:

=over

=item C<Statistics were not found for the job: $id not found>

Category: C<beanstalk-job>

No statistics are available for the job with ID C<$id> because it does
not exist.

=back

=item stats_tube ($tube_name)

Possible failures:

=over

=item C<Statistics were not found for the tube: $tube not found>

Category: C<beanstalk-tube>

No statistics are available for the tube named C<$tube> because it
does not exist.

=back

=item touch ($job_id)

Possible failures:

=over

=item C<The job could not be touched: $id not found>

Category: C<beanstalk-job>

The job with ID C<$id> could not be touched because it does not exist
or has not been previously reserved by this client.

=back

=item use ($tube_name)

This command should not fail.

=item watch ($tube_name)

This command should not fail.

=back

=cut

with 'Net::Async::Beanstalk::Receive';

with 'Net::Async::Beanstalk::Send';

=head1 OTHER METHODS

=over

=item reserve_pending () => @commands

Returns a all the entries in L<the command stack|/_command_stack>
which refer to a C<reserve> or C<reserve-with-timeout> command.

=cut

sub reserve_pending {
  scalar grep { $_->[STATE_COMMAND] =~ /^reserve/ } $_[0]->_pending_commands;
}

=item disconnect () => $future

An alias for L<quit>.

=cut

*disconnect = \&quit;

=item sync () => $future

Returns a L<Future> which completes when all pending commands have
been responded to.

=cut

sub sync { Future->wait_all(map { $_->[STATE_FUTURE] } $_[0]->_pending_commands) }

=item watch_only (@tubes) => $future

Send a C<list-tubes-watched> command and based on its result send a
series of C<watch> and then C<ignore> commands so that the tubes being
watched for this client exactly matches C<@tubes>.

=cut

sub watch_only {
  my $self = shift;
  my %want = map{+($_=>1)} @_;
  $self->list_tubes_watched->then(sub {
    my %current = map {+($_=>1)} @_;
    my @watch  = map { $self->watch($_)  } grep { not $current{$_} } keys %want;
    my @ignore = map { $self->ignore($_) } grep { not $want{$_} } keys %current;
    Future->wait_all(@watch, @ignore);
  });
}

=back

=head1 INTERNAL METHODS

=over

=item _assert_state($response_word) => VOID

Raises an exception of the word received from the server is not
something expected in response to the command which has most recently
been sent.

=cut

sub _assert_state {
  my $self = shift;
  my ($response) = @_;
  return if any { $response eq $_ } @GENERAL;
  croak "Internal error: $response in null state" unless $self->count_commands;
  my $state = $self->current_command;
  croak "Internal error: $response in invalid state " . $state->[STATE_COMMAND]
    unless exists $STATE_CAN{$state->[STATE_COMMAND]}{$response};
}

=item fail_command($message, $exception, @args) => $future

Remove the current command from the command stack and fail its
L<Future> with this method's arguments.

The L<Future> returned is the one which returned when initiating a
command and can be safely ignored.

This is used by L<Net::Async::Beanstalk::Receive> when the client
received an expected response which nevertheless indicates an error of
some kind, such as C<DEADLINE_SOON> received in response to a
C<reserve> command.

=cut

sub fail_command { $_[0]->_shift_command->[0]->fail(@_[1..$#_]) }

=item finish_command($event, @args) => $future

Remove the current command from the command stack and complete its
L<Future> with this method's arguments.

The L<Future> returned is the one which returned when initiating a
command and can be safely ignored.

This is used by L<Net::Async::Beanstalk::Receive> when the server sent
a response to a command which indicates successful completion.

=cut

sub finish_command { $_[0]->_shift_command->[0]->done(@_[1..$#_]) }

# Messy Moo/IO::Async stuff

# TODO: Don't use IaProtocol. Apparently it's bad.
BEGIN { our @ISA; unshift @ISA, 'IO::Async::Stream' }

my @events = qw(
  on_disconnect
);

# TODO: MooX::EventHandler is looking less and less useful.
has_event $_ for @events;

my @attributes = qw(
  default_delay
  default_priority
  default_ttr
  encoder
  decoder
);

sub FOREIGNBUILDARGS {
  my $class = shift;
  my %args = @_;
  delete @args{@attributes, @events};
  return %args;
}

1;

=back

=head1 ALTERNATIVE IMPLEMENTATIONS

=over

=item L<AnyEvent::Beanstalk>

A good module and asynchronous but it uses L<AnyEvent> which ... the
less said the better. The core of the protocol is implemented but it
does not handle all error conditions. I have attempted to make
L<Net::Async::Beanstalk>'s API superficially similar to this one.

=item L<Beanstalk::Client>

Also written by Graham Barr, this module seems to be slightly more
functionally complete than its L<AnyEvent> counterpart and has proven
itself stable and fast but unfortunately does not operate
asynchronously.

=item L<AnyEvent::Beanstalk::Worker>

Unfortunately also based on L<AnyEvent> which is a shame because it
implements what appears to be an interesting FSA using beanstalk
queues.

=item L<Queue::Beanstalk>

Ancient, presumably unsupported and based on an out-dated version of
the beanstalk protocol.

=back

=head1 SEE ALSO

L<IO::Async>

L<Future>

L<http://kr.github.com/beanstalkd/>

L<https://raw.githubusercontent.com/kr/beanstalkd/v1.10/doc/protocol.txt>

=head1 AUTHOR

Matthew King <chohag@jtan.com>

=cut
