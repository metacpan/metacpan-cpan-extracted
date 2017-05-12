package SyslogScan::In_identdLine;

use SyslogScan::SyslogEntry;

$VERSION = 0.20;
sub Version { $VERSION };

@ISA = qw( SyslogScan::SyslogEntry );
use strict;

sub parseContent
{
    my ($self) = shift;

    # check that we have the tag
    die "no tag found in in_identd line $$self{content}" unless
	defined $$self{tag};
}

__END__

This is a handler for in.identd messages.  It doesn't currently do
anything useful, but is mainly a proof-of-concept placeholder showing
how a SyslogEntry subclass can provide a parseContent method.

Note this is a subclass for SyslogScan::SyslogEntry which handles
certain types of logfile lines.  See the documentation for SyslogEntry
for further details of how SyslogEntry subclassing works.
