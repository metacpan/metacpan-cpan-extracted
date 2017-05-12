#
# NetPacket::LLC - Decode and encode IEEE Logical Link Layer 
#
# Comments/suggestions to cganesan@cpan.org
#

package NetPacket::LLC;

#
# Copyright (c) 2002 Chander Ganesan.
#
# This package is free software and is provided "as is" without express 
# or implied warranty.  It may be used, redistributed and/or modified 
# under the terms of the Perl Artistic License (see
# http://www.perl.com/perl/misc/Artistic.html)
#
# This software and all associated data and documentation
# ('Software') is available free of charge.  You may make copies of the 
# Software but you must include all of this notice on any copy.
#
# The Software was developed for research purposes does not
# warrant that it is error free or fit for any purpose.  The author
# disclaims any liability for all claims, expenses, losses, damages
# and costs any user may incur as a result of using, copying or
# modifying the Software.
#

use 5.006;
use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

my $myclass;
BEGIN {
    $myclass = __PACKAGE__;
    $VERSION = "0.01";
}
sub Version () { "$myclass v$VERSION" }

BEGIN {
    @ISA = qw(Exporter NetPacket);

# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)

    @EXPORT = qw(
    );

# Other items we are prepared to export if requested

    @EXPORT_OK = qw(llc_strip 
                    );

# Tags:

    %EXPORT_TAGS = (
    ALL         => [@EXPORT, @EXPORT_OK],
    strip       => [qw(llc_strip)],
    types       => [qw(
                       )],
);

}

#
# Decode the packet
#

sub decode {
    my $class = shift;
    my($pkt, $parent, @rest) = @_;
    my $self = {};

    # Class fields

    $self->{_parent} = $parent;
    $self->{_frame} = $pkt;

    # Decode LLC data

    if (defined($pkt)) {
         ($self->{dsap},$self->{ssap}, $self->{control},
          $self->{data}) = 
	    unpack('H2H2B8a*' , $pkt);
    }

    # Return a blessed object

    bless($self, $class);
    return $self;
}

#
# Strip header from data and return the data contained in it
#

undef &llc_strip;        # Create llc_strip alias
*llc_strip = \&strip;

sub strip {
    my ($pkt, @rest) = @_;
    my $llc_obj = NetPacket::LLC->decode($pkt);
    return $llc_obj->{data};;
}   

#
# Encode a packet - now implemented!
#

sub encode {
    my ($self, $data) = @_;
    my $defaults = {
        dsap => undef,
        ssap => undef,
        control => undef,
        data => undef,
    };

    my $packStruct = {
        1 => { 'dsap' => 'H2' },
        2 => { 'ssap' => 'H2' },
        3 => { 'control' => 'B8' },
        4 => { 'data' => 'a*' },
    };

    #
    # Ensure all required parameters are passed, and those that aren't
    # are defaulted.
    #
    foreach my $name (keys %$defaults) {
        if (defined $data->{$name}) {
            next;
        } else {
            if (defined $defaults->{$name}) { # we have a defaults
                $data->{$name} = $defaults->{$name};
            } else {
                die "$name parameter is required to encode LLC\n";
            }
        }
    }

    #
    # Encode the data
    #
    my $packed_data = "";
    foreach my $key (sort { $a <=> $b } keys %$packStruct) {
        foreach my $subkey (keys %{$packStruct->{$key}}) {
            $packed_data .= pack ($packStruct->{$key}{$subkey},
                                  $data->{$subkey});
        }
    }
    return $packed_data;
}

#
# Module return value
#
1;

# autoloaded methods go after the END token (&& pod) below

__END__
=head1 NAME

C<NetPacket::LLC> - Assemble and disassemble IEEE 802.3 LLC protocol packets.

=head1 SYNOPSIS

 use NetPacket::LLC;
 use NetPacket::SpanningTree;

 $llc_data = NetPacket::Ethernet->strip($raw_packet);
 $st_data = NetPacket::LLC->strip($llc_data);
 $st_obj = NetPacket::SpanningTree->decode($st_data);

=head1 DESCRIPTION

C<NetPacket::LLC> provides a set of routines for assembling and
disassembling packets using the IEEE standard LLC protocol layer.  

=head2 Methods

=over 

=item C<NetPacket::LLC-E<gt>decode([ST DATA])>

Decode the LLC packet data and return an object containing instance
data.  This method will probably decode garbage input, but it won't mean
much.

=item C<NetPacket::SpanningTree-E<gt>encode($st_hash)>

Encode the hash into a raw data stream that may be appended to ethernet 
packet data.  This allows the user to create his/her own LLC
protocol packet and subsequently send it out on the wire (though sending on 
the wire isn't a function of this module).

=back

=head2 Functions

=over

=item C<NetPacket::LLC-E<gt>strip([LLC DATA])>

Strip the LLC data from the packet, and return any underlying data.

=back

=head2 Instance data

The instance data contains in the hash returned by the encode and decode methodsof the C<NetPacket::LLC> module contain the following fields.  Note,
please refer to the IEEE spec for a description of these fields.  They
are not described in detail here unless relevant to encoding.  

=over

=item max_age

    
=item message_age

=item bpdu_flags

=item bridge_id 



=back

=head2 Exports

=over

=item exportable

llc_strip

=item tags

The following tags group together related exportable items.

=over

=item C<:strip>

Import the strip function C<st_strip>

=item C<:ALL>

All the above exportable items

=back

=back

=head1 EXAMPLE

The following is a script that listens on device "eth1" for spanning
tree packets.  It then decodes the packets, re-encodes them, and
verifies that the both the original and re-encoded data are identical. 
It uses tLLC module to decode the LLC layer.

#!/usr/bin/perl -w
#
# Perl script to verify that Spanning Tree packet intervals are correct
#
#
#

use strict;
use Net::PcapUtils;
use NetPacket::Ethernet;
use NetPacket::LLC;
use NetPacket::SpanningTree;


{
    my $iface = "eth1";
    my $errmsg = Net::PcapUtils::loop(\&process_pkt, 
                                      DEV => $iface );
    if (defined $errmsg) { die "$errmsg\n"; }
}


sub process_pkt {
    my ($arg, $hdr, $pkt)  = @_;
    my $eth_obj = NetPacket::Ethernet->decode($pkt);

    if ((defined $eth_obj->{length}) && 
        ($eth_obj->{dest_mac} =~ m/^0180c200000/)) { # Spanning Tree protocol
        my $llc_obj = NetPacket::LLC->decode($eth_obj->{data});
        my $st_obj = NetPacket::SpanningTree->decode($llc_obj->{data});
        verifyEncoding($st_obj);

        my $newdata = NetPacket::SpanningTree->encode($st_obj);
        return;
    }
 }

#
# Decode a packet and compare it to a hash of data to be encoded.
#
# Input is a hash of data to be encoded.  The subroutine encodes and
# subsequently decodes the data and verifies the data matches.
#

sub verifyEncoding {
    my ($st_obj) = @_;
    my $newdata = 
        NetPacket::SpanningTree->encode($st_obj);
    my $st_obj1 = 
        NetPacket::SpanningTree->decode($newdata);
    foreach my $key (keys %$st_obj) {
        if ($key =~ m/data/i) { next; }
        if ($key =~ m/frame/i) { next; }
        if ($key =~ m/_parent/i) { next; }
        if ($st_obj->{$key} eq $st_obj1->{$key}) {
            print "$key is identical ($st_obj1->{$key})\n";
        } else {
            print 
                "$key is $st_obj->{$key} before $st_obj1->{$key} after\n";
        }
    }
 }

=head1 TODO

=over

=item Better documentation

=item Clean up some code.

=back

=head1 SEE ALSO

=over

=item C<NetPacket::LLC>

    Module to decode LLC packets (Logical Link Control)

=item C<NetPacket::Ethernet>

    Module to decode Ethernet Packets

=item C<Net::RawIP>

    Module to send encoded data out.

=item C<Net::PcapUtils>

    Utility module to be used for packet capture.
    
=back


=head1 COPYRIGHT

Copyright (c) 2002 Chander Ganesan.

This package is free software and is provided "as is" without express 
or implied warranty.  It may be used, redistributed and/or modified 
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

This software and all associated data and documentation
('Software') is available free of charge.  You may make copies of the 
Software but you must include all of this notice on any copy.

The Software was developed for research purposes does not
warrant that it is error free or fit for any purpose.  The author
disclaims any liability for all claims, expenses, losses, damages
and costs any user may incur as a result of using, copying or
modifying the Software.

=head1 AUTHOR

Chander Ganesan E<lt>cganesan@cpan.org<gt>

=cut
