package RFID::Matrics::Reader::Test;
use RFID::Matrics::Reader; $VERSION=$RFID::Matrics::Reader::VERSION;
use RFID::Reader::TestBase;
@ISA=qw(RFID::Reader::TestBase RFID::Matrics::Reader);

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::Matrics::Reader::Test - A fake implementation of L<RFID::Matrics::Reader|RFID::Matrics::Reader> for testing

=head1 SYNOPSIS

Provides fake backend methods to test out
L<RFID::Matrics::Reader|RFID::Matrics::Reader> without having access
to a real reader.  Inherits from
L<RFID::Reader::TestBase|RFID::Reader::TestBase>.

=cut

use RFID::Matrics::Reader qw(hexdump);

our %TESTRESPONSE = 
    (
     # Start constant read

     # Stop constant read
     hex2bin('01 04 05 26 0a 45') 
       => hex2bin('01 04 06 25 00 6b 9a'),
     
     # Get parameter block
     hex2bin('01 04 06 24 a0 b9 26') 
       => hex2bin('01 04 26 24 00 ff 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 8a f6'),

     # Set parameter block
     hex2bin('01 04 29 23 01 00 00 00 ff 04 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 bf 9e')
       => hex2bin('01 04 06 23 00 bb ce'),

     # Get node address
     hex2bin('01 ff 0d 19 af 03 00 00 00 00 00 00 af 8f')
       => hex2bin('01 04 06 19 00 69 85'),
     
     # Get node status
     hex2bin('01 04 05 14 9b 57')
       => hex2bin('01 04 26 14 00 af 03 00 00 00 00 00 00 02 01 02 00 00 00 00 00 01 01 00 00 00 00 00 00 00 00 00 00 00 00 e7 0f e4 6f'),

     # Read tags
     hex2bin('01 04 06 22 a0 69 72')
       => hex2bin('01 04 35 22 01 a0 05 00 de 09 96 00 a8 07 05 c8 02 02 c4 76 01 00 00 00 00 02 02 c0 76 01 00 00 00 00 02 02 bc 76 01 00 00 00 00 02 02 bc 76 01 00 00 00 00 5a 0b')
        . hex2bin('01 04 0c 22 00 05 00 23 00 00 00 81 e9'),
     );

sub new
{
    my $class = shift;
    my(%p)=@_;
    my $self = {};
    bless $self,$class;
    
    # Initialize everything.
    foreach my $parent (@ISA)
    {
	if (my $init = $parent->can('_init'))
	{
	    $init->($self,%p);
	}
    }

    $self;
}

sub _process_input
{
    my $self = shift;
    my($buf)=@_;

    if ($buf =~ /^\x01.(.)/o)
    {
	my $pktsize = ord($1)+1;
	if (length($buf) >= ($pktsize))
	{
	    my $resp = $TESTRESPONSE{substr($buf,0,$pktsize,'')}
  	        or die "Test module received invalid input: ",hexdump $buf,"\n";
	    $self->_add_output($resp);
	}
    }
    $buf;
}

sub hex2bin
{
    my $hex = $_[0];
    $hex =~ tr/0-9a-fA-F//cd;
    pack("C*",map { hex } unpack("a2"x(length($hex)/2),$hex));
}
    
1;

=head1 SEE ALSO

L<RFID::Matrics::Reader>, L<RFID::Matrics::Reader::Serial>,
L<RFID::Matrics::Reader::TCP>, L<RFID::Reader::TestBase>.

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2004 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut

1;
