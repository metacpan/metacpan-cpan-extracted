package Tail::Stat;

=head1 NAME

Tail::Stat - Real-time log statistics server

=cut


use strict;
use warnings qw(all);

our $VERSION = '0.26';


=head1 ABSTRACT

It's often necessary to collect some statistics data for following
analysis or processing. Common case are various monitoring tools,
like a MRTG, Nagios or Zabbix. Some services may be examined by special
commands or protocols, other may not. But often, information we are interested in
can be extracted from server logs. This software helps
to extract, accumulate and provide this information to monitoring
tool via simple, easy parseable protocol.


=head1 ARCHITECTURE

Tail::Stat has a plugin structure. Each plugin supports logs processing
for a specific service. Main executable (called I<tstatd>) works as a
long running background process (daemon) with TCP listen socket for
querying about collected statistics. There is no any configuration files,
all required parameters tstatd takes from command line options.
One running instance of tstatd can process many similar log files
simultaneously. It agregates extracted parameters into I<zones>.
Zones are just namespaces for grouping this values.
For collecting parameters from other kind of service you have to run
other instance of tstatd.


=head1 TYPE OF VALUES

Fundamentally all measured values can be separated into two principally
different groups: I<counters> and I<gauges>.
For example, processing web-server logs we want to calculate two parameters:
total processed HTTP requests and average time elapsed per request.
The first goal can be achieved by simple incremented counter, but the second
is a little harder. We have to summarize elapsed times and then divide this
amount onto request count. But we have to do this for a small time slot
(usually comparable with our monitoring tool polling interval).
This kind of calculations is supported by Tail::Stat and calls I<sliding windows>
calculations. Tail::Stat operate with a set of a small windows.
First window (called I<current>) accumulates current data.
After a fixed period of time (C<--window-size>) a window is closing (special
handler executing), new window creating and setting as current and last of closed
windows is removing. Total number of windows can be adjusted by special option
(C<--windows-num>). For example: our monitoring tool has a polling interval
about 10 minutes (600 seconds). We want to provide it average response time
for last 600 seconds respectively. Appropriate window size can be set
as 10 seconds with keeping values for 60 windows (and this are default values).


=head1 CLIENT PROTOCOL

Querying accumulated data is available via simple TCP-based protocol.
Protocol is line oriented (like an HTTP or SMTP).

=head2 zones

Prints list of known zones. Zones specified via command line options marked
with 'a:' prefix (active). Zones restored from a database file, but not
found in command options marked with 'i:' prefix (inactive).

=head2 globs I<zone>

Prints list of globs (wildcards) associated with I<zone>. Applicable only
to active zones.

=head2 files I<zone>

Prints list of files currently processing for I<zone>. Each file prefixed by
current reading offset and size of file. Applicable only to active zones.

=head2 wipe I<zone>|*

Wipes out an inactive I<zone> or all inactive zones. Applicable only to inactive
zones.

=head2 dump I<zone>

Prints out raw I<zone> statistics.

=head2 stats I<zone>

Prints out formatted I<zone> statistics.

=head2 quit

Closes client connection.


=head1 BUGS

Please report any bugs or feature requests to C<bug-tail-stat at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tail-Stat>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tail::Stat

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tail-Stat>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tail-Stat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tail-Stat>

=item * Search CPAN

L<http://search.cpan.org/dist/Tail-Stat/>

=back


=head1 AUTHOR

Oleg A. Mamontov, C<< <oleg@mamontov.net> >>


=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


1;

