package Net::Async::Beanstalk;

our $VERSION = '0.001';
$VERSION = eval $VERSION;

=head1 NAME

Net::Async::Beanstalk - Non-blocking beanstalk client

=head1 SYNOPSIS

    use IO::Async::Loop;
    my $loop = IO::Async::Loop->new();

    use Net::Async::Beanstalk;
    my $client = Net::Async::Beanstalk->new();
    $loop->add($client);
    $client->connect(host => 'localhost', service => '11300',
                     on_connected => sub { $client->put("anything") });

    $loop->run();

=head1 BUGS

=over

=item * Some events are invoked with useless data.

=item * Receiving on_disconnect after sending quit might not work.

In fact disconnecting hasn't been tested at all, even ad-hoc.

=item * Protocol errors and the corresponding future exception are out
of sync.

=item * Net::Async::Beanstalk::Receive is highly repetetive.

=item * This document is too long.

=item * There are no tests

See if it's appropriate to steal the tests out of L<Beanstalk::Client>.

=back

=cut

use Moo;
use strictures 2;

use Carp;
use IO::Async::Protocol::Stream;
use List::Util qw(any);
use MooX::EventHandler;
use MooX::HandlesVia;
use Net::Async::Beanstalk::Constant qw(:state @GENERAL);
use YAML::Any  qw(Dump Load);
use namespace::clean;

=head1 DESCRIPTION

Implements the client-side of the beanstalk 1.10 protocol described in
L<https://raw.githubusercontent.com/kr/beanstalkd/v1.10/doc/protocol.txt>
using L<IO::Async> to provide an asynchronous non-blocking API.

Responses from the server can be handled with events registered in the
client object or by waiting on a L<Future> which is returned from the
function that initiated a command request.

Net::Async::Beanstalk is based on L<Moo> and
L<IO::Async::Protocol::Stream>. Refer to those modules' documentation
for basic usage. In particular L<IO::Async::Protocol/connect>.

Although this module implements a non-blocking beanstalk client, the
protocol itself is not asynchronous. Each command sent will receive a
response before the next command will be processed although in
practice network buffering makes it appear that commands can be sent
while waiting for a previous command's response.

Ordinarily this is irrelevant as all the commands except C<reserve>
and C<reserve-with-timeout> respond quickly enough that any delay will
be negligible and this module's internal command stack smooths over
the times where that's not the case. When a C<reserve> or a
C<reserve-with-timeout> command has been sent any other commands will
be stacked up waiting to be sent to the server but will not be handled
until the C<reserve>/C<reserve-with-timeout> command has completed or
the timeout has expired.

If there is a need to send a command while a C<reserve> or
C<reserve-with-timeout> is pending then another client object can be
created to do it. Note that while a job is reserved by a client (and
it remains connected) that job is invisible to any other clients. It
cannot, for example, be deleted except over the same connected in
which it was reserved and if that connection is closed the job will
return to the ready queue and may be reserved by another client.

=cut

my @attributes = qw(
  default_delay
  default_priority
  default_ttr
  encoder
  decoder
);

my @events = qw(
  on_disconnect
  on_draining
  on_job_bury          on_job_bury_not_found
  on_job_delete        on_job_delete_not_found
  on_job_insert                                      on_job_insert_fail
  on_job_kick          on_job_kick_not_found
  on_job_peek          on_job_peek_not_found
  on_job_peek_bury     on_job_peek_bury_not_found
  on_job_peek_delayed  on_job_peek_delayed_not_found
  on_job_peek_ready    on_job_peek_ready_not_found
  on_job_release       on_job_release_not_found      on_job_release_fail
  on_job_reserve
  on_job_stats         on_job_stats_not_found
  on_job_touch         on_job_touch_not_found
  on_list_tubes
  on_list_tubes_watched
  on_list_use
  on_protocol_error
  on_server_stats
  on_time_out
  on_ttr_soon
  on_tube_ignore                                     on_tube_ignore_fail
  on_tube_kick
  on_tube_pause        on_tube_pause_not_found
  on_tube_stats        on_tube_stats_not_found
  on_tube_use
  on_tube_watch
);

BEGIN { our @ISA; unshift @ISA, 'IO::Async::Protocol::Stream' }

sub FOREIGNBUILDARGS {
  my $class = shift;
  my %args = @_;
  delete @args{@attributes, @events};
  return %args;
}

has_event $_ for @events;

with 'Net::Async::Beanstalk::Send';

with 'Net::Async::Beanstalk::Receive';

=head1 ATTRIBUTES

=over

=item default_priority (10,000)

=item defauly_delay (0)

=item default_ttr (120)

Default values to associate with a job when it is L</put> on the
beanstalk server. The defaults are arbitrary but chosen to match the
default values from L<AnyEvent::Beanstalk>.

=cut

has default_priority => is => lazy => builder => sub { 10_000 }; # Totally arbitrary

has default_delay    => is => lazy => builder => sub { 0 };

has default_ttr      => is => lazy => builder => sub { 120 };    # 2 minutes

=item decoder (&YAML::Load)

=item encoder (&YAML::Dump)

A coderef which will be used to deserialise or serialise jobs as they
are retreived from or sent to a beanstalk server.

=cut

# TODO: has codec => ...; ?

has decoder          => is => lazy => builder => sub { \&Load };

has encoder          => is => lazy => builder => sub { \&Dump };

=item using

The name of the tube most recently L<use>d.

=cut

has using => is => rwp => init_arg => undef, default => 'default';

=item _watching

A hashref who's keys are the tubes which are being C<watch>ed. The
values are irrelevant.

Use the accessor C<watching> to get the list of C<watch>ed tubes
instead of using the attribute directly.

=cut

has _watching => is => rwp => init_arg => undef, default => sub {+{ default => 1 }};

sub watching { [ keys %{ $_[0]->_watching } ] }

=item _command_stack

=for comment Documented out of order because this attribue isn't
particularly interesting to users of this module.

An internal FIFO stack of commands which are waiting to be sent or
responded to.

Accessors:

=over

=item count_commands

How many commands are in the stack, including the one which the server
is currently processing.

=item current_command

Returns the command the server is currently processing, or has just
sent a response to, without removing it from the stack.

=item is_busy

A boolean indicating whether the client is busy, ie. has a command
currently being processed or has commands waiting to be sent. Actually
implemented by the same method as L</count_commands>.

=item _pending_commands

Returns the commands which have not yet completed, including the one
which the server is currently processing.

=item _push_command

Push a new command onto the stack.

=item _shift_command

Remove and return the first command from the stack, which the server
is either processing or has returned a response to.

=back

=cut

has _command_stack => (
  is          => 'ro',
  init_arg    => undef,
  default     => sub { [] },
  handles_via => 'Array',
  handles     => {
    count_commands    => 'count',
    is_busy           => 'count',
    _pending_commands => 'all',
    _push_command     => 'push',
    _shift_command    => 'shift',
  },
);

sub current_command { $_[0]->_command_stack->[0] || croak "No active command" }

=back

=cut

=head1 COMMAND METHODS

Methods which initiate a command on the server are implemented in
L<Net::Async::Beanstalk::Send>. The server response is processed by
the event handlers in L<Net::Async::Beanstalk::Receive>.

Every method returns a L<Future> which will complete with the server's
response to that command, whether success or failure. With few
exceptions, documented below, each method expects exactly the
arguments that the respective command requires. The commands which
expect a YAML structure deserialise the response before returning
it.

As well as completing (or failing) the L<Future> returned when the
command is sent, each response from the server will attempt to invoke
an event. It is probably not a good idea to mix code which waits for
futures with code which handles events.

However all commands can invoke one of the error events if an
exceptional condition arises and as this is done using
L<invoke_error|IO::Async::Notifier/invoke_error> which will call die
if the C<on_error> event is not handled.

All commands can potentially invoke these error events, which will
raise an exception if an C<on_error> event handler has not been
installed.

=over

=item on_error (C<Protocol error: Bad format>)

Failed future's exception: C<invalid>

=item on_error (C<Protocol error: Internal error>)

Failed future's exception: C<server-error>

=item on_error (C<Protocol error: Out of memory>)

Failed future's exception: C<server-error>

=item on_error (C<Protocol error: Unknown command>)

Failed future's exception: C<invalid>

=item on_error (C<Protocol error: Unknown response>)

Failed future's exception: C<unknown>

=back

See
L<the protocol documentation|https://raw.githubusercontent.com/kr/beanstalkd/v1.10/doc/protocol.txt>
for further details on each command.

The methods are named with a C<_> where the respective protocol
command has a C<->. They are:

=over

=item put ($job, %options) or put (%options)

Put a job onto the currently C<use>d tube. The job data can be passed
as the method's first argument or in C<%options>.

The job's C<priority>, C<delay> or C<ttr> can be set by including
those values in C<%options>. If they are not then the client's default
value is used (see above).

If the job is passed as the method's first argument and it is a
reference which does not overload the stringify (C<"">) operator then
it is first serialised using L</encoder>.

Alternatively the job may be passed in options as C<raw_data>, which
is sent to beanstalk as-is, or as C<data> which is first serialised
using L</encoder>. It should probably be considered a bug that C<$job>
and C<$options{data}> are handled treated differently.

Regardless of whether C</encoder> is used to transform the job data,
it is first changed to a string of bytes using L<utf8/encode>.

It is an error to pass the job data in more than one form or to
included unknown options.

Possible events:

=over

=item on_error (C<Protocol error: Expected cr+lf>)

Failed future's exception: C<invalid>

=item on_error (C<Protocol error: Job too big>)

Failed future's exception: C<invalid>

=item on_job_insert ($job_id)

=item on_job_insert_fail (?)

=item on_draining (?)

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

Possible events:

=over

=item on_time_out (?)

=item on_ttr_soon (?)

=item on_job_reserve ($job_id, $data)

=back

=item reserve_with_timeout ($time, %options)

Implemented by calling L</reserve> with a C<timeout> option.

=item bury ($job_id)

Possible events:

=over

=item on_job_bury ($job_id)

=item on_job_bury_not_found ($job_id)

=back

=item delete ($job_id)

Possible events:

=over

=item on_job_delete ($job_id)

=item on_job_delete_not_found ($job_id)

=back

=item ignore ($tube_name)

Possible events:

=over

=item on_tube_ignore ($tube, $count)

=item on_tube_ignore_fail ($tube)

=back

=item kick_job ($job_id)

Possible events:

=over

=item on_job_kick ($job_id)

=item on_job_kick_not_found ($job_id)

=back

=item kick ($max)

Possible events:

=over

=item on_tube_kick ($tube, $count)

=back

=item list_tubes ()

Possible events:

=over

=item on_list_tubes (@tubes)

=back

=item list_tubes_watched ()

Possible events:

=over

=item on_list_tubes_watched (@tubes)

=back

=item list_tube_used ()

Possible events:

=over

=item on_list_use ($tube)

=back

=item pause_tube ($tube_name, $delay)

Possible events:

=over

=item on_tube_pause ($tube)

=item on_tube_pause_not_found ($tube)

=back

=item peek ($job_id)

Possible events:

=over

=item on_job_peek ($job_id, $data)

=item on_job_peek_not_found ($job_id)

=back

=item peek_buried ()

Possible events:

=over

=item on_job_peek_bury ($job_id, $data)

=item on_job_peek_bury_not_found ($job_id)

=back

=item peek_delayed ()

Possible events:

=over

=item on_job_peek_delay ($job_id, $data)

=item on_job_peek_delay_not_found ($job_id)

=back

=item peek_ready ()

Possible events:

=over

=item on_job_peek_ready ($job_id, $data)

=item on_job_peek_ready_not_found ($job_id)

=back

=item quit ()

Possible events:

=over

=item on_disconnect

=back

=item release ($job_id, $priority, $delay)

Possible events:

=over

=item on_job_release ($job_id)

=item on_job_release_fail ($job_id)

=item on_job_release_not_found ($job_id)

=back

=item stats ()

Possible events:

=over

=item on_server_stats (%stats)

=back

=item stats_job ($job_id)

Possible events:

=over

=item on_job_stats (%stats)

=item on_job_stats_not_found ($job_id)

=back

=item stats_tube ($tube_name)

Possible events:

=over

=item on_tube_stats (%stats)

=item on_tube_stats_not_found ($tube_name)

=back

=item touch ($job_id)

Possible events:

=over

=item on_job_touch ($job_id)

=item on_job_touch_not_found ($job_id)

=back

=item use ($tube_name)

Possible events:

=over

=item on_tube_use ($tube_name)

=back

=item watch ($tube_name)

Possible events:

=over

=item on_tube_watch ($tube_name, $count)

=back

=back

=cut

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

=item error_command ($exception, $message, @args) => $future

Calls C<invoke_error> on the client object with C<$message> and
C<@args> then removes the current command from the command stack and
fails the L<Future> associated with it with C<$exception> and
C<@args>.

The L<Future> returned is the same as that returned when initiating a
command and can be safely ignored.

This is used by L<Net::Async::Beanstalk::Receive> to indicate serious
communication or internal errors and should never happen. It is called
in response to any of these:

=over

=item Invalid response from server

=item BAD_FORMAT

=item EXPECTED_CRLF

=item INTERNAL_ERROR

=item JOB_TOO_BIG

=item OUT_OF_MEMORY

=item UNKNOWN_COMMAND

=back

=cut

sub error_command {
  my $self = shift;
  my ($ex, $msg, @args) = @_;
  $self->invoke_error($msg => @args);
  $self->_shift_command->[0]->fail($ex, @args);
}

=item fail_command($event, $exception, @args) => $future

Attempts to invoke the C<$event> event if there is a handler for it
with C<@args> then removes the current command from the command stack
and fails the L<Future> associated with it with C<$exception> and
C<@args>.

The L<Future> returned is the same as that returned when initiating a
command and can be safely ignored.

This is used by L<Net::Async::Beanstalk::Receive> when the client
received an expected response which nevertheless indicates an error of
some kind, such as C<DEADLINE_SOON> received in response to a
C<reserve> command.

=cut

sub fail_command {
  my $self = shift;
  my ($event, $ex, @args) = @_;
  $self->maybe_invoke_event($event => @args);
  $self->_shift_command->[0]->fail($ex, @args);
}

=item finish_command($event, @args) => $future

Attempts to invoke the C<$event> event if there is a handler for it
with C<@args> then removes the current command from the command stack
and completes the L<Future> associated with it with C<@args>.

The L<Future> returned is the same as that returned when initiating a
command and can be safely ignored.

This is used by L<Net::Async::Beanstalk::Receive> when the server sent
a response to a command which indicates success.

=cut

sub finish_command {
  my $self = shift;
  my ($event, @args) = @_;
  $self->maybe_invoke_event($event => @args);
  $self->_shift_command->[0]->done(@args);
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
