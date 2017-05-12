package Regexp::Log::Progress;

use strict;
use warnings;

our $VERSION = '0.03';

1;

__END__

=head1 NAME

Regexp::Log::Progress - A set of regex's to parse Progress log files

=head1 SYNOPSIS

This module is primiarly for documentation. For how to initialize and
use these modules, please refer to L<Regexp::Log>.

=head1 DESCRIPTION

These modules provide a set of regex's to parse various Progress OpenEdge
log files. As of 10.2B, the default format for a Progress log line is as 
follows:

 [06/10/31@14:07:15.892-0400] P-002702 T-002867 2 4GL DYNOBJECTS message

Where:

 * 06/10/31 - is the date in yy/mm/dd format
 * 14:07:15.892 - is the time in hh:mm:ss.mls
 * 0400 - is the time zone, expressed as the number of hours relative to GMT
 * 002702 - is the process ID
 * 002867 - is the thread ID
 * 2 - is the logging level associated with this log entry
 * 4GL - is the execution environment
 * DYNOBJECTS - is the log entry type
 * message - the rest is the log message

This has been broken down into these named fields:

 datetime pid tid level process facility message

These selectors have been defined to select specific fields:

 %datetime $pid %tid %level %process %facility %message

For the most part each field is space delimited, but of course this "standard"
is violated at will. Especially the datetime field and some "message" fields 
have a message number associated with them. This can be captured with the 
"msgnum" field and the "%msgnum" selector.

There are five main types of log files. Each follows this standard in some
fashion, to support this, there are five additional modules. One for each log 
file type.

=over 4

=item L<Regexp::Log::Progress::Broker>

=item L<Regexp::Log::Progress::Server>

=item L<Regexp::Log::Progress::Database>

=item L<Regexp::Log::Progress::NameServer>

=item L<Regexp::Log::Progress::AdminServer>

=back

=head1 SEE ALSO

=over 4

=item L<Regexp::Log>

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc Regexp::Log::Progress

=head1 AUTHOR

Kevin L. Esteb, C<< <kesteb at wsipc.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 WSIPC.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
