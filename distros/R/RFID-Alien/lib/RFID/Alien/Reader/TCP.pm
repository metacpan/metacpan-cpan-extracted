package RFID::Alien::Reader::TCP;
use RFID::Alien::Reader; $VERSION=$RFID::Alien::Reader::VERSION;
@ISA = qw(RFID::Alien::Reader RFID::Reader::TCP);

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004-2006 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::Alien::Reader::TCP - Implement L<RFID::Alien::Reader|RFID::Alien::Reader> over a TCP connection

=head1 SYNOPSIS

This class takes a host and port to connect to, connects to it, and
implements the Alien RFID protocol over that connection.  It can use
the reader's builting TCP service, or a serial-to-Ethernet adapter
plugged into the serial port of the reader; I tested it with both.

=cut

use strict;
use warnings;

use RFID::Reader::TCP;

=head1 DESCRIPTION

This class is built on top of
L<RFID::Alien::Reader|RFID::Alien::Reader> and
L<RFID::Reader::TCP|RFID::Reader::TCP>.

=cut

=head2 Constructor

=head3 new

This constructor accepts all arguments to the constructors for
L<RFID::Alien::Reader|RFID::Alien::Reader> and
L<RFID::Reader::TCP|RFID::Reader::TCP>, and passes them along to both
constructors.  Any other settings are intrepeted as parameters to the
L<set|RFID::Alien::Reader/set> method.

=cut

=head1 SEE ALSO

L<RFID::Alien::Reader>, L<RFID::Reader::TCP>,
L<RFID::Alien::Reader::Serial>, L<http://whereabouts.eecs.umich.edu/code/rfid-perl/>.

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2004-2006 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut

1;
