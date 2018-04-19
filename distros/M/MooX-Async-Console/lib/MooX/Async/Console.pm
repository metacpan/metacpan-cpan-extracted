package MooX::Async::Console;

our $VERSION = '0.103';
$VERSION = eval $VERSION;

=head1 NAME

MooX::Async::Console - Attach a console to an async module

=head1 SYNOPSIS

    my Thing;
    use MooX::Async;
    with 'MooX::Async::Console';
    has _console => is => lazy => builder => sub {
        $_[0]->_launch_console(TCP => address => '127.0.0.1', port => 4242);
    };
    event cmd_foo => sub {
        my $self = shift;
        my %args = @_;
        say "foo";
        $args{inform}->('this thing is happening');
        $args{then}->done('finished');
    };

=head1 DESCRIPTION

Attaches some machinery to an object which allows it to start
listeners such as on a TCP or unix socket which expose a console
interface to the object.

This module is a role which mixes in the L</_launch_console> method
and implements a L</ping> and L</quit> command. Another module such as
L<MooX::Async::Console::TCP> is responsible for managing the socket
and the framing protocol.

=head1 BUGS

Certainly.

=cut

use Modern::Perl '2017';
use strictures 2;

use Moo::Role;
use Future;
use Module::Runtime qw(compose_module_name use_module);
use MooX::Async;
use Scalar::Util    qw(blessed);
use Syntax::Keyword::Try;
use namespace::clean;

with 'MooX::Role::Logger';

=head1 METHODS

=over

=item _launch_console($module, [@args]) => $console_instance

Loads C<MooX::Async::Console::$module> and creates a new instance of
it (with C<@args>) who's C<on_command> event will invoke commands on
C<$self>.

If C<$module> begins with C<::> it is removed and the remainder used
as-is.

    $self->_launch_console('My::Console::Socket', argu => 'meant');

At present this distribution includes one socket layer module,
L<MooX::Async::Console::TCP>.

An C<on_command> event handler is unconditionally appended to the
arguments passed to the console's constructor.

Its interface is desribed in L</on_command> in L</COMMANDS>.

=cut

sub _launch_console {
    my $self = shift;
    my $module = compose_module_name(__PACKAGE__, shift);
    my $executive = sub { unshift @_, $self; goto \&__execute };
    use_module($module)->new(@_, on_command => $executive);
}

=back

=head1 COMMANDS

The command handler will be invoked with the arguments decoded by the
socket layer implementation launched by L</_launch_console>. Usually
these will come in the form of key/value pairs but need not. 4 items
will be appended to the argument list, which therefore constitute two
entries which will be included in the command handlers' args if it
treats C<@_> like a hash.

=over

=item inform => $subref

A subref the command handler can use to send messages to the connected
client. What is suitable for the socket layer to receive is not
defined. L<MooX::Async::Console::TCP> can accept 0 or more scalars
which it concatenates, so probably at least that.

=item then => $future

A L<Future> which the command handler can complete or fail with the
result of executing the command.

=back

The return value from the command handler is usually ignored.

If a L<Future> is returned from the command then that is what's used
to determine when the command has completed instead of L</then> which
was given to the command handler. The command handler is free then to
do with the L<Future> as it wishes; it is no longer used by this
module.

    sub cmd_generic {
      my $self = shift;
      my %args = @_;
      # If you're not sure about the arguments: my %args = @_[-4..-1];
      # or: my ($then, undef, $inform, undef) = map pop, 1..4;
      ...;
      $args{inform}->(...);
      $args{inform}->(...);
      ...;
      $args{then}->done(...);
    }

=over

=item ping [$nonce]

Respond with C<pong> and <$nonce>, if given. Other arguments are
ignored.

=cut

event cmd_ping => sub {
  my $ping = @_ > 5 ? $_[1] : undef;
  $_[0]->_logger->tracef('ping %s', $ping);
  $_[-1]->done(pong => $ping // ());
};

=item quit

Disconnect this client session. Arguments are accepted and ignored.

=cut

event cmd_quit => sub {
  my $self = shift;
  my %args = @_;
  $self->_logger->tracef('Client quit');
  $args{then}->fail(('quit')x2);
};

=back

=head1 EVENTS

=over

=item on_command

Understanding this is not necessary to link a console into your own
code, it describes the interface used when implementing one's own
socket layer.

The event handler invoked when a client executes a command. The
definition of the command and objects for communication between the
client and the console-using object are provided in C<%args>:

=over

=item command

A scalar containing the name of the command to be executed. This will
be transformed into the C<cmd_C<$command>> event.

=item args

An optional arrayref containing the arguments to the command handler.

=item then

A L<Future> which will be completed when the command handler has
finished. This is not the L<Future> which the command handler is
invoked with. If the command dies or was not found then this L<Future>
will be failed with the exception.

    Future->fail($message, console =>
        ex      => $@,   # If the command threw one
        command => $command,
        args    => \%args)

Another L<Future> is created which is passed onto the command itself,
if the command returns without dying then L</then> is completed with
the L<Future> the command handler was given.

The command handler is free to return a different L<Future> to this
event handler. If it does so then it is that L<Future> which L</then>
is completed with. Anything else returned from the command handler is
ignored.

=item inform

An optional subref which the command handler may invoke to respond to
the client before execution has completed.

Although C<inform> isn't a required argument its default value is
C<sub { ... }> which will die if the command handler attempts to use
it.

=back

=cut

use namespace::clean '__execute';
sub __execute {
    my $self = shift;
    my $client_connection = shift;
    my %args = @_;
    my $then    = delete $args{then} or die 'no future';
    my $command = delete $args{command} or die 'no command';
    my $informer= delete $args{inform} || sub { ... };
    # $real_informer = sub { ...; $informer->(); ... };
    $self->_logger->debugf('Invoking command %s %s', $command, $args{args});
    my $next = $self->loop->new_future;
    try {
        my $r = $self->invoke_event("cmd_$command" => @{ $args{args} // [] },
                                    inform => $informer, then => $next);
        $next = $r if blessed $r and $r->DOES('Future');
        return $then->done($next);

    } catch {
        # TODO: See what's happened to $next
        return $then->fail("Unknown command: $command",
                console => command => $command, args => \%args)
            if $@ =~ /cannot handle cmd_\Q$command\E event/;
        chomp $@ unless ref $@;
        return $then->fail("Unhandled exception running $command: $@",
            console => ex => $@, command => $command, args => \%args);
    }
}

1;

=back

=head1 HISTORY

=over

=item MooX::Async::Console 0.103

=over

=item on_command/cmd_* interface

=item line-based TCP implementation

=back

=back

=head1 SEE ALSO

L<MooX::Async::Console::TCP>

=head1 AUTHOR

Matthew King <chohag@jtan.com>

=cut
