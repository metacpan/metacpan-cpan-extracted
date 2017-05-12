#
#   POE::Component::Child - Child manager
#   Copyright (C) 2001-2005 Erick Calder
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

package POE::Component::Child;

# --- external modules --------------------------------------------------------

use warnings;
use strict;
use Carp;
use Cwd;

use POE 0.29 qw(Wheel::Run Filter::Line Driver::SysRW);

# --- module variables --------------------------------------------------------

use vars qw($VERSION $PKG $AUTOLOAD);
$VERSION = substr q$Revision: 1.39 $, 10;
$PKG = __PACKAGE__;

# --- module interface --------------------------------------------------------

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = bless({}, $class);

	my %args = @_;
	$args{alias} ||= "main";
	$args{debug} ||= 0;
	$args{events}{$_} ||= $_
		for qw/stdout stderr error done died/;
	$self->{$PKG} = \%args;

	# events we catch from the session
	my @sh = qw/
        _start _stop
        stdin stdout stderr error close
        sig_child got_run
        /;

	POE::Session->create(
		object_states => [ $self => \@sh ]
		);

	return $self;
	}

sub run {
	my $self = shift;
	POE::Kernel->call($self->{$PKG}{session}, got_run => \@_);
	}

sub write {
	my $self = shift;
	my $wheel = $self->wheel();
    if (defined $wheel) {
	    $self->debug(qq/write(): "/ . join(" ", @_) . qq/"/);
	    $wheel->put(@_);
        }
    else {
        $self->debug(sprintf(
            q/wheel undefined, refusing to write(): "%s"/, join(" ", @_)
            ));
        }
	}

sub quit {
	my $self = shift;
	my $quit = shift || $self->{$PKG}{writemap}{quit};
	my $id = $self->wheelid();

	$self->{$PKG}{wheels}{$id}{quit} = 1;
	$self->write($quit) if $quit;
    $self->stdin_close();
	}

sub kill {
	my $self = shift;
    local %_ = @_;
    my $sig = $_{HARD} ? 9 : $_{SIG} || 'TERM';
    my $nod = $_{NODIE} || 0;

	my $id = $self->wheelid();
	$self->{$PKG}{wheels}{$id}{quit} = $nod;

	my $pid = $self->wheel()->PID;
	CORE::kill $sig, $pid;
	$self->debug("kill(): $pid");
	}

sub shutdown {
	my $self = shift;
	POE::Kernel->alias_remove("${PKG}::$self->{$PKG}{session}");
	}

sub attr {
	my ($self, $key, $val) = @_;

	my @keys = split m|/|, $key;
	$key = pop @keys;

	my $ref = \$self->{$PKG};
	$ref = \$ref->{$_} for @keys;

	$ref->{$key} = $val if $val;
	return $ref->{$key};
	}

# --- session handlers --------------------------------------------------------

sub _start {
	my ($kernel, $session, $self) = @_[KERNEL, SESSION, OBJECT];
	$self->{$PKG}{session} = $session->ID;
	$self->debug("session-id: $self->{$PKG}{session}");

	# install death handler
    $kernel->sig(CHLD => 'sig_child');

	# to make sure our session sticks around between
	# wheel invocations we set an alias (unique per sesion)

	$kernel->alias_set("${PKG}::$self->{$PKG}{session}");
	}

sub _stop {
	my ($self, $session) = @_[OBJECT, SESSION];

	#	clean remaining wheels

	delete $self->{$PKG}{wheels}{current};
	for my $id (keys %{ $self->{$PKG}{wheels} }) {
		delete $self->{$PKG}{wheels}{$id};
		}

	#	and wipe children

	CORE::kill 9, $_ for keys %{ $self->{$PKG}{pids} };

	# for enlightenment

	$self->debug("_stop=" . $session->ID);
	}

#	not currently handled by the session.  not sure how
#	to propagate

sub _default {
	my $self = $_[OBJECT];
	$self->debug(qq/_default: "$_[ARG0]", args: @{$_[ARG1]}/);
	}

sub got_run {
	my ($kernel, $session, $self, $cmd) = @_[KERNEL, SESSION, OBJECT, ARG0];

	# init stuff

	my $conduit = $self->{$PKG}{conduit};
	$self->{$PKG}{StdioFilter}
		||= POE::Filter::Line->new(OutputLiteral => "\n");

    my $cwd = cwd();
    chdir $self->{$PKG}{chdir} if $self->{$PKG}{chdir};

	my $wheel = POE::Wheel::Run->new(
		Program		=> $cmd,
		StdioFilter	=> $self->{$PKG}{StdioFilter},
		StdoutEvent	=> "stdout",
		$conduit ? (Conduit => $conduit) : (StderrEvent => "stderr"),
		ErrorEvent	=> "error",
        CloseEvent  => "close",
		);

    chdir $cwd if $self->{$PKG}{chdir};

	my $id = $wheel->ID;
	$self->debug(qq/run(): "@$cmd", wheel=$id, pid=/ . $wheel->PID);

	$self->{$PKG}{pids}{$wheel->PID} = $id;
	$self->{$PKG}{wheels}{$id}{cmd} = $cmd;
	$self->{$PKG}{wheels}{$id}{ref} = $wheel;
	$self->{$PKG}{wheels}{$id}{quit} = 0;
	$self->{$PKG}{wheels}{$id}{stdin_close} = 0;
	$self->wheelid($id);
	}

sub callback {
	my ($self, $event, $args) = @_;
	my $call = $self->{$PKG}{events}{$event};
	$self->debug("callback(): $event=$call", 2);
	ref($call) eq "CODE"
		? $call->($self, $args)
		: POE::Kernel->post($self->{$PKG}{alias}, $call, $self, $args)
		;
	}

sub stdio {
	my ($kernel, $self, $event) = @_[KERNEL, OBJECT, STATE];
	return unless $_[ARG0];

	$self->callback($event, { out => $_[ARG0], wheel => $_[ARG1] });
	$self->debug(qq/$event(): "$_[ARG0]"/, 2);
	}

sub stdin {
    my ($kernel, $self, $event) = @_[KERNEL, OBJECT, STATE];
    my $id = $_[ARG0] || return;
    $self->debug("stdin: $id flushed", 2);
    $self->pending_close();
    }

*stdout = *stderr = *stdio;

sub sig_child {
    my ($kernel, $self, $pid, $rc) = @_[KERNEL, OBJECT, ARG1, ARG2];

	my $id = $self->{$PKG}{pids}{$pid} || "";

    # child death signals are issued by the OS and sent to all
    # sessions; we want to handle only our own children

	return unless $id;

    $kernel->sig_handled() if $POE::VERSION >= 0.20;

    my %args = (self => $self, id => $id, rc => $rc);
    return done(%args), 0 if $self->{$PKG}{CLOSED}{$id};
    $self->{$PKG}{SIGCHLD}{$id} = \%args;

    my $sid = $_[SESSION]->ID;
	$self->debug("sig_child(): session=$sid, wheel=$id, pid=$pid, rc=$rc");
    return 0;
    }

#   the child has closed its output pipes

sub close {
    my ($self, $id) = @_[OBJECT, ARG0];
    my $sigchld = $self->{$PKG}{SIGCHLD}{$id};

    return done(%$sigchld) if $sigchld;

    $self->{$PKG}{CLOSED}{$id} = 1;
    $self->debug("close()");
    }

sub done {
    %_ = @_; my ($self, $id, $rc) = @_{qw/self id rc/};

	# clean up

	delete $self->{$PKG}{wheels}{$id};
	delete $self->{$PKG}{pids}{$id};

	# all expiring children should issue a "done" except when
	# the return code is non-zero which indicates a failure
	# if the caller asked we quit, fire a "done" regardless
	# of the child's return code value (we might have hard killed)

	my $event = ($self->{$PKG}{wheels}{$id}{quit} || $rc == 0)
		? "done" : "died"
		;
	$self->callback($event, { wheel => $id, rc => $rc });
	}

sub error {
	my ($kernel, $self, $event) = @_[KERNEL, OBJECT, STATE];
	my $args = {
		syscall	=> $_[ARG0],
		err		=> $_[ARG1],
		error	=> $_[ARG2],
		wheel	=> $_[ARG3],
		fh		=> $_[ARG4],
		};

	return if $args->{syscall} eq "read" && $args->{err} == 0;

	$self->callback($event, $args);
	$self->debug("$event() [$args->{err}]: $args->{error}");
	}

# --- internal methods --------------------------------------------------------

sub wheelid {
	my $self = shift;
	$self->{$PKG}{wheels}{current} = shift if @_;
	$self->{$PKG}{wheels}{current};
	}

sub wheel {
	my $self = shift;
	my $id = shift || $self->{$PKG}{wheels}{current};
	$self->{$PKG}{wheels}{$id}{ref};
	}

sub stdin_close {
    my ($self, $id) = @_;
    $id = $self->wheelid() unless defined $id;
    $self->debug("stdin_close: $id");
    $self->{$PKG}{wheels}{$id}{stdin_close} = 1;
    $self->pending_close();
    }

sub pending_close {
    my $self = shift;
   
    for my $id (keys %{$self->{$PKG}{wheels}}) {
        my $wheel = $self->{$PKG}{wheels}{$id};
        next unless ref $wheel && ref $wheel->{ref};
        next if $wheel->{ref}->get_driver_out_octets();
        next unless $wheel->{stdin_close};

        $self->debug("pending_close: $id should be closed");
        $wheel->{ref}->shutdown_stdin();
        }
    }

sub debug {
	my $self = shift;
	my $arg = shift || $_;
	my $debug = shift || 1;
	my $hdr = shift || $PKG;

	return unless $self->{$PKG}{debug} >= $debug;

	local ($\, $,) = ("\n", " ");
	print STDERR ">", $hdr, "-", $arg;
	}

sub AUTOLOAD {
	my $self = shift;
	my $attr = $AUTOLOAD;
	$attr =~ s/.*:://;
	return if $attr eq 'DESTROY';   

	my $cmd = $self->{$PKG}{writemap}{$attr};
	$self->write($cmd), return if $cmd;

	my $super = "SUPER::$attr";
	$self->$super(@_);
	}

1; # yipiness

__END__

=head1 NAME

POE::Component::Child - Child management component

=head1 SYNOPSIS

 use POE qw(Component::Child);

 $p = POE::Component::Child->new();
 $p->run("ls", "-alF", "/tmp");

 POE::Kernel->run();

=head1 DESCRIPTION

This POE component serves as a wrapper for POE::Wheel::Run, obviating the need to create a session to receive the events it dishes out.

=head1 METHODS

The module provides an object-oriented interface as follows: 

=head2 new [hash[-ref]]

Used to initialise the system and create a component instance.  The function may be passed either a hash or a reference to a hash.  The keys below are meaningful to the component, all others are passed to the provided callbacks.

=item alias

Indicates the name of a session to which module callbacks will be posted.  Default: C<main>.

=item events

This hash reference contains mappings for the events the component will generate.  Callers can set these values to either event handler names (strings) or to callbacks (code references).  If names are given, the events are thrown at the I<alias> specified; when a code reference is given, it is called directly.  Allowable keys are listed below under section "Event Callbacks".

=over

- I<exempli gratia> -

=back

	$p = POE::Component::Child->new(
		alias => "my_session",
		events => { stdout => "my_out", stderr => \&my_err }
		);

In the above example, any output produced by children on I<stdout> generates an event I<my_out> for the I<my_session> session, whilst output on I<stderr> causes a call to I<my_err()>.

=item writemap

This item may be set to a hash reference containing a mapping of method names to strings that will be written to the client.

- I<exempli gratia> -

	writemap => { quit => "bye", louder => "++" }

In the above example a caller can issue a call to I<$self->quit()>, in which case the string C<bye> will be written to the client, or I<$self->louder()> to have the client receive the string C<++>.

=item conduit

If left unspecified, POE::Wheel::Run assumes "pipe".  Alternatively "pty" may be provided in which case no I<stderr> events will be fired.

=item debug

Setting this parameter to a true value generates debugging output (useful mostly to hacks).

=head2 run {array}

This method requires an array indicating the command (and optional parameters) to run.  The command and its parameters may also be passed as a single string.  The method returns the I<id> of the wheel which is needed when running several commands simultasneously.

Before calling this function, the caller may set stdio filter to a value of his choice.  The example below shows the default used.

I<$p-E<gt>{StdioFilter} = POE::Filter::Line-E<gt>new(OutputLiteral =E<gt> '\n');>

=head2 write {array}

This method is used to send input to the child.  It can accept an array and will be passed through as such to the child.

=head2 quit [command]

This method requests that the currently selected wheel quit.  An optional I<command> string may be passed which is sent to the child - this is useful for graceful shutdown of interactive children e.g. the ftp command understands "bye" to quit.

If no I<command> is specified, the system will use whatever string was passed as the I<quit> item in the I<writemap> hash argument to I<new()>.  If this too was left unspecified, a kill is issued.  Please note if the child is instructed to quit, it will not generate a I<died> event, but a I<done> instead (even when hard killed).

Please note that quitting all children will not shut the component down - for that use the I<shutdown> method.

=head2 kill [HARD/SIG = TERM, NODIE = 0]

Instructs the component to send the child a signal.  By default the I<TERM> signal is sent but the I<SIG> named parameter allows the caller to specify anything else.  If I<HARD> => 1 is specified, a hard kill (-9) is done and any specific signal passed is ignored.

Note that by default killing the child will generate a I<died> event (not a I<done>) unless the named parameter I<NODIE> is passed a true value.

Additionally, note that kills are done immediately, not scheduled.

=over

- I<exempli gratia> -

=back

	$obj->kill();                       # a TERM signal is sent
    $obj->kill(HARD => 1);              # a -9 gets sent
    $obj->kill(SIG => 'INT');           # obvious
    $obj->kill(HARD => 1, NODIE => 1);  # hard kill w/o a C<died> event

=head2 shutdown

This method causes the component to kill all children and shut down.

=head2 attr <key> [val]

Gets or sets the value of a certain key.  Values inside of hashes may be specified by separating the keys with slashes e.g. $self->attr("events/quit", "bye"); whould store C<bye> in {events}{quit} inside of the object.

=head2 wheelid

Used to set the current wheel for other methods to work with.  Please note that I<-E<gt>write()>, I<-E<gt>quit()> and I<-E<gt>kill()> will work on the wheel most recently created.  I you wish to work with a previously created wheel, set it with this method.

=head2 wheel [id]

Returns a reference to the current wheel.  If an id is provided then that wheel is returned.

=head1 EVENTS / CALLBACKS

Events are are thrown at the session indicated as I<alias> and may be specified using the I<callbacks> argument to the I<new()> method.  If no such preference is indicated, the default event names listed below are used.  Whenever callbacks are specified, they are called directly instead of generating an event.

Event handlers are passed two arguments: ARG0 which is a reference to the component instance being used (i.e. I<$self>), and ARG1, a hash reference containing the wheel id being used (as I<wheel>) + values specific to the event.  Callbacks are passed the same arguments but as @_[0,1] instead.

=head2 stdout

This event is fired upon any generation of output from the client.  The output produced is provided in C<out>, e.g.:

I<$_[ARG1]-E<gt>{out}>

=head2 stderr

Works exactly as with I<stdout> but for the error channel.

=head2 done

Fired upon termination of the child, including such cases as when the child is asked to quit or when it ends naturally (as with non-interactive children).  Please note that the event is fired when _both_ the OS death signal has been received _and_ the child has closed its output pipes (this also holds true for the I<died> event described below).

=head2 died

Fired upon abnormal ending of a child.  This event is generated only for interactive children who terminate without having been asked to.  Inclusion of the C<died> key in the C<callbacks> hash passed to I<-E<gt>new()> qualifies a process for receiving this event and distinguishes it as interactive.  This event is mutually exclusive with C<done>.

=head2 error

This event is fired upon generation of any error by the child.  Arguments passed include: I<syscall>, I<err> (the numeric value of the error), I<error> (a textual description), and I<fh> (the file handle involved).

=head1 AUTHOR

Erick Calder <ecalder@cpan.org>

=head1 ACKNOWLEDGEMENTS

1e6 thx pushed to Rocco Caputo for suggesting this needed putting together, for giving me the privilege to do it, and for all the late night help.

=head1 AVAILABILITY

This module may be found on the CPAN.  Additionally, both the module and its RPM package are available from:

F<http://perl.arix.com>

=head1 SUPPORT

Thank you notes, expressions of aggravation and suggestions may be mailed directly to the author :)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2002-2003 Erick Calder.

This product is free and distributed under the Gnu Public License (GPL).  A copy of this license was included in this distribution in a file called LICENSE.  If for some reason, this file was not included, please see F<http://www.gnu.org/licenses/> to obtain a copy of this license.

$Id: Child.pm,v 1.39 2005/12/30 04:14:38 ekkis Exp $

=cut
