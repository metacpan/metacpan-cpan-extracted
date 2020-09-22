# $Id: Run.pm,v 1.7 2005-04-11 12:08:51 mike Exp $

package Net::Z3950::DBIServer::Run;
use strict;


=head1 NAME

Net::Z3950::DBIServer::Run - Invoking the zSQLgate Server


=head1 SYNOPSIS

C<zSQLgate>
I<config-file>
I<[YAZ-options]>
I<[listener]>
...

=head1 DESCRIPTION

C<zSQLgate>
provides an Z39.50 interface to your relational databases.
That is, it provides a generic gateway between the Z39.50 Information
Retrieval protocol and pretty much any relational database you
care to mention.

This document describes how to invoke the C<zSQLgate> server from the
command-line: what the options do and how to specify listener
addresses.  For other information, including details of the
configuration file format, see L<::zSQLgate> and the linked pages.


=head1 OPTIONS

Besides the mandatory configuration-file name, the following options
may be provided on the command-line.  These are all inherited from the
YAZ back-end server on which zSQLgate is built.

=over 4

=item -a I<APDUfile>

APDU file.  Specifies a file for dumping APDUs (for diagnostic
purposes).  The special name ``C<->'' sends output to the standard
error stream.  It's better then even money that you'll never, ever do
this.  (Though now I've said that, you'll try it just to spite me.)

=cut

=item -S

Static.  Prevents the server from C<fork()>ing on connection requests.
This can be useful for debugging, but is not recommended for real
operation: although the server is asynchronous and non-blocking, there
are potential efficiency gains in having separate server processes for
each client connection: for example, a single intensive back-end
operation on the behalf of one client will not cause simpler requests
from other clients to be delayed.

=item -l I<logFile>

Log file.  Specifies a file to which to write logging messages, which
by default go to the standard error stream.

=item -v I<verbosity>

Verbosity.  Specifies what information to write to the log file.  The
I<verbosity> specification should be a comma-separated list of one or
more of the following words:

	fatal, debug, warn, log, all, none

The default logging level is C<fatal,warn,log> - that is, everything
except the very verbose C<debug> messages.

=item -u I<userName>

User.  Sets the running server's real and effective user IDs to that
of the specified user.  This is useful if you need the server to start
running as C<root> so it can bind to a privileged port, but you don't
otherwise want or need to run as C<root>.

=item -w I<dir>

Working directory.  Tells the server to run in the specified
directory.

=item -i

Inetd.  Used when running C<zSQLgate> from the C<inetd> server.  The
default is to run in standalone mode.

=item -t I<minutes>

Timeout.  Tells the server to unilaterally close client connections
after they are idle for the specified number of minutes.

=cut

### does timeout=0 => forever?

=item -k I<Kb>

Sets the maximum record size and message size to the specified number
of kilobytes.  You should really never need this.

=item -1

One-shot mode.  Tells the server to serve a single connection, then
exit immediately.  This can be useful when debugging, but not in
normal use.

=item -T

Threads.  Asks the server to use threads, rather than multiple
processes, on systems where that is an option.  On Windows NT, this is
the default (and indeed only) mode.

=item -s

SR.  Instructs the server to use the obsolete ISO SR protocol rather than
Z39.50.  I don't think there's any reason to do this now, if there
ever was, but it's there for completeness.

=item -z

Z39.50.  Instructs the server to speak Z39.50 rather than the
obsolete ISO SR protocol.  This is the default.

=cut

### I don't honestly understand what these are
#=item -c I<string>
#
#Sets C<configname> to the specified I<string>.
#
#=item -d I<something>
#
#Sets C<daemonname> to the specified I<string>.

=back


=head1 LISTENER SPECIFICATIONS

Following any options on the command line, one or more listener
specifications may be provided.  A listener specification consists of
a transport mode followed by a colon (C<:>) followed by a listener
address.  The transport mode may be either C<tcp> or C<ssl>.  The
former is the default and may be omitted.   The
latter is experimental; please don't hassle me if you can't get it to
work.  (I know I<I> can't.)

The address itself consists of a hostname or IP number, optionally
followed by a colon and a port number; if the port number is omitted,
it defaults to 210, the standard Z39.50 port.  The special hostname
C<@> is mapped to the address C<INADDR_ANY>, which causes the server
to listen on any local interface.  This is nearly always what you
want.

For example, to start C<zSQLgate> in static (single-process) mode
with logging going to the C<zsql.log> file and listening for
connections on ports 210 and 3950, use:

	zSQLgate -S -l zsql.log tcp:@ @:3950


=head1 AUTHOR

Mike Taylor E<lt>mike@miketaylor.org.ukE<gt>

First version Saturday 2nd February 2002.

=cut
