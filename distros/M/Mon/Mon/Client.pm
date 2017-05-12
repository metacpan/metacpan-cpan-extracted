=head1 NAME

Mon::Client - Methods for interaction with Mon client

=head1 SYNOPSIS

    use Mon::Client;

=head1 DESCRIPTION

    Mon::Client is used to interact with "mon" clients. It supports
    a protocol-independent API for retrieving the status of the mon
    server, and performing certain operations, such as disableing hosts
    and service checks.

=head1 METHODS

=over 4

=item new

Creates a new object. A hash can be supplied which sets the
default values. An example which contains all of the variables
that you can initialize:

    $c = new Mon::Client (
    	host => "monhost",
	port => 2583,
	username => "foo",
	password => "bar",
    );

=item password (pw)

If I<pw> is provided, sets the password. Otherwise, returns the
currently set password.

=item host (host)

If I<host> is provided, sets the mon host. Otherwise, returns the
currently set mon host.


=item port (portnum)

If I<portnum> is provided, sets the mon port number. Otherwise, returns the
currently set port number.


=item username (user)

If I<user> is provided, sets the user login. Otherwise, returns the
currently set user login.

=item prot

If I<protocol> is provided, sets the protocol, specified by a string
which is of the form "1.2.3", where "1" is the major revision, "2" is
the minor revision, and "3" is the sub-minor revision.
If I<protocol> is not provided, the currently set protocol is returned.


=item protid ([protocol])

Returns true if client and server protocol match, false otherwise.
Implicitly called by B<connect>. If protocol is specified as an integer,
supplies that protocol version to the server for verification.


=item version

Returns the protocol version of the remote server.

=item error

Returns the error string from set by the last method, or undef if
there was no error.

=item connected

Returns 0 (not connected) or 1 (connected).

=item connect (%args)

Connects to the server. If B<host> and B<port> have not been set,
uses the defaults. Returns I<undef> on error.  If $args{"skip_protid"}
is true, skip protocol identification upon connect.

=item disconnect

Disconnects from the server. Return I<undef> on error.

=item login ( %hash )

B<%hash> is optional, but if specified, should contain two keys,
B<username> and B<password>.

Performs the "login" command to authenticate the user to the server.
Uses B<username> and B<password> if specified, otherwise uses
the username and password previously set by those methods, respectively.


=item checkauth ( command )

Checks to see if the specified command, as executed by the current user,
is authorized by the server, without actually executing the command.
Returns 1 (command is authorized) or 0 (command is not authorized).


=item disable_watch ( watch )

Disables B<watch>.

=item disable_service ( watch, service )

Disables a service, as specified by B<watch> and B<service>.


=item disable_host ( host )

Disables B<host>.

=item enable_watch ( watch )

Enables B<watch>.

=item enable_service ( watch, service )

Enables a service as specified by B<watch> and B<service>.

=item enable_host ( host )

Enables B<host>.

=item set ( group, service, var, val )

Sets B<var> in B<group,service> to B<val>. Returns
undef on error.

=item get ( group, service, var )

Gets variable B<var> in B<group,service> and returns it,
or undef on error.

=item quit

Logs out of the server. This method should be followed
by a call to the B<disconnect> method.

=item list_descriptions

Returns a hash of service descriptions, indexed by watch
and service. For example:

    %desc = $mon->list_descriptions;
    print "$desc{'watchname'}->{'servicename'}\n";

=item list_deps

Lists dependency expressions and their components for all
services. If there is no dependency for a particular service,
then the value will be "NONE".

    %deps = $mon->list_deps;
    foreach $watch (keys %deps) {
    	foreach $service (keys %{$deps{$watch}}) {
	    my $sref = \%{$deps{$watch}->{$service}};
	    print "expr ($watch,$service) = $sref->{expression}\n";
	    print "components ($watch,$service) = @{$sref->{components}}\n";
	}
    }

=item list_group ( hostgroup )

Lists members of B<hostgroup>. Returns an array of each
member.

=item list_watch

Returns an array of all the defined watch groups and services.

    foreach $w ($mon->list_watch) {
    	print "group=$w->[0] service=$w->[1]\n";
    }

=item list_opstatus ( [group1, service1], ... )

Returns a hash of per-service operational statuses, as indexed by watch
and service. The list of anonymous arrays is optional, and if is not
provided then the status of all groups and services will be queried.

    %s = $mon->list_opstatus;
    foreach $watch (keys %s) {
    	foreach $service (keys %{$s{$watch}}) {
	    foreach $var (keys %{$s{$watch}{$service}}) {
	    	print "$watch $service $var=$s{$watch}{$service}{$var}\n";
	    }
	}
    }

=item list_failures

Returns a hash in the same manner as B<list_opstatus>, but only
the services which are in a failure state.

=item list_successes

Returns a hash in the same manner as B<list_opstatus>, but only
the services which are in a success state.

=item list_disabled

Returns a hash of disabled watches, services, and hosts.

    %d = $mon->list_disabled;

    foreach $group (keys %{$d{"hosts"}}) {
    	foreach $host (keys %{$d{"hosts"}{$group}}) {
	    print "host $group/$host disabled\n";
	}
    }

    foreach $watch (keys %{$d{"services"}}) {
    	foreach $service (keys %{$d{"services"}{$watch}}) {
	    print "service $watch/$service disabled\n";
	}
    }

    for (keys %{$d{"watches"}}) {
    	print "watch $_ disabled\n";
    }

=item list_alerthist

Returns an array of hash references containing the alert history.

    @a = $mon->list_alerthist;

    for (@a) {
    	print join (" ",
	    $_->{"type"},
	    $_->{"watch"},
	    $_->{"service"},
	    $_->{"time"},
	    $_->{"alert"},
	    $_->{"args"},
	    $_->{"summary"},
	    "\n",
	);
    }

=item list_dtlog

Returns an array of hash references containing the downtime log.

@a = $mon->list_dtlog

     for (@a) {
       print join (" ",
           $_->{"timeup"},
           $_->{"group"},
           $_->{"service"},
           $_->{"failtime"},
           $_->{"downtime"},
           $_->{"interval"},
           $_->{"summary"},
           "\n",
       );
     }

=item list_failurehist

Returns an array of hash references containing the failure history.

    @f = $mon->list_failurehist;

    for (@f) {
    	print join (" ",
	    $_->{"watch"},
	    $_->{"service"},
	    $_->{"time"},
	    $_->{"summary"},
	    "\n",
	);
    }

=item list_pids

Returns an array of hash references containing the list of process IDs
of currently active monitors run by the server.

    @p = $mon->list_pids;

    $server = shift @p;

    for (@p) {
    	print join (" ",
	    $_->{"watch"},
	    $_->{"service"},
	    $_->{"pid"},
	    "\n",
	);
    }

=item list_state

Lists the state of the scheduler. Returns a two-element array. The 
first element of the array is 0 if the scheduler is stopped, and 1
if the scheduler is currently running. The second element of the array
returned is the string "scheduler running" if the scheduler is 
currently running, and if the scheduler is stopped, the second
element is the time(2) that the scheduler was stopped.

    @s = $mon->list_state;

    if ($s[0] == 0) {
    	print "scheduler stopped since " . localtime ($s[1]) . "\n";
    }

=item start

Starts the scheduler.

=item stop

Stops the scheduler.

=item reset

Resets the server.

=item reload ( what )

Causes the server to reload its configuration. B<what> is an optional
argument, and currently the only supported option is B<auth>, which
reloads the authorization file.

=item term

Terminates the server.

=item set_maxkeep

Sets the maximum number of history entries to store in memory.

=item get_maxkeep

Returns the maximum number of history entries to store in memory.

=item test ( test, group, service [, exitval, period])

Schedules a service test to run immediately, or tests an alert for a
given period. B<test> must be B<monitor>, B<alert>, B<startupalert>, or
B<upalert>. To test alerts, the B<exitval> and B<period> must be supplied.
Periods are identified by their label in the mon config file. If there
are no period tags, then the actual period string must be used, exactly
as it is listed in the config file.

=item test_config

Tests the syntax of the configuration file. Returns a two-element 
array. The first element of the array is 0 if the syntax of the
config file is invalid, and 1 if the syntax of the config file
is OK. The second element of the array returned is the failure 
message, if the config file has invalid syntax, and the result code
if the config file syntax is OK. This function returns undef if it
cannot get a connection or a response from the mon server.

Config file checking stops as soon as an error is found, so
you will need to run this command more than once if you have multiple
errors in your config file in order to find them all.

    @s = $mon->test_config;

    if ($s[0] == 0) {
        print "error in config file:\n" . $s[1] . "\n";
    }


=item ack ( group, service, text )

When B<group/service> is in a failure state,
acknowledges this with B<text>, and disables all further
alerts during this failure period.

=item loadstate ( state )

Loads B<state>.

=item savestate ( state )

Saves B<state>.

=item servertime

Returns the time on the server using the same output as the
time(2) system call.

=item send_trap ( %vars )

Sends a trap to a remote mon server. Here is an example:

    $mon->send_trap (
    	group		=> "remote-group",
	service		=> "remote-service",
	retval		=> 1,
	opstatus	=> "operational status",
	summary		=> "summary line",
	detail		=> "multi-line detailed information",
    );

I<retval> must be a nonnegative integer.

I<opstatus> must be one of I<fail>, I<ok>, I<coldstart>, I<warmstart>,
I<linkdown>, I<unknown>, I<timeout>,  I<untested>.

Returns I<undef> on error.

=back

=cut
#
# Perl module for interacting with a mon server
#
# $Id: Client.pm 1.4 Thu, 11 Jan 2001 08:42:17 -0800 trockij $
#
# Copyright (C) 1998-2000 Jim Trocki
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#

package Mon::Client;
require Exporter;
require 5.004;
use IO::File;
use Socket;
use Text::ParseWords;

@ISA = qw(Exporter);
@EXPORT_OK = qw(%OPSTAT $VERSION);

$VERSION = "0.11";

my ($STAT_FAIL, $STAT_OK, $STAT_COLDSTART, $STAT_WARMSTART, $STAT_LINKDOWN,
$STAT_UNKNOWN, $STAT_TIMEOUT, $STAT_UNTESTED, $STAT_DEPEND, $STAT_WARN) = (0..9);

my ($TRAP_COLDSTART, $TRAP_WARMSTART, $TRAP_LINKDOWN, $TRAP_LINKUP,
    $TRAP_AUTHFAIL, $TRAP_EGPNEIGHBORLOSS, $TRAP_ENTERPRISE, $TRAP_HEARTBEAT) = (0..7);
	
%OPSTAT = ("fail" => $STAT_FAIL, "ok" => $STAT_OK, "coldstart" =>
   $STAT_COLDSTART, "warmstart" => $STAT_WARMSTART, "linkdown" =>
   $STAT_LINKDOWN, "unknown" => $STAT_UNKNOWN, "timeout" => $STAT_TIMEOUT,
   "untested" => $STAT_UNTESTED, "dependency" => $STAT_DEPEND);

my %TRAPS = ( "coldstart" => $TRAP_COLDSTART, "warmstart" =>
   $TRAP_WARMSTART, "linkdown" => $TRAP_LINKDOWN, "linkup" => $TRAP_LINKUP,
   "authfail" => $TRAP_AUTHFAIL, "egpneighborloss" => $TRAP_EGPNEIGHBORLOSS,
   "enterprise" => $TRAP_ENTERPRISE, "heartbeat" => $TRAP_HEARTBEAT );



sub _sock_write;
sub _sock_readline;
sub _do_cmd;
sub _list_opstatus;
sub _start_stop;
sub _un_esc_str;
sub _esc_str;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    my %vars = @_;

    if ($ENV{"MONHOST"}) {
	$self->{"HOST"} = $ENV{"MONHOST"};
    } else {
	$self->{"HOST"} = undef;
    }

    $self->{"CONNECTED"} = undef;
    $self->{"HANDLE"} = new IO::File;

    $self->{"PORT"} = getservbyname ("mon", "tcp") || 2583;
    $self->{"PROT"} = 0x2611;
    $self->{"TRAP_PRO_VERSION"} = "0.3807";
    $self->{"PASSWORD"} = undef;
    $self->{"USERNAME"} = undef;
    $self->{"DESCRIPTIONS"} = undef;
    $self->{"GROUPS"} = undef;
    $self->{"ERROR"} = undef;
    $self->{"VERSION"} = undef;

    if ($ENV{"USER"} ne "") {
    	$self->{"USERNAME"} = $ENV{"USER"};
    } else {
    	$self->{"USERNAME"} = (getpwuid ($<))[0];
    }

    $self->{"OPSTATUS"} = undef;
    $self->{"DISABLED"} = undef;

    foreach my $k (keys %vars) {
	if ($k eq "host" && $vars{$k} ne "") {
	    $self->{"HOST"} = $vars{$k};
	} elsif ($k eq "port" && $vars{$k} ne "") {
	    $self->{"PORT"} = $vars{$k};
	} elsif ($k eq "username") {
	    $self->{"USERNAME"} = $vars{$k};
	} elsif ($k eq "password") {
	    $self->{"PASSWORD"} = $vars{$k};
	}
    }

    bless ($self, $class);
    return $self;
}

sub password {
    my $self = shift;
    if (@_) { $self->{"PASSWORD"} = shift }
    return $self->{"PASSWORD"};
}

sub host {
    my $self = shift;
    if (@_) { $self->{"HOST"} = shift }
    return $self->{"HOST"};
}

sub port {
    my $self = shift;
    if (@_) { $self->{"PORT"} = shift }
    return $self->{"PORT"};
}

sub username {
    my $self = shift;
    if (@_) { $self->{"USERNAME"} = shift }
    return $self->{"USERNAME"};
}


sub prot {
    my $self = shift;

    undef $self->{"ERROR"};

    if (@_) {
	if ($_[0] =~ /^\d+\.\d+\.\d+$/) {
	    $self->{"PROT"} = shift;
	} else {
	    $self->{"ERROR"} = "invalid protocol version";
	    return undef;
	}
    }
    return $self->{"PROT"};
}


sub DESTROY {
    my $self = shift;

    if ($self->{"CONNECTED"}) { $self->disconnect; }
}

sub error {
    my $self = shift;

    return $self->{"ERROR"};
}

sub connected {
    my $self = shift;

    return $self->{"CONNECTED"};
}


sub connect {
    my $self = shift;
    my %args = @_;

    my ($iaddr, $paddr, $proto);

    undef $self->{"ERROR"};

    if ($self->{"HOST"} eq "") {
    	$self->{"ERROR"} = "no host defined";
	return undef;
    }

    if (!defined ($iaddr = inet_aton ($self->{"HOST"}))) {
	$self->{"ERROR"} = "could not resolve host";
    	return undef;
    }

    if (!defined ($paddr = sockaddr_in ($self->{"PORT"}, $iaddr))) {
	$self->{"ERROR"} = "could not generate sockaddr";
    	return undef;
    }

    if (!defined ($proto = getprotobyname ('tcp'))) {
	$self->{"ERROR"} = "could not getprotobyname for tcp";
    	return undef;
    }

    if (!defined socket ($self->{"HANDLE"}, PF_INET, SOCK_STREAM, $proto)) {
	$self->{"ERROR"} = "socket failed, $!";
    	return undef;
    }

    if (!defined connect ($self->{"HANDLE"}, $paddr)) {
	$self->{"ERROR"} = "connect failed, $!";
    	return undef;
    }

    $self->{"CONNECTED"} = 1;

    if (!$args{"skip_protid"})
    {
    	if (!$self->protid)
	{
	    $self->{"ERROR"} = "connect failed, protocol mismatch";
	    close ($self->{"HANDLE"});
	    return undef;
	}
    }

    1;
}


sub protid {
    my $self = shift;
    my $p = shift;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    if (!defined $p) {
    	$p = int ($self->{"PROT"});
    }

    my ($r, $l) = _do_cmd ($self->{"HANDLE"}, "protid $p");

    if (!defined $r) {
	$self->{"ERROR"} = "error ($l)";
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    1;
}

sub disconnect {
    my $self = shift;

    undef $self->{"ERROR"};

    if (!defined close ($self->{"HANDLE"})) {
	$self->{"ERROR"} = "could not close: $!";
    	return undef;
    }

    $self->{"CONNECTED"} = 0;

    return 1;
}


sub login {
    my $self = shift;
    my %l = @_;

    undef $self->{"ERROR"};

    $self->{"USERNAME"} = $l{"username"} if (defined $l{"username"});
    $self->{"PASSWORD"} = $l{"password"} if (defined $l{"password"});

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    if (!defined $self->{"USERNAME"} || $self->{"USERNAME"} eq "") {
    	$self->{"ERROR"} = "no username";
	return undef;
    }

    if (!defined $self->{"PASSWORD"} || $self->{"PASSWORD"} eq "") {
    	$self->{"ERROR"} = "no password";
	return undef;
    }

    my ($r, $l) = _do_cmd ($self->{"HANDLE"},
    		"login $self->{USERNAME} $self->{PASSWORD}");

    if (!defined $r) {
	$self->{"ERROR"} = "error ($l)";
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return 1;
}


sub checkauth {
    my $self = shift;
    my ($cmd) = @_;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
      $self->{"ERROR"} = "not connected";
      return undef;
    }

    if ($cmd eq "") {
      $self->{"ERROR"} = "invalid command";
      return undef;
    }

    my ($r, $l) = _do_cmd ($self->{"HANDLE"}, "checkauth $cmd");

    if ($r =~ /^220/) {
      return 1;
    } else {
      $self->{"ERROR"} = $r;
      return 0;
    }
}


sub disable_watch {
    my $self = shift;
    my ($watch) = @_;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    if ($watch !~ /\S+/) {
    	$self->{"ERROR"} = "invalid watch";
	return undef;
    }

    my ($r, $l) = _do_cmd ($self->{"HANDLE"}, "disable watch $watch");

    if (!defined $r) {
	$self->{"ERROR"} = "error ($l)";
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r;
}


sub disable_service {
    my $self = shift;
    my ($watch, $service) = @_;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    if ($watch !~ /\S+/) {
    	$self->{"ERROR"} = "invalid watch";
	return undef;
    }

    if ($service !~ /\S+/) {
    	$self->{"ERROR"} = "invalid service";
	return undef;
    }

    my ($r, $l) = _do_cmd ($self->{"HANDLE"},
    		"disable service $watch $service");

    if (!defined $r) {
	$self->{"ERROR"} = "error ($l)";
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r;
}


sub disable_host {
    my $self = shift;
    my (@hosts) = @_;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    my ($r, $l) = _do_cmd ($self->{"HANDLE"}, "disable host @hosts");

    if (!defined $r) {
	$self->{"ERROR"} = "error ($l)";
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r;
}


sub enable_watch {
    my $self = shift;
    my ($watch) = @_;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    if ($watch !~ /\S+/) {
    	$self->{"ERROR"} = "invalid watch";
	return undef;
    }

    my ($r, $l) = _do_cmd ($self->{"HANDLE"}, "enable watch $watch");

    if (!defined $r) {
	$self->{"ERROR"} = "error ($l)";
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r;
}


sub enable_service {
    my $self = shift;
    my ($watch, $service) = @_;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    if ($watch !~ /\S+/) {
    	$self->{"ERROR"} = "invalid watch";
	return undef;
    }

    if ($service !~ /\S+/) {
    	$self->{"ERROR"} = "invalid service";
	return undef;
    }

    my ($r, $l) = _do_cmd ($self->{"HANDLE"},
    		"enable service $watch $service");

    if (!defined $r) {
	$self->{"ERROR"} = "error ($l)";
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r;
}


sub enable_host {
    my $self = shift;
    my (@hosts) = @_;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    my ($r, $l) = _do_cmd ($self->{"HANDLE"}, "enable host @hosts");

    if (!defined $r) {
	$self->{"ERROR"} = "error ($l)";
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r;
}


sub version {
    my $self = shift;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    unless (defined($self->{"VERSION"})) {
	my ($r, $l) = _do_cmd ($self->{"HANDLE"}, "version");

	if (!defined $r) {
	    $self->{"ERROR"} = "error ($l)";
	    return undef;
	} elsif ($r !~ /^220/) {
	    $self->{"ERROR"} = $r;
	    return undef;
	}
	($self->{"VERSION"} = $l) =~ s/^version\s+//;;
    }

    return $self->{"VERSION"};
}


sub quit {
    my $self = shift;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    my ($r, $l) = _do_cmd ($self->{"HANDLE"}, "quit");

    return $r;
}


sub list_descriptions {
    my $self = shift;
    my ($d, $group, $service, $desc, %desc);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    my ($r, @d) = _do_cmd ($self->{"HANDLE"}, "list descriptions");

    if (!defined $r) {
	$self->{"ERROR"} = "error (@d)";
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r if (!defined $r);

    foreach $d (@d) {
	($group, $service, $desc) = split (/\s+/, $d, 3);
	$desc{$group}{$service} =
	    _un_esc_str ((parse_line ('\s+', 0, $desc))[0]);
    }

    return %desc;
}


sub list_deps {
    my $self = shift;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    my ($r, @d) = _do_cmd ($self->{"HANDLE"}, "list deps");

    if (!defined $r) {
	$self->{"ERROR"} = "error (@d)";
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r if (!defined $r);

    my %dep = ();

    foreach my $d (@d) {
	my ($what, $group, $service, $l) = split (/\s+/, $d, 4);

	if ($what eq "exp") {
	    $dep{$group}->{$service}->{"expression"} =
	    	_un_esc_str ((parse_line ('\s+', 0, $l))[0]);

	} elsif ($what eq "cmp") {
	    @{$dep{$group}->{$service}->{"components"}} =
	    	split (/\s+/, $l);
	}
    }

    return %dep;
}


sub list_group {
    my $self = shift;
    my ($group) = @_;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    if ($group eq "") {
    	$self->{"ERROR"} = "invalid group";
    	return undef;
    }

    my ($r, $l) = _do_cmd ($self->{"HANDLE"}, "list group $group");

    if ($r =~ /^220/) {
    	$l =~ s/^hostgroup\s+$group\s+//;;
		return split (/\s+/, $l);
    } else {
	$self->{"ERROR"} = $l;
    	return undef;
    }

}


sub list_watch {
    my $self = shift;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    my ($r, @l) = _do_cmd ($self->{"HANDLE"}, "list watch");

    my @groups;

    if ($r =~ /^220/)
    {
    	foreach my $l (@l)
	{
	    push @groups, [split (/\s+/, $l, 2)];
	}
	@groups;
    }
    
    else
    {
	$self->{"ERROR"} = $l;
    	return undef;
    }
}


sub list_opstatus {
    my $self = shift;
    my @g = @_;

    if (@g == 0)
    {
	_list_opstatus ($self, "list opstatus");
    }

    else
    {
	my @l;
	foreach my $i (@g)
	{
	    push @l, "$i->[0],$i->[1]";
	}
    	_list_opstatus ($self, "list opstatus " . join (" ", @l));
    }
}


sub list_failures {
    my $self = shift;

    _list_opstatus($self, "list failures");
}


sub list_successes {
    my $self = shift;

    _list_opstatus($self, "list successes");
}


sub list_disabled {
    my $self = shift;
    my (%disabled, $h);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    my ($r, @d) = _do_cmd ($self->{"HANDLE"}, "list disabled");

    if (!defined $r) {
	$self->{"ERROR"} = $d[0];
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    foreach $r (@d) {
    	if ($r =~ /^group (\S+): (.*)$/) {
	    foreach $h (split (/\s+/, $2)) {
		$disabled{hosts}{$1}{$h} = 1;
	    }

	} elsif ($r =~ /^watch (\S+) service (\S+)$/) {
	    $disabled{services}{$1}{$2} = 1;

	} elsif ($r =~ /^watch (\S+)/) {
	    $disabled{watches}{$1} = 1;

	} else {
	    next;
	}
    }

    return %disabled;
}


sub list_alerthist {
    my $self = shift;
    my (@alerts, $h, $group, $service, $time, $alert, $args, $summary);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    my ($r, @h) = _do_cmd ($self->{"HANDLE"}, "list alerthist");

    if (!defined $r) {
	$self->{"ERROR"} = "error (@h)";
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    foreach $h (@h) {
	$h = _un_esc_str ($h);
    	my ($type, $group, $service, $time, $alert, $args, $summary) =
	    ($h =~ /^(\S+) \s+ (\S+) \s+ (\S+) \s+
		    (\d+) \s+ (\S+) \s+ \(([^)]*)\) \s+ (.*)$/x);
	push @alerts, { type => $type,
		    watch => $group,
		    group => $group,
		    service => $service,
		    time => $time,
		    alert => $alert,
		    args => $args,
		    summary => $summary };
    }

    return @alerts;
}


sub list_dtlog {
    my $self = shift;
    my (@dtlog, $h, $timeup, $group, $service, $failtime, $downtime, $interval, $summary);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
      $self->{"ERROR"} = "not connected";
      return undef;
    }

    my ($r, @h) = _do_cmd ($self->{"HANDLE"}, "list dtlog");

    if (!defined $r) {
      $self->{"ERROR"} = "error (@h)";
      return undef;
    } elsif ($r !~ /^220/) {
      $self->{"ERROR"} = $r;
      return undef;
    }

    foreach $h (@h) {
      $h = _un_esc_str ($h);

      my ($timeup, $group, $service, $failtime, $downtime, $interval, $summary) =
          ($h =~ /^(\d+) \s+ (\S+) \s+ (\S+) \s+
                  (\d+) \s+ (\d+) \s+ (\d+) \s+ (.*)$/x);

      push @dtlog, { timeup => $timeup,
                  group => $group,
                  service => $service,
                  failtime => $failtime,
                  downtime => $downtime,
                  interval => $interval,
                  summary => $summary };
    }

    return @dtlog;
}


sub list_failurehist {
    my $self = shift;
    my ($r, @f, $f, $group, $service, $time, $summary, @failures);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    ($r, @f) = _do_cmd ($self->{"HANDLE"}, "list failurehist");

    if (!defined $r) {
	$self->{"ERROR"} = "@f";
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    foreach $f (@f) {
    	($group, $service, $time, $summary) = split (/\s+/, $f, 4);
	push @failures, {
	    	watch => $group,
		service => $service,
		time => $time,
		summary => $summary
	    };
    }

    return @failures;
}


sub list_pids {
    my $self = shift;
    my ($r, $l, @pids, @p, $p, $pid, $group, $service, $server);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    ($r, @p) = _do_cmd ($self->{"HANDLE"}, "list pids");

    if (!defined $r) {
	$self->{"ERROR"} = "@p";
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    foreach $p (@p) {
    	if ($p =~ /server (\d+)/) {
	    $server = $1;

	} else {
	    ($group, $service, $pid) = split (/\s+/, $p);
	    push @pids, { watch => $group, service => $service, pid => $pid };
	}
    }

    return ($server, @pids);
}


sub list_state {
    my $self = shift;
    my ($r, $l);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    ($r, $l) = _do_cmd ($self->{"HANDLE"}, "list state");

    if (!defined $r) {
	$self->{"ERROR"} = $l;
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    if ($l =~ /scheduler running/) {
    	return (1, $l);
    } elsif ($l =~ /scheduler stopped since (\d+)/) {
    	return (0, $1);
    }
}


sub start {
    my $self = shift;

    _start_stop ($self, "start");
}


sub stop {
    my $self = shift;

    _start_stop ($self, "stop");
}


sub reset {
    my $self = shift;
    my @opts = @_;
    my ($r, $l);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    if (@opts == 0) {
	($r, $l) = _do_cmd ($self->{"HANDLE"}, "reset");
    } else {
	($r, $l) = _do_cmd ($self->{"HANDLE"}, "reset @opts");
    }

    if (!defined $r) {
	$self->{"ERROR"} = $l;
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r;
}


sub reload {
    my $self = shift;
    my ($r, $l);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    ($r, $l) = _do_cmd ($self->{"HANDLE"}, join (" ", "reload", @_));

    if (!defined $r) {
	$self->{"ERROR"} = $l;
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r;
}


sub term {
    my $self = shift;
    my ($r, $l);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    ($r, $l) = _do_cmd ($self->{"HANDLE"}, "term");

    if (!defined $r) {
	$self->{"ERROR"} = $l;
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r;
}


sub set_maxkeep {
    my $self = shift;
    my $val = shift;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    if ($val !~ /^\d+$/) {
    	$self->{"ERROR"} = "invalid value for maxkeep";
	return undef;
    }

    my ($r, $l) = _do_cmd ($self->{"HANDLE"}, "set maxkeep $val");

    if (!defined $r) {
	$self->{"ERROR"} = $l;
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r;
}


sub get_maxkeep {
    my $self = shift;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    my ($r, $l) = _do_cmd ($self->{"HANDLE"}, "set maxkeep");

    if (!defined $r) {
	$self->{"ERROR"} = $l;
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    $l =~ /maxkeep = (\d+)/;

    return $1;
}


sub set {
    my $self = shift;
    my ($group, $service, $var, $val) = @_;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    my ($r, $l) = _do_cmd ($self->{"HANDLE"}, "set $group $service $var " .
    	"'" . _esc_str ($val, 1) . "'");

    if (!defined $r)
    {
    	$self->{"ERROR"} = $l;
	return undef;
    }
    elsif ($r !~ /^220/)
    {
    	$self->{"ERROR"} = $r;
	return undef;
    }

    return $r;
}


sub get {
    my $self = shift;
    my ($group, $service, $var) = @_;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    my ($r, $l) = _do_cmd ($self->{"HANDLE"}, "get $group $service $var");

    if (!defined $r) {
	$self->{"ERROR"} = $l;
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    ($group, $service, $var) = split (/\s+/, $l, 3);
    $var =~ s/^[^=]*=//;

    return _un_esc_str ((parse_line ('\s+', 0, $var))[0]);
}


sub test {
    my $self = shift;
    my ($what, $group, $service, $exitval, $period) = @_;
    my ($r, $l);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    if ($what !~ /^monitor|alert|startupalert|upalert$/) {
    	$self->{"ERROR"} = "unknown test";
	return undef;
    }

    if (!defined $group) {
    	$self->{"ERROR"} = "group not specified";
	return undef;
    }

    if (!defined $service) {
    	$self->{"ERROR"} = "service not specified";
	return undef;
    }

    if ($what =~ /^alert|startupalert|upalert$/ &&
	    ($exitval eq "" || $period eq "")) {
    	$self->{"ERROR"} = "must specify exit value and time period";
	return undef;
    }

    ($r, $l) = _do_cmd ($self->{"HANDLE"},
	    join (" ", "test", $what, $group, $service, $exitval, $period));

    if (!defined $r) {
	$self->{"ERROR"} = $l;
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r;
}


sub test_config {
    my $self = shift;
    my ($r, $l);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
        $self->{"ERROR"} = "not connected";
        return undef;
    }

    ($r, $l) = _do_cmd ($self->{"HANDLE"}, "test config");

    if (!defined $r) {
        $self->{"ERROR"} = $l;
        return undef;
    } elsif ($r !~ /^220/) {
        $self->{"ERROR"} = $r;
        return (0 , $l) ;
    }

    return (1 , $r);
}


sub ack {
    my $self = shift;
    my ($group, $service, $text) = @_;

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    $text = _esc_str ($text, 1);

    my ($r, $l) = _do_cmd ($self->{"HANDLE"}, "ack $group $service '$text'");

    if (!defined $r) {
	$self->{"ERROR"} = $l;
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r;
}


sub loadstate {
    my $self = shift;
    my (@state) = @_;
    my ($r, $l);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    ($r, $l) = _do_cmd ($self->{"HANDLE"}, "loadstate @state");

    if (!defined $r) {
	$self->{"ERROR"} = $l;
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r;
}


sub savestate {
    my $self = shift;
    my (@state) = @_;
    my ($r, $l);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    ($r, $l) = _do_cmd ($self->{"HANDLE"}, "savestate @state");

    if (!defined $r) {
	$self->{"ERROR"} = $l;
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r;
}


sub servertime {
    my $self = shift;
    my ($r, $l, $t);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    ($r, $l) = _do_cmd ($self->{"HANDLE"}, "servertime");

    if (!defined $r) {
	$self->{"ERROR"} = $l;
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    $l =~ /^(\d+)/;
    return $1;
}


#
# clear timers
#
sub clear {
    my $self = shift;
    my ($r, $l);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    ($r, $l) = _do_cmd ($self->{"HANDLE"}, "clear timers");

    if (!defined $r) {
	$self->{"ERROR"} = $l;
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

}


# sub crap_cmd {
#     my $self = shift;
#     my ($r, $l);
# 
#     undef $self->{ERROR};
# 
#     if (!$self->{CONNECTED}) {
#     	$self->{ERROR} = "not connected";
# 	return undef;
#     }
# 
#     ($r, $l) = _do_cmd ($self->{HANDLE}, "COMMAND");
# 
#     if (!defined $r) {
# 	$self->{ERROR} = $l;
#     	return undef;
#     } elsif ($r !~ /^220/) {
# 	$self->{ERROR} = $r;
#     	return undef;
#     }
# 
# }

sub send_trap {
    my $self = shift;
    my %v = @_;

    undef $self->{"ERROR"};

    if ($v{"retval"} !~ /^\d+$/)
    {
	$self->{"ERROR"} = "invalid value for retval";
	return undef;
    }

    if (!defined ($v{"opstatus"} = $OPSTAT{$v{"opstatus"}}))
    {
	$self->{"ERROR"} = "Undefined opstatus type";
	return undef;
    }

    foreach my $k (keys %v)
    {
    	$v{$k} = _esc_str ($v{$k}, 1);
    }

    my $pkt = "";
    $pkt .= "pro='" . _esc_str ($self->{"TRAP_PRO_VERSION"}, 1) . "'\n";
    $pkt .= "usr='" . _esc_str ($self->{"USERNAME"}, 1) . "'\n";
    $pkt .= "pas='" . _esc_str ($self->{"PASSWORD"}, 1) . "'\n"
	    if ($self->{"USERNAME"} ne "");

    $pkt .= "spc='$v{opstatus}'\n" .
	"seq='0'\n" .
	"typ='trap'\n" .
	"grp='$v{group}'\n" .
	"svc='$v{service}'\n" .
	"sta='$v{retval}'\n" .
	"spc='$v{opstatus}'\n" .
	"tsp='" . time . "'\n" .
	"sum='$v{summary}'\n" .
	"dtl='$v{detail}'\n";

    my $proto = getprotobyname ("udp");
    if ($proto eq "")
    {
    	$self->{"ERROR"} = "could not get proto";
	return undef;
    }

    if (!socket (TRAP, AF_INET, SOCK_DGRAM, $proto))
    {
	$self->{"ERROR"} = "could not create UDP socket: $!";
	return undef;
    }

    my $port = $self->{"PORT"};

    my $paddr = sockaddr_in ($port, inet_aton ($self->{"HOST"}));

    if (!defined (send (TRAP, $pkt, 0, $paddr)))
    {
       $self->{"ERROR"} = "could not send trap to ".$self->{"HOST"}.": $!\n";
       return undef;
    }

    close (TRAP);

    return 1;
}


sub _start_stop {
    my $self = shift;
    my $cmd = shift;
    my ($r, $l);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    if ($cmd ne "start" && $cmd ne "stop") {
    	$self->{"ERROR"} = "undefined command";
	return undef;
    }

    ($r, $l) = _do_cmd ($self->{"HANDLE"}, "$cmd");

    if (!defined $r) {
	$self->{"ERROR"} = $l;
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    return $r;
}


sub _list_opstatus {
    my ($self, $cmd) = @_;
    my (%op, $o, %opstatus);
    my ($group, $service, $last, $timer, $summary);

    undef $self->{"ERROR"};

    if (!$self->{"CONNECTED"}) {
    	$self->{"ERROR"} = "not connected";
	return undef;
    }

    my ($r, @op) = _do_cmd ($self->{"HANDLE"}, "$cmd");

    if (!defined $r) {
	$self->{"ERROR"} = $op[0];
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{"ERROR"} = $r;
    	return undef;
    }

    foreach $o (@op) {
	foreach my $w (quotewords ('\s+', 0, $o)) {
	    my ($var, $val) = split (/=/, $w, 2);
	    $op{$var} = _un_esc_str ($val);
	}

	next if ($op{group} eq "");
	next if ($op{service} eq "");
	$group = $op{"group"};
	$service = $op{"service"};
	foreach my $w (keys %op) {
	    $opstatus{$group}{$service}{$w} = $op{$w};
	}
    }

    return %opstatus;
}


sub _sock_write {
    my ($sock, $buf) = @_;
    my ($nleft, $nwritten);

    $nleft = length ($buf);
    while ($nleft) {
        $nwritten = syswrite ($sock, $buf, $nleft);
        return undef if (!defined ($nwritten));
        $nleft -= $nwritten;
        substr ($buf, 0, $nwritten) = "";
    }
}


sub _do_cmd {
    my ($fd, $cmd) = @_;
    my ($l, @out);

    @out = ();
    return (undef) if (!defined _sock_write ($fd, "$cmd\n"));

        for (;;) {
            $l = _sock_readline ($fd);
            return (undef) if (!defined $l);
	    chomp ($l);

            if ($l =~ /^(\d{3}\s)/) {
                last;
            }
            push (@out, $l);
        }

        ($l, @out);
}


sub _sock_readline {
    my ($sock) = @_;

    my $l = <$sock>;
    return $l;
}

1;

#
# not yet implemented
#
#list aliasgroups


sub _esc_str {
    my $str = shift;
    my $inquotes = shift;
    my $escstr = "";

    for (my $i = 0; $i < length ($str); $i++)
    {
    	my $c = substr ($str, $i, 1);

	if (ord ($c) < 32 ||
	    ord ($c) > 126 ||
	    $c eq "\"" ||
	    $c eq "\'")
	{
	    $c = sprintf ("\\%02x", ord($c));
	}
	elsif ($inquotes && $c eq "\\")
	{
	    $c = "\\\\";
	}

	$escstr .= $c;
    }

    $escstr;
}

sub _un_esc_str {
    my $str = shift;

    $str =~ s{\\([0-9a-f]{2})}{chr(hex($1))}eg;

    $str;
}

sub list_aliases {
    my $self = shift;
    my ($r, @d, $d, $group, $service, @allAlias, $aliasBlock, %alias);

    undef $self->{ERROR};

    if (!$self->{CONNECTED}) {
    	$self->{ERROR} = "not connected";
	return undef;
    }

    ($r, @d) = _do_cmd ($self->{HANDLE}, "list aliases");

    if (!defined $r) {
	$self->{ERROR} = "error (@d)";
    	return undef;
    } elsif ($r !~ /^220/) {
	$self->{ERROR} = $r;
    	return undef;
    }

    return $r if (!defined $r);

	# the block separator is \n\n
	@allAlias = split (/\n\n/ ,join ("\n", @d));
	foreach $aliasBlock (@allAlias) {
		my(@allServices, $headerAlias, @headerAlias, $nameLine, $name, $description);
		
		# extract the service block
		@allServices = split ( /\nservice\s*/, $aliasBlock);
		# The first element is not a service block, it is the alias header
		# alias FOO
		# FOO is a good service
		# FOO bla bla
		$headerAlias = shift (@allServices);
		# Split the block to get the name and the description
		@headerAlias = split (/\n/, $headerAlias);
		$nameLine = shift(@headerAlias);
		$nameLine =~ /\Aalias\s+(\S+)/;
		$name = $1;
		
		$headerAlias = join("\n", @headerAlias);
		$alias{$name}{'declaration'} = ($headerAlias) ? $headerAlias : '?';
		
		foreach $service (@allServices) {
			my($serviceName, @allWatch, $watch);
			@allWatch = split ("\n", $service);
			$serviceName = shift(@allWatch);
			foreach $watch (@allWatch) {
				my($groupWatched, $serviceWatched, @items, $url);
				if($watch =~ /\Awatch\s+(\S+)\s+service\s+(\S+)\s+items\s*(.*)\Z/){
					$groupWatched   = $1;
					$serviceWatched = $2;
					@items		= split(/\s+/, $3);
					$alias{$name}{'service'}{$serviceName}{'watch'}{$groupWatched}{'service'}{$serviceWatched}{'items'} = [ @items ];
					
				}elsif($watch =~ /\Aurl\s+(.*)\Z/){
					$url = $1;
					$alias{$name}{'service'}{$serviceName}{'url'} = $url;
				}
			}			
		}
		
	}
    return %alias;
}
