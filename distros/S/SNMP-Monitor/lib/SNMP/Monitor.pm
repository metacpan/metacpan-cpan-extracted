
# -*- perl -*-
#
#
#   SNMP::Monitor - a Perl package for monitoring remote hosts via SNMP
#
#
#   Copyright (C) 1998    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#

use strict;

require Mail::Internet;
require SNMP;
require DBI;
require Sys::Syslog;


package SNMP::Monitor;


$SNMP::Monitor::VERSION = '0.1012';


sub new ($$) {
    my($proto, $config) = @_;
    my($self) = { config => $config, debug => $config->{debug} };
    bless($self, (ref($proto) || $proto));

    if ($self->{debug}) {
	Sys::Syslog::syslog('debug', "Entering debugging mode");
    }

    $self->{dbh} = DBI->connect($config->{dbi_dsn}, $config->{dbi_user},
				$config->{dbi_pass});
    if (!$self->{dbh}) {
	die "Cannot connect to database: " . $DBI::errstr;
    }

    $self->{sessions} = [];

    my($router, $interface);
    foreach $router (values(%{$config->{hosts}})) {
	my $session = SNMP::Monitor::Session->new($self, $router);
	$session->{events} = [];
	foreach $interface (@{$session->{interfaces}}) {
	    my $class;
	    foreach $class (@{$interface->{events}}) {
		$@ = '';
		eval "require $class";
		if ($@) {
		    die $@;
		}
		my $event = $class->new($session, $interface);
		push(@{$session->{events}}, $event);
	    }
	}
	if (@{$session->{events}}) {
	    push(@{$self->{sessions}}, $session);
	}
    }

    if (!@{$self->{sessions}}) {
	die "No sessions found";
    }

    $self;
}


sub Loop ($) {
    my($self) = @_;
    my $time = time;
    my($event, $session, $wait);

    while (1) {
	my $nexttime = time() + 60;

	foreach $session (@{$self->{sessions}}) {
	    my $queued = 0;
	    foreach $event (@{$session->{events}}) {
		if ($event->{count}  ==  0) {
		    $event->Queue();
		    $queued = 1;
		}
	    }
	    if ($queued) {
		$session->Query();
	    }
	    foreach $event (@{$session->{events}}) {
		if ($event->{count} == 0) {
		    $event->Process();
		    $event->{count} = $event->{init_count};
		}
		$event->{count} -= 1;
	    }
	}

	my $wait = $nexttime - time();
	if ($wait > 0) {
	    sleep $wait;
	}
    }
}


sub Configuration ($$) {
    my($class, $file) = @_;

    if (! -r $file) {
        die "Cannot read configuration file $file";
    }
    $@ = '';
    my $config = do($file);
    if ($@) {
        die "Error while reading configuration file $file: $@";
    }
    $config;
}


sub Message ($@) {
    my($self, %attr) = @_;
    if (!$attr{'to'}) {
	$attr{'to'} = $self->{'config'}->{'email'};
    }

    my $body = delete $attr{body};
    my $host = (delete $attr{mailhost})  ||  $self->{'config'}->{'mailhost'}
        ||  '127.0.0.1';
    my $head = Mail::Header->new();
    my($val, $header);
    foreach $header ('to', 'cc', 'bcc') {
	if ($attr{$header}) {
	    foreach $val (split(/,/, $attr{$header})) {
		$head->add($header, $val);
	    }
	    delete $attr{$header};
	}
    }
    while (($header, $val) = each %attr) {
	$head->add($header, $val);
    }

    my $mail = Mail::Internet->new([$body], Header => $head);
    $mail->smtpsend();
    1;
}


package SNMP::Monitor::Session;

sub new ($$$) {
    my($proto, $monitor, $attr) = @_;
    my $self = { %$attr };
    bless($self, (ref($proto) || $proto));
    $self->{config} = $monitor;
    $self->{debug} = $monitor->{debug};

    my $session = SNMP::Session->new(%$self);
    if (!$session) {
	die "Cannot create session for router " . $self->{name};
    }

    $self->{session} = $session;
    $self;
}


sub Query ($) {
    my($self) = @_;

    my $session = $self->{session};
    my @varlist;
    my $vr = $self->{vars_registered};
    for (my $i = 0;  $i < @$vr;  $i++) {
	if ($vr->[$i]->[1]) {
	    push(@varlist, $vr->[$i]->[0]);
	    $vr->[$i]->[1] = 0;
	}
    }
    my $vl = SNMP::VarList->new(@varlist);
    if ($self->{debug}) {
	Sys::Syslog::syslog('debug', "Sending query: Session = %s",
			    $session->{name});
	foreach $vr (@$vl) {
	    Sys::Syslog::syslog('debug', "Query variable: %s.%d", $vr->[0],
				$vr->[1]);
	}
    }
    $session->get($vl);
    if ($self->{debug}) {
	Sys::Syslog::syslog('debug', "Query response: Session = %s",
			    $session->{name});
	foreach $vr (@$vl) {
	    Sys::Syslog::syslog('debug', "Query variable: %s.%d => %s",
				$vr->[0], $vr->[1], $vr->[2]);
	}
    }
    $self->{'time'} = time();
    if ($session->{ErrorNum}) {
	if (!$self->{err_msg_sent}) {
	    my $time = localtime(time());
	    my $name = $session->{name};
	    my $host = $session->{DestHost};
	    my $errmsg = $session->{ErrorStr};
	    $self->{err_msg_sent} =
		$self->Message(subject => "No response from $name",
			       body => <<"MSG");

Warning: I did not get an SNMP reply from router $name ($host)
at $time. The error message is:

$errmsg

You will not receive any further messages until the next successfull
request or restart of SNMP::Monitor.

MSG
	}
    } else {
	$self->{err_msg_sent} = 0;
    }
}


sub Message ($@) {
    my($self, %attr) = @_;
    if (!$attr{'to'}  &&  $self->{email}) {
	$attr{'to'} = $self->{email};
    }
    $self->{config}->Message(%attr);
}


package SNMP::Monitor::Event;

sub new ($$$) {
    my($proto, $session, $attr) = @_;
    my $self = { %$attr };
    bless($self, (ref($proto) || $proto));
    $self->{count} = 0;
    $self->{init_count} = 1;
    $self->{session} = $session;
    $self;
}


sub Queue ($)  {
    my($self) = @_;
    my $i;
    my $vr = $self->{vars_registered};
    my $session = $self->{session};
    if (!$vr) {
	$vr = $self->{vars_registered} = [];
	if (!$session->{vars_registered}) {
	    $session->{vars_registered} = [];
	}
	my($var, $ref);
	foreach $var (@{$self->{vars}}) {
	    for ($i = 0;  $i < @{$session->{vars_registered}};  $i++) {
		$ref = $session->{vars_registered}->[$i];
		if ($var->[0] eq $ref->[0]->[0]  &&
		    $var->[1] eq $ref->[0]->[1]) {
		    # Variable already present
		    last;
		}
	    }
	    if ($i >= @$vr) {
		# New variable
		$session->{vars_registered}->[$i] = [$var, 0];
	    }
	    push(@$vr, $i);
	}
	delete $self->{vars};
    }

    for ($i = 0;  $i < @$vr;  $i++) {
	$session->{vars_registered}->[$vr->[$i]]->[1] = 1;
    }
    $session->{events_queued} = 1;
}


sub Process ($) {
    1;
}


sub Message ($@) {
    my($self, %attr) = @_;
    if (!$attr{'to'}  &&  $self->{email}) {
	$attr{'to'} = $self->{email};
    }
    $self->{session}->Message(%attr);
}


1;


=head1 NAME

SNMP::Monitor - a Perl package for monitoring remote hosts via SNMP


=head1 SYNOPSIS

    require SNMP::Monitor;

    # Read a configuration file
    my $config = SNMP::Monitor->Configuration("/etc/snmpmon/config");

    # Create a new monitor
    my $monitor = SNMP::Monitor->new($config);

    # Start monitoring (endless loop, never returns)
    $monitor->Loop();


=head1 DESCRIPTION

The SNMP::Monitor module is a package for checking and watching arbitrary
values via SNMP. Events can be triggered, Logging can be done, whatever
you want.

The package is based on the SNMP package, but it is merely created for
system administrators and not for programmers.

The following class methods are offered:


=over 8

=item Configuration($file)

(Class method) Read a monitor configuration from C<$file>. The module
I<SNMP::Monitor::Install> is available for creating such files.
See L<SNMP::Monitor::Install>. No error indicators, the method dies
in case of trouble.


=item new($config)

(Class method) This is the monitor constructor. Given a monitor
configuration C<$config>, as returned by the I<Configuration> method
(see above), returns a new monitor. Internally the monitor is a
set of sessions (instances of SNMP::Monitor::Session) and events
(instances of SNMP::Monitor::Event). Currently there are two
available event classes: One for watching an interface status and
one for logging interface loads into a database. See
L<"EVENT IMPLEMENTATION"> below.


=item Message(\%attr)

(Instance method) Called for sending an E-Mail via the I<Mail::Internet>
module. See L<Mail::Internet(3)>. The following keys are supported in
the hash ref C<\%attr>:

=over 12

=item I<body>

The message body.

=item I<mailhost>

A host being used as SMTP server. By default the mail host from the
config file or localhost are used.

=item I<to>

=item I<cc>

=item I<bcc>

Mail recipients, or recipient lists (comma separated values).

=back

All other keys are used as mail headers, in particular the attributes
I<subject> and I<from> should be present.


=item Loop()

(Instance method) The monitor enters an endless loop. Every 60 seconds
it checks its event lists and requests SNMP values, if desired. (You
cannot rely on these 60 seconds, though, because the SNMP package doesn't
support asynchronous SNMP requests.)

=back


=head1 EVENT IMPLEMENTATION

Currently only two event classes are available: The
I<SNMP::Monitor::Event::IfStatus> class for watching an interface
status and the I<SNMP::Monitor::Event::IfLoad> class for logging
interface utilization into a database.

However, it is fairly simple two add arbitrary new event classes:
All you need is a constructor method I<new> for setting up an
SNMP variable list and a method I<Process> for processing these
lists when the monitor requested it for you. Let's see the
I<SNMP::Monitor::Event::IfStatus> class for an example:

    sub new ($$$) {
        my($proto, $session, $attr) = @_;
        my $self = $proto->SUPER::new($session, $attr);

        my $table = "interfaces.ifTable.ifEntry";
        my $v = "SNMP::Varbind";
        my $num = $self->{num};
        $self->{vars} = [ $v->new(["$table.ifDescr", $num]),
		          $v->new(["$table.ifAdminStatus", $num]),
		          $v->new(["$table.ifOperStatus", $num])];
        $self;
    }

The method starts by calling its super classes constructor,
SNMP::Monitor::Event::new. Once that is done, it creates an attribute
C<$self-E<gt>{'vars'}>, an array ref of SNMP variables that the monitor
should fill in. It might additionally initialize the attribute
C<$self-E<gt>{'init_count'}>: This attribute defaults to 1, telling
the monitor, that it should request variables for this event every
minute. For example, the I<IfLoad> module is using a value of 5,
because logging every 5 minutes seems to me to be sufficient.

The second method to overwrite is the I<Process> method. This is
called whenever the monitor has fetched SNMP variables for the event.
Here's the I<Process> method of the I<IfStatus> class:

  sub Process ($) {
    my($self) = @_;
    my $session = $self->{session};
    my $vr_session = $session->{vars_registered};
    my $vr_self = $self->{vars_registered};

    # The following list corresponds to the list in the 'new' method.
    # This is important when calculation the index $i in $vr_self->[$i].
    my $ifDescr = $vr_session->[$vr_self->[0]]->[0]->[2];
    my $ifAdminStatus = $vr_session->[$vr_self->[1]]->[0]->[2];
    my $ifOperStatus = $vr_session->[$vr_self->[2]]->[0]->[2];
    my $num = $self->{num};

    # Now do anything with the values; in case of the IfStatus
    # this means sending a mail whenever the status has changed
    ...

    # Note the current value for the next time we are called
    $self->{ifAdminStatus} = $ifAdminStatus;
    $self->{ifOperStatus} = $ifOperStatus;
  }


=head1 AUTHOR AND COPYRIGHT

This module is Copyright (C) 1998 by

    Jochen Wiedmann
    Am Eisteich 9
    72555 Metzingen
    Germany

    Phone: +49 7123 14887
    Email: joe@ispsoft.de

All rights reserved.

You may distribute this module under the terms of either the GNU General
Public License or the Artistic License, as specified in the Perl README file.


=head1 SEE ALSO

L<SNMP(3)>, L<snmpmon(1)>, L<SNMP::Monitor::Install(3)>


=cut
