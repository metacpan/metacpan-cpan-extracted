use warnings;
use strict;

package Remind::Client;

=head1 NAME

Remind::Client - class for working with remind's daemon mode

=head1 SYNOPSIS

  package Remind::Client::something;

  use base 'Remind::Client';

  sub reminder {
      my ($self, %args) = @_;
      say "Got the message: $args{message}";
  }

  package main;

  my $rc = Remind::Client::something->new();
  $rc->run();

=head1 DESCRIPTION

This module provides methods for communicating with the "Server Mode" of
remind. It

=head1 METHODS

=cut

our $VERSION = '0.03';
$VERSION = eval $VERSION;

use Carp;
use File::HomeDir;
use IO::Handle;
use IPC::Open2;

use constant DEBUG => 0;

my $REMIND = 'remind';
my @REMIND_SERVER_ARGS = qw(-z0);
my @REMIND_DAILY_ARGS = qw(-g -q -a -r);
my $DEFAULT_FILENAME = defined $ENV{DOTREMINDERS} ?
    $ENV{DOTREMINDERS} : File::Spec->catfile(File::HomeDir->my_home, '.reminders');

=head2 new

Construct a new Remind::Client object. Takes the following named
parameters:

=over 4

=item filename

The filename of the reminders file to use. Defaults to
$ENV{DOTREMINDERS}, if it exists, or ~/.reminders.

=back

=cut

sub new {
    my ($class, %args) = @_;

    $args{filename} ||= $DEFAULT_FILENAME;

    return bless \%args, $class;
}

=head2 run

Start up an instance of remind in server mode, and begin to listen for
events.

=cut

sub run {
    my ($self) = @_;

    $self->_connect();

    local $SIG{HUP} = sub { $self->sigHUP(@_) };

    $self->on_connect();

    $self->_loop();
}

# connect to the server mode process, storing the pid, and child_in/out
# handles
sub _connect {
    my ($self) = @_;

    $self->{child_out} = IO::Handle->new();
    $self->{child_in} = IO::Handle->new();
    $self->{pid} = open2($self->{child_out}, $self->{child_in},
        $REMIND, @REMIND_SERVER_ARGS, $self->{filename});

    $self->_debug("Running $REMIND @REMIND_SERVER_ARGS $self->{filename}");
}

# the main event loop, parses the output from remind -z0 and fires off
# the various local handlers
sub _loop {
    my ($self) = @_;

    $self->_debug("\$self->_loop(): $self");

    while (defined(my $line = $self->{child_out}->getline())) {
        chomp $line;
        if (my ($due_time, $reminder_time, $tag) = $line =~ /^NOTE\s+reminder\s+(\S+)\s+(\S+)\s+(\S{0,48})$/) {
            my $msg;
            while(defined(my $line = $self->{child_out}->getline())) {
                if ($line =~ /^NOTE\s+endreminder$/) {
                    last;
                }
                $msg .= $line;
            }
            chomp $msg;
            $self->_debug("Got a new reminder: $msg, due at $due_time, reminded at $reminder_time, with tag $tag");
            $self->reminder(message => $msg, due_time => $due_time, reminder_time => $reminder_time, tag => $tag);
        } elsif ($line =~ /^NOTE\s+newdate$/) {
            $self->_debug("It's a new day.");
            $self->newdate();
        } elsif ($line =~ /^NOTE\s+reread$/) {
            $self->_debug("Config was reread.");
            $self->reread();
        } elsif ($line =~ /^NOTE\s+queued\s+(\d+)$/) {
            $self->_debug("Got queued count: $1");
            $self->queued(count => $1);
        } else {
            $self->_debug("Unparsable line: $line");
        }
    }
}

=head2 reminder

This handler is fired whenever a reminder is sent from remind. So, for a
timed reminder like:

  REM 01 Oct 2009 AT 10:50 +10 *5 MSG It's time%

This would be fired at 10:40, 10:45, and 10:50.

It receives the following named parameters:

=over 4

=item message

The reminder message; chomped. In the above example, it would be "It's
time".

=item due_time

The time this reminder is set for. In the above example, it would always
be '10:50am'.

=item reminder_time

The time this reminder fired. In the above example, it would be
'10:40am', '10:45am', and '10:50am'.

=item tag

The TAG from the reminder. If there is no TAG, then it defaults to '*'.

=back

The default implementation does nothing; most subclasses of
Remind::Client will want to implement this.

=cut

sub reminder { }

=head2 newdate

This is fired when the day changes over. Use it to do things like check
for new daily reminders.

This receives no parameters.

The default implementation does nothing.

=cut

sub newdate { }

=head2 reread

This is fired when the number of reminders in the queue changes because
the day has changed, or because of a REREAD command. The recommendation
is to issue a 'STATUS' command in response to this.

This receives no parameters.

The default implementation does nothing.

=cut

sub reread { }

=head2 queued

This is fired as a result of a STATUS command. It receives the following
named parameters:

=over 4

=item count

The number of reminders that are queued.

=back

The default implementation does nothing.

=cut

sub queued { }

=head2 send

Send a command to the remind server.

Takes one named parameter, C<command>. It may be one of:

=over 4

=item EXIT

Tell the remind server to exit. This will also finish the current run().

=item STATUS

Request the current number of queued reminders from the server. This
will result in a queued() event being fired.

=item REREAD

Request that the server reread the configuration. This will result in a
reread() event being fired.

=back

=cut

sub send {
    my ($self, %args) = @_;

    defined $args{command}
        or return $self->_error("Missing required argument 'command'");
    $args{command} = uc $args{command};
    $args{command} =~ /^(EXIT|STATUS|REREAD)$/
        or return $self->_error("Invalid command: $args{command}");

    $self->_debug("Sending command: $args{command}");

    $self->{child_in}->printflush("$args{command}\n");
}

=head2 on_connect

This is fired once, after $rc->run() has started up the remind server.
It is useful for checking for things like daily reminders, etc.

It receives no parameters.

The default implementation does nothing.

=cut

sub on_connect { }

=head2 sigHUP

Default SIGHUP handler. Sends a REREAD command to the server.

=cut

sub sigHUP {
    my ($self, @msg) = @_;

    $self->send(command => 'REREAD');
}

# debug messages, for development
sub _debug {
    return unless DEBUG;

    my ($self, @msg) = @_;

    print STDERR "DEBUG: ", @msg, "\n";
}

# error messages, should be shown to the user
sub _error {
    my ($self, @msg) = @_;

    carp @msg;

    return;
}

=head1 BUGS

This doesn't provide any useful support for non-timed reminders (yet).

=head1 SEE ALSO

L<tkremind/"SERVER MODE">(1), L<remind>(1)

L<Remind::Parser> for a tool to parse the calendar output.

Remind's Homepage: L<http://www.roaringpenguin.com/products/remind>

=head1 AUTHOR

Mike Kelly <pioto@pioto.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, Mike Kelly.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses at <http://www.perlfoundation.org/artistic_license_1_0>,
and <http://www.gnu.org/licenses/gpl-2.0.html>.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut

1;

# vim: set ft=perl sw=4 sts=4 et :
