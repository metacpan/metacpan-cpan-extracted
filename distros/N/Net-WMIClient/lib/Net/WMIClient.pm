# WMIClient package to interface with the WMI libraries rather than forking
# wmic.
package Net::WMIClient;
use strict;
use warnings;

require Exporter;

our(@ISA, @EXPORT, @EXPORT_OK, $VERSION);

$VERSION = '0.62';

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(wmiclient);

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

# Call the wmic wrapper after processing the argument list into the proper
# format.
sub wmiclient {

	my @argv;
	my @temp;
	my $argref;
	my $host;
	my $query;
	my $count;
	my $timeout = 0;

	# If the first argument is a hashref, process it for arguments and append
	# them to the remaining list of arguments to be handed off to the wmic
	# wrapper.
	if (ref($_[0]) eq 'HASH') {
		($argref, @argv) = @_;
	# If the first parameter is not a hashref, pass the function arguments
	# on unmodified.
	} else {
		@argv = @_;
	}

	# Check for a host in the remaining options, and throw an error if there
	# is more than one.  Also save it for checking the hashref (if any).
	$count = scalar(@temp = grep(m{^//}, @argv));
	if ($count > 1) {
		return (0, "ERROR: Multiple hosts specified.");
	} elsif ($count == 1) {
		$host = $temp[0];
	}

	# Check for a query in the remaining options, and throw an error if there
	# is more than one  Also save it for checking the hashref (if any)..
	$count = 0;
	my $need_param = 0;
	foreach my $arg (@argv) {
		# If the previous argument needed a parameter, we assume the current
		# argument is that parameter, and just reset the flag.
		if ($need_param) {
			$need_param = 0;
		# The following arguments don't take parameters, so the next argument
		# needs to be checked.
		} elsif ($arg =~ m{^//
				  |^--debug-stderr
				  |^--option=
				  |^--leak-report
				  |^--realm=
				  |^-N|^--no-pass
				  |^--password=
				  |^-P|^--machine-pass
				  |^--simple-bind-dn=
				  |^--use-security-mechanisms=
				  |^--namespace=
				  |^--delimiter=}x) {
			$need_param = 0;
		# Remaining arguments that start with a '-' take a parameter
		} elsif ($arg =~ /^-/) {
			$need_param = 1;
		# And finally, anything else is assumed to be a query.
		} else {
			$count++;
		}
		# If the count is greater than one, error out now even if there are
		# more arguments to check.
		if ($count > 1) {
			return (0, "ERROR: Multiple queries specified.");
		}
	}
	# If we have exactly one query, save it for checking the hashref (if any).
	if ($count == 1) {
		$query = $temp[0];
	}

	# Parse the hashref if we have one.  All options from wmic are supported
	# in the hashref EXCEPT for -?|--help, --usage and -V|--version.  The hash
	# mappings are as follows:
	#   DebugLevel => DEBUGLEVEL : [-d|--debuglevel DEBUGLEVEL]
	#   DebugStderr => true : [--debug-stderr]
	#   ConfigFile => CONFIGFILE : [-s|--configfile CONFIGFILE]
	#   Option => \('name=value', ...) : [--option=name=value]
	#   LogFileBase => LOGFILEBASE : [-l|--log-basename LOGFILEBASE]
	#   LeakReport => true : [--leak-report]
	#   LeakReportFull => true : [--leak-report-full]
	#   NameResolve => NAME-RESOLVE-ORDER : [-R|--name-resolve NAME-RESOLVE-ORDER]
	#   SocketOpt => SOCKETOPTIONS : [-O|--socket-options SOCKETOPTIONS]
	#   NetBIOSName => NETBIOSNAME : [-n|--netbiosname NETBIOSNAME]
	#   Workgroup => WORKGROUP : [-W|--workgroup WORKGROUP]
	#   Realm => REALM : [--realm=REALM]
	#   Scope => SCOPE : [-i|--scope SCOPE]
	#   MaxProtocol => MAXPROTOCOL : [-m|--maxprotocol MAXPROTOCOL]
	#   Username => [DOMAIN/]USERNAME[%PASSWORD] : [-U|--user [DOMAIN/]USERNAME[%PASSWORD]]
	#   NoPass => true : [-N|--no-pass]
	#   Password => STRING : [--password=STRING]
	#   AuthFile => FILE : [-A|--authentication-file FILE]
	#   Signing => [on|off|required] : [-S|--signing on|off|required]
	#   MachinePass => true : [-P|--machine-pass]
	#   SimpleBindDN => STRING : [--simple-bind-dn=STRING]
	#   Kerberos => STRING : [-k|--kerberos STRING]
	#   UseSecMech => STRING : [--use-security-mechanisms=STRING]
	#   Namespace => STRING : [--namespace=STRING]
	#   Delimiter => STRING : [--delimiter=STRING]
	#   Host => "//<hostname>"
	#   Query => "<WMI query string>"
	if ($argref) {
		$timeout = $argref->{'Timeout'} if exists($argref->{'Timeout'});
		push @argv, ('-d', $argref->{'DebugLevel'}) if exists($argref->{'DebugLevel'});
		push @argv, ('--debug-stderr') if (exists($argref->{'DebugStderr'}) && $argref->{'DebugStderr'});
		push @argv, ('-s', $argref->{'ConfigFile'}) if exists($argref->{'ConfigFile'});
		if (exists($argref->{'Option'})) {
			my $options = $argref->{'Option'};
			if (ref($options)) {
				foreach my $option (@{$options}) {
					push @argv, "--option=$option";
				}
			} else {
				push @argv, "--option=$options";
			}
		}
		push @argv, ('-l', $argref->{'LogFileBase'}) if exists($argref->{'LogFileBase'});
		push @argv, ('--leak-report') if (exists($argref->{'LeakReport'}) && $argref->{'LeakReport'});
		push @argv, ('--leak-report-full') if (exists($argref->{'LeakReportFull'}) && $argref->{'LeakReportFull'});
		push @argv, ('-R', $argref->{'NameResolve'}) if exists($argref->{'NameResolve'});
		push @argv, ('-O', $argref->{'SocketOpt'}) if exists($argref->{'SocketOpt'});
		push @argv, ('-n', $argref->{'NetBIOSName'}) if exists($argref->{'NetBIOSName'});
		push @argv, ('-W', $argref->{'Workgroup'}) if exists($argref->{'Workgroup'});
		push @argv, ('--realm='.$argref->{'Realm'}) if exists($argref->{'Realm'});
		push @argv, ('-i', $argref->{'Scope'}) if exists($argref->{'Scope'});
		push @argv, ('-m', $argref->{'MaxProtocol'}) if exists($argref->{'MaxProtocol'});
		push @argv, ('-U', $argref->{'Username'}) if exists($argref->{'Username'});
		push @argv, ('-N') if (exists($argref->{'NoPass'}) && $argref->{'NoPass'});
		push @argv, ('--password='.$argref->{'Password'}) if exists($argref->{'Password'});
		push @argv, ('-A', $argref->{'AuthFile'}) if exists($argref->{'AuthFile'});
		push @argv, ('-S', $argref->{'Signing'}) if exists($argref->{'Signing'});
		push @argv, ('-P') if (exists($argref->{'MachinePass'}) && $argref->{'MachinePass'});
		push @argv, ('--simple-bind-dn='.$argref->{'SimpleBindDN'}) if exists($argref->{'SimpleBindDN'});
		push @argv, ('-k', $argref->{'Kerberos'}) if exists($argref->{'Kerberos'});
		push @argv, ('--use-security-mechanisms='.$argref->{'UseSecMech'}) if exists($argref->{'UseSecMech'});
		push @argv, ('--namespace='.$argref->{'Namespace'}) if exists($argref->{'NameSpace'});
		push @argv, ('--delimiter='.$argref->{'Delimiter'}) if exists($argref->{'Delimiter'});
		if (exists($argref->{'Host'})) {
			if ($host) {
				return (0, "ERROR: Multiple hosts specified.");
			} else {
				$host = $argref->{'Host'};
				$host = "//$host" unless ($host =~ m{^//});
			}
			push @argv, $host;
		}
		if (exists($argref->{'Query'})) {
			if ($query) {
				return (0, "ERROR: Multiple queries specified.");
			}
			push @argv, $argref->{'Query'};
		}
	}

	# Place the calling program at the beginning of the argument list to
	# mimic argv[], and call the wrapper function.
	unshift @argv, $0;
	my $return = call_wmic($timeout, scalar(@argv), \@argv);
	if ($return =~ /^(\d)(.*)/s) {
		return ($1, $2);
	} else {
		return(0, "Invalid return value: '$return'");
	}
}

1;
__END__
=head1 NAME

Net::WMIClient - Perl extension for WMI calls

=head1 SYNOPSIS

  use Net::WMIClient qw(wmiclient);
  ($rc, $ret_string) = wmiclient([HASHREF], LIST);

=head1 DESCRIPTION

This module provides a perl interface to libasync_wmi_lib, which implements the
wmic binary as a Perl module.  Returns the non-debug output as a string for
parsing.

=head2 Functions

=over 2

=item wmiclient([HASHREF], LIST)

Returns a true/false value to indicate success or failure, and the WMI output as
a string, the same as calling `wmic <params> 2>&1`.  In the event of an invalid
output response, returns failure and the string "Invaild return value:" followed
by the output enclosed in single quotes.  Parameters may be passed in a hashref,
a list, or both.  The list parameter may be empty the hashref is provided.  The
hashref accepts the following entries:

=over 2

=over 2

=item B<< Timeout => <int> >>

Sets a timeout after which the wmiclient call will abort and return a failure
with the output 'TIMEOUT'.  By default, the WMI client call will timeout after
60 seconds - setting this value will reduce that, but cannot increase it.  This
parameter is only available as part of the hashref, and cannot be set in list
context.

=item B<< DebugLevel => <int> >>

Equivalent to '-d N'.  Note that debug output is NOT captured, and will be sent directly to
STDOUT unless B<DebugStderr> is also set.

=item B<< DebugStderr => <bool> >>

If set to a true value, equivalent to '--debug-stderr'.

=item B<< ConfigFile => <string> >>

Equivalent to '-s CONFIGFILE'.

=item B<< Option => <arrayref> >>

Specifies an array of 'name=value' options to be set explicitly.  Each entry in
the array will be passed equivalent to '--option=name=value'.

=item B<< LogFileBase => <string> >>

Equivalent to '-l LOGFILEBASE'.

=item B<< LeakReport => <bool> >>

If set to a true value, equivalent to '--leak-report'.

=item B<< LeakReportFull => <bool> >>

If set to a true value, equivalent to '--leak-report-full'.

=item B<< NameResolve => <string> >>

Equivalent to '-R NAME-RESOLVE-ORDER'.

=item B<< SocketOpt => <string> >>

Equivalent to '-O SOCKETOPTIONS'.

=item B<< NetBIOSName => <string> >>

Equivalent to '-n NETBIOSNAME'.

=item B<< Workgroup => <string> >>

Equivalent to '-W WORKGROUP'.

=item B<< Realm => <string> >>

Equivalent to '--realm=REALM'.

=item B<< Scope => <string> >>

Equivalent to '-i SCOPE'.

=item B<< MaxProtocol => <string> >>

Equivalent to '-m MAXPROTOCOL'.

=item B<< Username => <string> >>

Equivalent to '-U [DOMAIN/]USERNAME[%PASSWORD]'.

=item B<< NoPass => <bool> >>

Equivalent to '-N'.

=item B<< Password => <string> >>

Equivalent to '--password=STRING'.

=item B<< AuthFile => <string> >>

Equivalent to '-A FILE'.

=item B<< Signing => [on|off|required] >>

Equivalent to '-S [on|off|required]'.

=item B<< MachinePass => <bool> >>

If set to a true value, equivalent to '-P'.

=item B<< SimpleBindDN => <string> >>

Equivalent to '--simple-bind-dn=STRING'.

=item B<< Kerberos => <string> >>

Equivalent to '-k STRING'.

=item B<< UseSecMech => <string> >>

Equivalent to '--use-security-mechanisms=STRING'.

=item B<< Namespace => <string> >>

Equivalent to '--namespace=STRING'.

=item B<< Delimiter => <string> >>

Equivalent to '--delimiter=STRING'.

=item B<< Host => <string> >>

Specifies the host to query.  Can either be a plain host name, or //<hostname>.

=item B<< Query => <string> >>

Specifies the WMI query to be sent to the host.

=back

=back

Options specified in both the hashref and array will be passed along, with
parameters in the hashref overriding those in the array.  The exception is
that if multiple hosts are specified, or multiple queries, wmiclient will
return an error.

=back

=head2 Export

wmiclient

=head1 REQUIRED LIBRARIES

Requires libasync_wmi_lib.so.0 from the wmi package available at
http://www.edcint.co.nz/checkwmiplus/wmi-1.3.14.tar.gz.

=head1 SEE ALSO

The wmic binary from the wmi package.

=head1 AUTHOR

Joshua Megerman, E<lt>josh@honorablemenschen.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Joshua Megerman

Portions Copyright by Jelmer Vernooij, Tim Potter, and Andrzej Hajda

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=cut
