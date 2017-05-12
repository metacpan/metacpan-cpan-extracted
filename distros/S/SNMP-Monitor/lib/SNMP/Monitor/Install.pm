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

package SNMP::Monitor::Install;

use strict;
require SNMP;
require SNMP::Monitor;
use ExtUtils::MakeMaker qw(prompt);


$SNMP::Monitor::Install::VERSION = '0.01';


sub Install ($$$) {
    require Sys::Hostname;

    my($class, $file, $prefix) = @_;

    my $config = { hosts => {} };

    my $default = $prefix;
    if ($default !~ /etc/) {
	$default .= "/etc";
    }
    $config->{etc_dir} = prompt("\nWhich directory should be used for the"
				. " config file?", $default);
    if (! -d $config->{etc_dir}) {
	if (prompt("\nA directory " . $config->{etc_dir} . " does not exist."
		   . "\nCreate it?", "y")  !~  /y/i) {
	    die "etc_dir is not a valid directory, cannot continue.";
	}
    } else {
	my $target = $config->{etc_dir} . "/configuration";
	if (-f $target) {
	    my $reply = prompt("\nA file $target already exists. Read"
			       . " configuration from this file?", "y");
	    if ($reply =~ /y/i) {
		$config = SNMP::Monitor->Configuration($target);
	    }
	}
    }

    my $pidFile = $config->{pid_file} || "/var/run/snmpmon.pid";
    $config->{pid_file} = prompt("\nWhere to store the PID file?", $pidFile);
    require File::Basename;
    my $dirname = File::Basename::dirname($config->{pid_file});
    if (! -d $dirname) {
	if (prompt("\nA directory $dirname does not exist."
		   . "\nCreate it?", "y")  !~  /y/i) {
	    die "pid_file is not in a valid directory, cannot continue.";
	}
    }

    my $facility = $config->{facility} || 'daemon';
    $facility = prompt("\nEnter the syslog facility for logging messages: ",
		       $facility);
    require Sys::Syslog;
    if (Sys::Syslog::xlate($facility) == -1) {
	die "Unknown syslog facility: $facility";
    }
    $config->{facility} = $facility;

    $config->{dbi_dsn} = prompt("\nWhich DBI DSN should be used for"
				. " connecting to the database?\n",
				($config->{dbi_dsn} || "DBI:mysql:snmpmon"));

    my $user;
    if (exists($config->{dbi_user})) {
	$user = defined($config->{dbi_user}) ? $config->{dbi_user} : "undef";
    } else {
	$user = "undef";
    }
    $user = prompt("\nWhich user name should be used for connecting to"
		   . " the database?\n", $user);
    $config->{dbi_user} = ($user eq "undef") ? undef : $user;

    my $pass;
    if (exists($config->{dbi_pass})) {
	$pass = defined($config->{dbi_pass}) ? $config->{dbi_pass} : "undef";
    } else {
	$pass = "undef";
    }
    $pass = prompt("\nWhich password should be used for connecting to"
		   . " the database?\n", $pass);
    $config->{dbi_pass} = ($pass eq "undef") ? undef : $pass;

    require DBI;
    print "Connecting to the database ... ";
    my $dbh;
    if (!($dbh = DBI->connect($config->{dbi_dsn}, $config->{dbi_user},
			      $config->{dbi_pass},
			      { PrintError => 0 }))) {
	die "\nCannot connect to database " . $config->{dbi_dsn} . " as user "
	    . $config->{dbi_user} . " with password " . $config->{dbi_pass}
	    . ": " . $DBI::errstr;
    }
    print "ok\n";

    print "Checking for an 'SNMPMON_IFLOAD' table ... ";
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM SNMPMON_IFLOAD");
    if (!$sth) {
	die "\nCannot prepare query: " . $dbh->errstr();
    }
    if ($sth->execute()  &&  $sth->fetchrow_arrayref()) {
	print "ok.\n";
	$sth->finish();
    } else {
	$sth->finish();
	require SNMP::Monitor::Event::IfLoad;
	if (!$dbh->do($SNMP::Monitor::Event::IfLoad::CREATE_QUERY)) {
	    die "Cannot create table 'SNMPMON_IFLOAD': " . $dbh->errstr();
	}
    }
    undef $sth;
    $dbh->disconnect();

    my $email;
    if (exists($config->{email})) {
	$email = $config->{email};
    } else {
	$email = ($ENV{'USER'} || "root") . '@' . Sys::Hostname::hostname();
    }
    $config->{email} = prompt("\nWhat email address should be used for"
			      . " problem reports?\n", $email);


    my $searchSub = sub {
	my($prog) = @_;
	my $dir;
	foreach $dir (split(/:/, $ENV{'PATH'})) {
	    if (-x "$dir/$prog") {
		return "$dir/$prog";
	    }
	}
	undef;
    };

    my $path;
    if (exists($config->{path_gnuplot})) {
        $path = $config->{path_gnuplot};
    } else {
	$path = &$searchSub("gnuplot");
    }
    if (!$path) {
        $path = "none";
    }
    $path = prompt("Enter the path to the gnuplot binary, version 3.6 beta\n"
		   . "or later:", $path);
    if ($path eq 'none'  ||  !$path) {
        $path = undef;
        print("Ok, but you won't be able to display the interface\n",
	      "utilization in that case.\n");
    }
    $config->{path_gnuplot} = $path;

    if (exists($config->{path_ppmtogif})) {
        $path = $config->{path_ppmtogif};
    } else {
	$path = &$searchSub("ppmtogif");
    }
    if (!$path) {
        $path = "none";
    }
    $path = prompt("Enter the path to the ppmtogif binary: ", $path);
    if ($path eq 'none'  ||  !$path) {
        $path = undef;
        print("Ok, but you won't be able to display the interface\n",
	      "utilization in that case.\n");
    }
    $config->{path_ppmtogif} = $path;

    if (!%{$config->{hosts}}) {
	my $name = prompt("Do you want to configure a router?\n"
			  . "Enter the routers name: ", "none");
	if ($name ne 'none') {
	    SNMP::Monitor::Install->AddRouter($config, $name);
	}
    }

    SNMP::Monitor::Install->SaveFile($file, $config);

    $config;
}


sub SaveFile ($$$) {
    my($class, $file, $config) = @_;

    require Data::Dumper;
    my $dumped = Data::Dumper->new([$config], ['CONFIGURATION']);
    $dumped->Indent(1);
    my $cstr = $dumped->Dump();

    my (@comments) =
        (['etc_dir',
          'The directory where to create router configurations'
         ],
	 ['pid_file',
	  'Where to store the PID file.'
	 ],
	 ['facility',
	  'The syslog facility.'
	 ],
         ['dbi_dsn',
          'A DBI DSN declaring the database being used for accouting.'
         ],
         ['dbi_user',
          'A user name for connecting to the accounting database.'
         ],
         ['dbi_pass',
          'A user name for connecting to the accounting database.'
         ],
	 ['email',
	  'The Snmpmon administrators email address.'
         ],
	 ['hosts',
	  <<'NOTICE'
A hash ref of hosts that are monitored by snmpmon. The hash values are
again hash refs with the following attributes:

    name        - router name; same as the primary hash's key
    description - a one-line description of the router
    DestHost    - the DNS name or IP address of the router
    RemotePort  - the SNMP agent's port, by default 161
    Community   - the SNMP agent's community string, for example "public"
    interfaces  - an array ref of interfaces that are monitored on this
                  router; the elements are hash refs (you guessed it? :-)
                  with the following attributes:

			num           - Interface number
			description   - Interface name, as returned
                                        by the router in SNMP queries
                        short_message - One line text describing the
                                        interface in reports
			speed         - Interface speed; for calculating the
				        interface load
			type          - Interface type
                        events        - List of Event objects being created
                                        for that interface

NOTICE
         ],
         ['path_gnuplot',
          'Path to the GNUplot binary, 3.6 beta or later'
         ],
         ['path_ppmtogif',
          'Path to the ppmtogif binary'
         ]
	 );

    my $ref;
    foreach $ref (@comments) {
        my $attr = $ref->[0];
        my $comment = '';
        my $line;
        foreach $line (split(/\n/, $ref->[1])) {
            $comment .= "# $line\n";
        }
        $cstr =~ s/^(  \'\Q$attr\E)/$comment$1/m;
    }

    my $fh;
    $@ = '';
    eval { require IO::AtomicFile; };
    if ($@) {
        $fh = IO::File->new($file, "w");
    } else {
        $fh = IO::AtomicFile->open($file, "w");
    }
    if (!$fh) {
        die "Cannot create configuration file $file: $!";
    }
    if (!$fh->print($cstr)) {
        if ($fh->isa("IO::AtomicFile")) {
            $fh->delete();
        }
        die "Error while writing $file: $!";
    }
    if (!$fh->close()) {
        die "Fatal error while writing $file, contents may be destroyed: $!";
    }
}


############################################################################
#
#    Name:    AddRouter
#
#    Purpose: Add a new router to the list of machines by querying its
#             values interactively.
#
#    Inputs:  $class - This class
#             $config - SNMP-Monitor configuration
#             $name - Routers name
#
#    Returns: Modified configuration
#
############################################################################

sub AddRouter ($$$) {
    my($class, $config, $name) = @_;
    if (exists($config->{hosts}->{$name})) {
	die "A router $name already exists in the configuration.\n";
    }
    if (length($name) > 10) {
	die "Internal router names must have 10 characters or less.\n";
    }

    my $router = { name => $name };
    while (!$router->{description}) {
	$router->{description} = prompt("Enter a one-line description of"
					. " router $name:", undef);
	if (!$router->{description}) {
	    print STDERR "A non-empty description is required.\n";
	}
    }
    while (!$router->{DestHost}) {
	$router->{DestHost} = prompt("Enter router ${name}'s host name or IP"
				     . " address:", undef);
	require Socket;
	if (!Socket::inet_aton($router->{DestHost})) {
	    print STDERR ("Cannot resolv host name: ", $router->{DestHost},
			  "\n");
	    delete $router->{DestHost};
	}
    }
    while (!$router->{Community}) {
	$router->{Community} = prompt("Enter router ${name}'s community"
				      . " string: ", "public");
	if (!$router->{Community}) {
	    print STDERR "A community string is required.\n";
	}
    }

    while (!$router->{RemotePort}) {
	$router->{RemotePort} = prompt("Enter router ${name}'s SNMP port: ",
				       161);
	if (!$router->{RemotePort}) {
	    print STDERR "A non-zero port number must be given.\n";
	} else {
	    if ($router->{RemotePort} !~ /^\d+$/) {
		my $port = getservbyname($router->{RemotePort}, 'udp');
		if (!$port) {
		    print STDERR ("Unknown service: ", $router->{RemotePort},
				  "\n");
		    undef $router->{RemotePort};
		} else {
		    $router->{RemotePort} = $port;
		}
	    }
	}
    }

    require SNMP;
    my $session = SNMP::Session->new(%$router);
    if (!$session) {
	die "Cannot create session object." . ($! ? " ($!)" : "");
    }

    my $vb = SNMP::Varbind->new(["interfaces.ifNumber", 0]);
    $session->get($vb);
    if ($session->{ErrorNum}) {
	die "Failed to open SNMP session to " . $router->{DestHost} . ": "
	    . $session->{ErrorStr};
    }
    if (!$vb->[2]) {
	die "Router " . $router->{DestHost}
	    . " doesn't seem to have any interfaces.";
    }


    print "I have found the following interfaces:\n";
    my $j = 0;
    my $iList = [];
    my $nLen = length("Nr");
    my $dLen = length("Description");
    my $aLen = length("AdminStatus");
    my $opLen = length("OperStatus");
    my $iLen = length("InOctets");
    my $oLen = length("OutOctets");

    for (my $i = 1;  $i <= $vb->[2];  $i++) {
	my $table = "interfaces.ifTable.ifEntry";
	my $vl = SNMP::VarList->new(["$table.ifDescr", $i],
	                            ["$table.ifAdminStatus", $i],
				    ["$table.ifOperStatus", $i],
				    ["$table.ifInOctets", $i],
				    ["$table.ifOutOctets", $i],
				    ["$table.ifSpeed", $i],
				    ["$table.ifType", $i]);
	$session->get($vl);
	if ($session->{ErrorNum}) {
	    die "Failed to retrieve interface list: " . $session->{ErrorStr};
	}

	my $hash = { num => $i };
	$hash->{descr}       = $vl->[0]->[2];
	$hash->{adminStatus} = $vl->[1]->[2];
	$hash->{operStatus}  = $vl->[2]->[2];
	$hash->{inOctets}    = $vl->[3]->[2];
	$hash->{outOctets}   = $vl->[4]->[2];
	$hash->{speed}       = $vl->[5]->[2];
	$hash->{type}        = $vl->[6]->[2];
	push(@$iList, $hash);
	if (length($hash->{num}) > $nLen) {
	    $nLen = length($hash->{num});
	}
	if (length($hash->{descr}) > $dLen) {
	    $dLen = length($hash->{descr});
	}
	if (length($hash->{adminStatus}) > $aLen) {
	    $aLen = length($hash->{adminStatus});
	}
	if (length($hash->{operStatus}) > $opLen) {
	    $opLen = length($hash->{operStatus});
	}
	if (length($hash->{inOctets}) > $iLen) {
	    $iLen = length($hash->{inOctets});
	}
	if (length($hash->{outOctets}) > $oLen) {
	    $oLen = length($hash->{outOctets});
	}
    }

    my $format = sprintf("%%%ds  %%-%ds  %%-%ds  %%-%ds  %%%ds  %%%ds\n",
			 $nLen, $dLen, $aLen, $opLen, $iLen, $oLen);
    printf("$format\n", "Nr", "Description", "AdminStatus", "OperStatus",
	   "InOctets", "OutOctets");
    for (my $i = 0;  $i < @$iList;  $i++) {
	printf($format, $iList->[$i]->{num}, $iList->[$i]->{descr},
	       $iList->[$i]->{adminStatus} ? "Up" : "Down",
	       $iList->[$i]->{operStatus} ? "Up" : "Down",
	       $iList->[$i]->{inOctets}, $iList->[$i]->{outOctets});
    }

    my $ifStatusRequest = prompt("\nFor which interfaces do you want messages"
				 . " if the interface status changes?\n"
				 . "Enter a comma separated list of numbers:",
				 join(",", (1 .. @$iList)));
    my $ifLoadRequest = prompt("\nFor which interfaces shall I log the"
			       . " utilization into a database?\n"
			       . "Enter a comma separated list of numbers:",
			       join(",", (1 .. @$iList)));


    $router->{interfaces} = [];
    for (my $i = 0;  $i < @$iList;  $i++) {
	my $ref = { description => $iList->[$i-1]->{descr},
		    short_message => $iList->[$i-1]->{descr},
		    num => $iList->[$i-1]->{num},
		    speed => $iList->[$i-1]->{speed},
		    type => $iList->[$i-1]->{type},
		    events => []
	};
	my $r;
	foreach $r (split(/,/, $ifStatusRequest)) {
	    if ($r eq $ref->{num}) {
		push(@{$ref->{events}}, "SNMP::Monitor::Event::IfStatus");
		last;
	    }
	}
	foreach $r (split(/,/, $ifLoadRequest)) {
	    if ($r eq $ref->{num}) {
		push(@{$ref->{events}}, "SNMP::Monitor::Event::IfLoad");
		last;
	    }
	}
	push(@{$router->{interfaces}}, $ref);
    }

    if (!@{$router->{interfaces}}) {
	print("No interfaces selected.\nI won't add router $name.\n");
    } else {
	$config->{hosts}->{$name} = $router;
    }
}


1;


__END__

=head1 NAME

SNMP::Monitor::Install - Create a config file for SNMP::Monitor module


=head1 SYNOPSIS

    require SNMP::Monitor::Install;

    # Create a new config file
    SNMP::Monitor::Install->Install($file, $prefix);

    # Save a config file
    SNMP::Monitor::Install->Save($file, $config);

=head1 DESCRIPTION

This module is used to create config files for the SNMP::Monitor module.
It offers class methods for creating new files and adding hosts. It
tries to guess system defaults and queries the user for settings.

All methods throw a Perl exception in case of errors.

=over 4

=item Install($file, $prefix)

(Class method) This method is called to create a completely new
config file. It suggests the prefix C<$prefix> as a default for
directory locations and stores the configuration in the file
C<$file>.

=item Save($file, $config)

(Class method) Saves the configuration C<$config> in the file C<$file>.

=back


=head1 CONFIGURATION FILE

The configuration file is created by the Data::Dumper module. See
L<Data::Dumper(3)>. This means that it contains valid Perl source:
You have both the restrictions that Perl puts on you and the full
power of Perl available.

However, the first thing to keep in mind when manually editing the
file is: Do yourself a favour and let Perl do a syntax check for
you by executing

    perl -e 'require "/etc/snmpmon/configuration"; print "ok\n"'

In general, the configuration file contains a hash ref, thus a
lot of key/value pairs. Available keys include:

=over 8

=item dbi_dsn

=item dbi_user

=item dbi_pass

The DSN, user name and password for accessing the database.

=item email

The administrators email address. Messages will be sent to this
address. It is overridable in the router and interface configuration.
Multiple, comma separated recipients can be used.

=item etc_dir

Path to the directory where the C<configuration> file is stored.

=item facility

The syslog facility to use for syslog messages, by default C<daemon>.

=item hosts

An hash ref routers that are being monitored, in other words: Yet
more key/value pairs, the keys being router names and the values
being router configurations.

See L<"Router configuration"> below for a description of the
values.

=item path_gnuplot

=item path_ppmtogif

The paths to the I<gnuplot> and I<ppmtogif> binaries

=item pid_file

Path of the PID file. By default C</var/run/snmpmon.pid>.

=item users

A list of users that may view information. Can be overwritten in the
router or interface configuration.

=back


=head2 Router configuration

For any router in the list of routers an SNMP::Session instance will
be created. Thus the router is configured by a hash ref of key/value
pairs that merely describe the SNMP session:

=over 8

=item Community

The community string being used for accessing the routers SNMP server;
defaults to C<public>.

=item description

A one line description of the router, from time to time being used in
output.

=item DestHost

The routers host name (resolvable via DNS) or IP address.

=item email

This attribute, if present, overrides the global C<email> attribute.

=item interfaces

A list of interfaces being available at the router. Configuring an
interface here doesn't necessarily mean, that a session is watching
this interface. For example, you definitely don't want to receive
an email any time when a dialup line goes up or down. :-)

See L<"Interface configuration"> below for a detailed description
of interfaces.

=item name

A short, unique name of the router. This name is used for identifying
the router in the database, thus it has to be short (10 characters).

=item RemotePort

The service name or port number where the routers SNMP server is
listening. Defaults to C<161>.

=item users

A list of users that may view information about this router. Can be
overwritten in the interface configuration.

=back


=head2 Interface configuration

Interfaces are yet more key/value pairs, the keys being:

=over 8

=item description

The interface number, as returned by the SNMP variable
C<interfaces.ifTable.ifEntry.ifDescr>.

=item email

This attribute, if present, overrides the routers C<email> attribute.

=item events

An array list of events being created for monitoring this interface.
Currently available are:

=over 12

=item SNMP::Monitor::Event::IfStatus

This is for watching the interface status. Whenever the administrative
or operative status changes, then a mail will be sent to the interfaces
admin. You definitely don't want this for a dialup line ... :-)

The status will be queried every minute.

=item SNMP::Monitor::Event::IfLoad

This is for logging accounting information. Every 5 minutes the module
will query the interfaces status and the C<ifInOctets> and C<ifOutOctets>.
The interface utilization in percent will be calculated and written to
the database, together with the status information and the counter
differences.

=back

=item num

The interface number, as returned by the SNMP variable
C<interfaces.ifTable.ifEntry.ifIndex>.

=item speed

The interface speed in Bits per second, as returned by the SNMP variable
C<interfaces.ifTable.ifEntry.ifSpeed>.

=item short_message

A textual description of the interface, being used in reports and other
output.

=item type

The interface type, as returned by the SNMP variable
C<interfaces.ifTable.ifEntry.ifType>.

=item users

A list of users that may view information about this interface.

=back


=head1 AUTHOR AND COPYRIGHT

This module is

    Copyright (C) 1998    Jochen Wiedmann
                          Am Eisteich 9
                          72555 Metzingen
                          Germany

                          Phone: +49 7123 14887
                          Email: joe@ispsoft.de

All rights reserved.

You may distribute this module under the terms of either
the GNU General Public License or the Artistic License, as
specified in the Perl README file.


=head1 SEE ALSO

L<snmpmon(1)>, L<SNMP::Monitor(3)>

=cut
