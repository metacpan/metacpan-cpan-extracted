package SyslogScan::UnsupportedEntry;

$VERSION = 0.20;
sub Version { $VERSION };
@ISA = qw (SyslogScan::SyslogEntry);
use strict;

sub parseContent
{
    my ($self) = shift;
}

__END__

This class handles syslog lines which were created programs which are
not specifically handled by any other SyslogEntry subclasses.

Note this is a subclass for SyslogScan::SyslogEntry which handles
certain types of logfile lines.  See the documentation for SyslogEntry
for further details of how SyslogEntry subclassing works.
