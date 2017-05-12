package NetStumbler::Wap;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

#
# We do not Export anything
#
our $VERSION = '0.09';

=head1 Object Methods

=head2 new()

Returns a new Wap object. NOTE: this method may take some time to execute
as it loads the list into memory at construction time

=cut

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {} ;
    $self->{VENDORS} = {};
    bless ($self, $class);
    return $self;
}

sub initialize
{
    my $self = shift;
    while(<DATA>)
    {
	if(/END/)
	{
	    last;
	}
	chomp;
	my ($prefix,$ven) = split(/\t/);
	if($prefix && $prefix =~ /\w\w:\w\w:\w\w/i)
	{
		chomp($ven);
	    $self->{VENDORS}->{$prefix} = $ven;
	}
    }
}

=head2 isAdhoc($flags)

Params:
	-number 801.11 Capability flags
Returns:
	true is the flags indicate the access point is in adhoc mode
Example:
	if($obj->isAdhoc($flags))
	{
		# do something here
	}

=cut

sub isAdhoc
{

	my $self = shift;
	my $flags = shift;
	return $flags & 0x0002;
}

=head2 isInfrascruture($flags)

Params:
	-number 801.11 Capability flags
Returns:
	true is the flags indicate the access point is in infrastructure mode
Example:
	if($obj->isInfrascructure($flags))
	{
		# do something here
	}

=cut

sub isInfrastructure
{
	my $self = shift;
	my $flags = shift;
	return !isAdhoc($flags);
}

=head2 hasWEP($flags)

Params:
	-number 801.11 Capability flags
Returns:
	true is the flags indicate the access point has WEP enabled
Example:
	if($obj->hasWEP($flags))
	{
		# do something here
	}

=cut

sub isWEP
{
	my $self = shift;
	my $flags = shift;
	return $flags & 0x0010;
}


=head2 getVendorForBBSID ($mac)

Determine the vendor or a nic by the MAC prefix
The argument should be a mac address in the format of
00000000000
or
00:00:00:00:00:00

C<getVendorForBBSID> will return the vendor or undef
if the mac address could not be translated to a vendor

=cut

sub getVendorForBBSID
{
    my $self = shift;
    my $mac = shift;
    if(length($mac) > 12)
    {
	my $prefix = substr($mac,0,8);
    	return $self->{VENDORS}->{uc($prefix)};
    }
    else
    {
    	my $prefix = substr($mac,0,2) . ":" . substr($mac,2,2) . ":" . substr($mac,4,2);
    	return $self->{VENDORS}->{uc($prefix)};
    }
}
1;
__DATA__
00:00:00	Xerox
00:00:01	Xerox
00:00:02	Xerox
00:00:03	Xerox
00:00:04	Xerox
00:00:05	Xerox
00:00:06	Xerox
00:00:07	Xerox
00:00:08	Xerox
00:00:09	Xerox
00:00:0C	Cisco
00:00:95	Ericsson/Sony
00:00:AA	Xerox
00:00:E2	Acer
00:00:E8	Accton
00:00:F0	Samsung
00:00:FF	Camtec
00:01:02	3Com
00:01:03	3Com
00:01:24	Acer
00:01:42	Cisco
00:01:43	Cisco
00:01:4A	Ericsson/Sony
00:01:4C	Berkeley
00:01:63	Cisco
00:01:64	Cisco
00:01:96	Cisco
00:01:97	Cisco
00:01:C7	Cisco
00:01:C9	Cisco
00:01:EC	Ericsson/Sony
00:01:F4	Enterasys (Cabletron)
00:01:F9	Global
00:02:07	Global
00:02:16	Cisco
00:02:17	Cisco
00:02:2D	Proxim (Agere)ORiNOCO
00:02:4A	Cisco
00:02:4B	Cisco
00:02:6F	Senao
00:02:7D	Cisco
00:02:7E	Cisco
00:02:88	Global
00:02:8A	Ambit
00:02:9C	3Com
00:02:A5	Compaq
00:02:B3	Intel
00:02:B9	Cisco
00:02:BA	Cisco
00:02:DD	Bormax
00:02:EE	Nokia
00:02:FC	Cisco
00:02:FD	Cisco
00:03:2F	Global
00:03:31	Cisco
00:03:32	Cisco
00:03:47	Intel
00:03:6B	Cisco
00:03:6C	Cisco
00:03:93	Apple
00:03:9F	Cisco
00:03:A0	Cisco
00:03:E3	Cisco
00:03:E4	Cisco
00:03:FD	Cisco
00:03:FE	Cisco
00:03:FF	Microsoft
00:04:0B	3Com
00:04:0D	Avaya
00:04:1F	Ericsson/Sony
00:04:25	Atmel
00:04:27	Cisco
00:04:28	Cisco
00:04:31	Global
00:04:4D	Cisco
00:04:4E	Cisco
00:04:5A	Linksys
00:04:6D	Cisco
00:04:6E	Cisco
00:04:9A	Cisco
00:04:9B	Cisco
00:04:C0	Cisco
00:04:C1	Cisco
00:04:C6	Yamaha
00:04:DD	Cisco
00:04:DE	Cisco
00:04:E2	SMC
00:04:E3	Accton
00:05:00	Cisco
00:05:01	Cisco
00:05:02	Apple
00:05:1A	3Com
00:05:31	Cisco
00:05:32	Cisco
00:05:3C	Xircom
00:05:3D	Proxim (Agere)ORiNOCO
00:05:5D	D-Link
00:05:5E	Cisco
00:05:5F	Cisco
00:05:73	Cisco
00:05:74	Cisco
00:05:75	CDS
00:05:86	Lucent (WaveLAN)
00:05:9A	Cisco
00:05:9B	Cisco
00:05:DC	Cisco
00:05:DD	Cisco
00:06:25	Linksys
00:06:28	Cisco
00:06:2A	Cisco
00:06:52	Cisco
00:06:53	Cisco
00:06:6E	Delta(Netgear)
00:06:7C	Cisco
00:06:8C	3Com
00:06:C1	Cisco
00:06:D6	Cisco
00:06:D7	Cisco
00:06:EB	Global
00:07:0D	Cisco
00:07:0E	Cisco
00:07:4F	Cisco
00:07:50	Cisco
00:07:84	Cisco
00:07:85	Cisco
00:07:B3	Cisco
00:07:B4	Cisco
00:07:E9	Intel
00:07:EB	Cisco
00:07:EC	Cisco
00:08:02	Compaq
00:08:0F	Proxim(WaveLAN)
00:08:20	Cisco
00:08:21	Cisco
00:08:7C	Cisco
00:08:7D	Cisco
00:08:A3	Cisco
00:08:A4	Cisco
00:08:C2	Cisco
00:08:C7	Compaq
00:08:E2	Cisco
00:08:E3	Cisco
00:09:11	Cisco
00:09:12	Cisco
00:09:43	Cisco
00:09:44	Cisco
00:09:5B	Netgear
00:09:7B	Cisco
00:09:7C	Cisco
00:09:B6	Cisco
00:09:B7	Cisco
00:09:E1	Gemtek
00:09:E8	Cisco
00:09:E9	Cisco
00:0A:04	3Com
00:0A:27	Apple
00:0A:41	Cisco
00:0A:42	Cisco
00:0A:5E	3Com
00:0A:8A	Cisco
00:0A:8B	Cisco
00:0A:95	Apple
00:0A:B7	Cisco
00:0A:B8	Cisco
00:0A:D9	Ericsson/Sony
00:0A:E9	AirVast
00:0A:F3	Cisco
00:0A:F4	Cisco
00:0B:45	Cisco
00:0B:46	Cisco
00:0B:5F	Cisco
00:0B:60	Cisco
00:0B:89	Global
00:0B:AC	3Com
00:0B:BE	Cisco
00:0B:BF	Cisco
00:0B:C5	SMC
00:0B:CD	Compaq
00:0B:FC	Cisco
00:0B:FD	Cisco
00:0B:FF	Berkeley
00:0C:1E	Global
00:0C:30	Cisco
00:0C:31	Cisco
00:0C:41	Linksys
00:0C:85	Cisco
00:0C:86	Cisco
00:0C:CA	Global
00:0C:CC	Bluesoft
00:0C:CE	Cisco
00:0C:CF	Cisco
00:0C:F1	Intel
00:0D:28	Cisco
00:0D:29	Cisco
00:0D:3A	Microsoft
00:0D:54	3Com
00:0D:65	Cisco
00:0D:66	Cisco
00:0D:72	2Wire
00:0D:88	D-Link
00:0D:93	Apple
00:0D:B5	Global
00:0D:BC	Cisco
00:0D:BD	Cisco
00:0D:EC	Cisco
00:0D:ED	Cisco
00:0E:07	Ericsson/Sony
00:0E:0C	Intel
00:0E:35	Intel
00:0E:38	Cisco
00:0E:39	Cisco
00:0E:6A	3Com
00:0E:83	Cisco
00:0E:84	Cisco
00:0E:D6	Cisco
00:0E:D7	Cisco
00:0E:ED	Nokia
00:0F:23	Cisco
00:0F:24	Cisco
00:0F:34	Cisco
00:0F:35	Cisco
00:0F:3D	D-Link
00:0F:5B	Delta(Netgear)
00:0F:66	Cisco
00:0F:8F	Cisco
00:0F:90	Cisco
00:0F:B3	Premax(Actiontec)
00:0F:B5	Netgear
00:0F:CB	3Com
00:0F:DE	Ericsson/Sony
00:0F:E2	3Com
00:0F:F7	Cisco
00:0F:F8	Cisco
00:10:07	Cisco
00:10:0B	Cisco
00:10:0D	Cisco
00:10:11	Cisco
00:10:14	Cisco
00:10:1F	Cisco
00:10:29	Cisco
00:10:2F	Cisco
00:10:4B	3Com
00:10:54	Cisco
00:10:5A	3Com
00:10:79	Cisco
00:10:7A	Ambicom
00:10:7B	Cisco
00:10:A4	Xircom
00:10:A6	Cisco
00:10:B3	Nokia
00:10:B5	Accton
00:10:E3	Compaq
00:10:E7	BreezeNet
00:10:F6	Cisco
00:10:FF	Cisco
00:11:11	Intel
00:11:20	Cisco
00:11:21	Cisco
00:11:24	Apple
00:20:14	Global
00:20:7B	Intel
00:20:88	Global
00:20:A6	Proxim(WaveLAN)
00:20:AF	3Com
00:20:D8	NetWave-Bay
00:20:E0	Premax(Actiontec)
00:26:54	3Com
00:30:19	Cisco
00:30:1E	3Com
00:30:24	Cisco
00:30:40	Cisco
00:30:65	Apple
00:30:6D	Lucent (WaveLAN)
00:30:71	Cisco
00:30:78	Cisco
00:30:7B	Cisco
00:30:80	Cisco
00:30:85	Cisco
00:30:94	Cisco
00:30:96	Cisco
00:30:98	Global
00:30:A3	Cisco
00:30:AB	Delta(Netgear)
00:30:B6	Cisco
00:30:B8	Delta(Netgear)
00:30:BD	Belkin
00:30:F1	Accton
00:30:F2	Cisco
00:40:05	Ani
00:40:0B	Cisco
00:40:27	SMC
00:40:33	Addtron
00:40:36	Zoom-Tribe
00:40:43	Nokia
00:40:96	Aironet
00:40:AE	Delta(Netgear)
00:50:04	3Com
00:50:0B	Cisco
00:50:0F	Cisco
00:50:14	Cisco
00:50:18	Adv
00:50:2A	Cisco
00:50:3E	Cisco
00:50:50	Cisco
00:50:53	Cisco
00:50:54	Cisco
00:50:73	Cisco
00:50:80	Cisco
00:50:8B	Compaq
00:50:98	Global
00:50:99	3Com
00:50:A0	Delta(Netgear)
00:50:A2	Cisco
00:50:A7	Cisco
00:50:BA	D-Link
00:50:BD	Cisco
00:50:D1	Cisco
00:50:DA	3Com
00:50:E2	Cisco
00:50:E4	Apple
00:50:F0	Cisco
00:50:F2	Microsoft
00:50:F3	Global
00:60:08	3Com
00:60:09	Cisco
00:60:1D	Lucent (WaveLAN)
00:60:2F	Cisco
00:60:3E	Cisco
00:60:47	Cisco
00:60:5C	Cisco
00:60:67	Acer
00:60:70	Cisco
00:60:83	Cisco
00:60:8C	3Com
00:60:97	3Com
00:60:B3	Z-Com
00:60:D2	Lucent (WaveLAN)
00:80:37	Ericsson/Sony
00:80:5F	Compaq
00:80:C7	Xircom
00:80:C8	D-Link
00:90:04	3Com
00:90:0C	Cisco
00:90:0E	Handlink
00:90:21	Cisco
00:90:27	Intel
00:90:2B	Cisco
00:90:4B	Gemtek
00:90:4D	Gemtek
00:90:5F	Cisco
00:90:6C	Global
00:90:6D	Cisco
00:90:6F	Cisco
00:90:86	Cisco
00:90:92	Cisco
00:90:A6	Cisco
00:90:AB	Cisco
00:90:B1	Cisco
00:90:BF	Cisco
00:90:D1	Addtron
00:90:D9	Cisco
00:90:E6	Acer
00:90:F2	Cisco
00:A0:24	3Com
00:A0:40	Apple
00:A0:60	Acer
00:A0:8E	Nokia
00:A0:C9	Intel
00:A0:DE	Yamaha
00:A0:F8	Symbol
00:AA:00	Intel
00:AA:01	Intel
00:AA:02	Intel
00:B0:4A	Cisco
00:B0:64	Cisco
00:B0:8E	Cisco
00:B0:C2	Cisco
00:C0:03	Global
00:C0:49	U.S. Robotics
00:C0:AC	Ambit
00:D0:06	Cisco
00:D0:58	Cisco
00:D0:59	Ambit
00:D0:63	Cisco
00:D0:77	Lucent (WaveLAN)
00:D0:79	Cisco
00:D0:90	Cisco
00:D0:96	3Com
00:D0:97	Cisco
00:D0:9E	2Wire
00:D0:AB	Delta(Netgear)
00:D0:B7	Intel
00:D0:BA	Cisco
00:D0:BB	Cisco
00:D0:BC	Cisco
00:D0:C0	Cisco
00:D0:D3	Cisco
00:D0:D8	3Com
00:D0:E4	Cisco
00:D0:FF	Cisco
00:E0:03	Nokia
00:E0:14	Cisco
00:E0:1E	Cisco
00:E0:34	Cisco
00:E0:38	Proxim(WaveLAN)
00:E0:4F	Cisco
00:E0:78	Berkeley
00:E0:85	Global
00:E0:8F	Cisco
00:E0:A3	Cisco
00:E0:B0	Cisco
00:E0:E4	U.S. Robotics
00:E0:F7	Cisco
00:E0:F9	Cisco
00:E0:FE	Cisco
02:60:8C	3Com
02:C0:8C	3Com
08:00:05	Symbol
08:00:07	Apple
08:00:37	Xerox
08:00:46	Ericsson/Sony
08:00:4E	3Com
08:00:72	Xerox
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

NetStumbler::Wap - Wap tools for NetStumbler

=head1 SYNOPSIS

  use NetStumbler::Wap;
  my $waplib = NetStumbler::Wap->new();
  my $vendor = $waplib->getVendorForBBSID("mac address");

=head1 DESCRIPTION

 This module stores a list of mac prefixes for various wireless cards
 It was built for use with NetStumbler/Kismet/iStumbler etc... to help
 with vendor mac discovery
 
=head2 EXPORT

None by default.

=head1 SEE ALSO

http://idogan.istanbul.edu.tr/oui_full.html OUI database
All the items in this list were generated by parsing the oui database

=head1 AUTHOR

Salvatore E. ScottoDiLuzio<lt>washu@olypmus.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Salvatore ScottoDiLuzio

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
