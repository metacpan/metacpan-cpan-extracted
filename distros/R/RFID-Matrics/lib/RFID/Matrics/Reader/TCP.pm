package RFID::Matrics::Reader::TCP;
@ISA = qw(RFID::Matrics::Reader RFID::Reader::TCP Exporter);
use RFID::Matrics::Reader; $VERSION=$RFID::Matrics::Reader::VERSION;
use RFID::Reader::TCP;
use Exporter;

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::Matrics::Reader::TCP - Implement L<RFID::Matrics::Reader|RFID::Matrics::Reader> over a TCP connection

=head1 SYNOPSIS

This class takes a host and port to connect to, connects to it, and
implements the Matrics RFID protocol over that connection.  It is
designed to use a serial-to-Ethernet adapter plugged into the serial
port of the reader; I tested it with the I<NPort Express> from Moxa.

An example:

    use RFID::Matrics::Reader::TCP;

    my $reader = 
      RFID::Matrics::Reader::TCP->new(PeerAddr => 1.2.3.4,
				      PeerPort => 4001,
				      Node => 4,
				      Antenna => MATRICS_ANT_1,
				      Debug => 1,
				      Timeout => CMD_TIMEOUT,
				      )
        or die "Couldn't create reader object.\n";

=head1 DESCRIPTION

This class is built on top of
L<RFID::Matrics::Reader|RFID::Matrics::Reader> and
L<RFID::Reader::TCP|RFID::Reader::TCP>.

=cut

our @EXPORT_OK = @RFID::Matrics::Reader::EXPORT_OK;
our %EXPORT_TAGS = %RFID::Matrics::Reader::EXPORT_TAGS;

=head2 Constructor

=head3 new

This constructor accepts all arguments to the constructor for
L<RFID::Reader::TCP|RFID::Reader::TCP>.  All other parameters are
passed along to L<the set method|RFID::Matrics::Reader/set>.

=cut

=head1 SEE ALSO

L<RFID::Matrics::Reader>, L<RFID::Reader::TCP>,
L<RFID::Matrics::Reader::Serial>,
L<http://www.eecs.umich.edu/~wherefid/code/rfid-perl/>.

=head1 AUTHOR

Scott Gifford <gifford@umich.edu>, <sgifford@suspectclass.com>

Copyright (C) 2004 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut

1;
