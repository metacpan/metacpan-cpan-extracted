#
# NetPacket::SpanningTree - Decode and encode spanning tree protocol packets
#
# Comments/suggestions to cganesan@cpan.org
#

package NetPacket::SpanningTree;

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

    @EXPORT_OK = qw(st_strip 
                    );

# Tags:

    %EXPORT_TAGS = (
    ALL         => [@EXPORT, @EXPORT_OK],
    strip       => [qw(st_strip)],
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

    # Decode Spanning Tree packet

    if (defined($pkt)) {
        my ($root_pri, $bridge_pri, $port_pri, $port_num, $root_path_cost,
            $message_age, $max_age, $bpdu_type, 
            $fwd_delay, $hello_time ,
            $root_mac, $bridge_mac, $version, $version_length);
        
	($self->{protocol_id}, $version, $bpdu_type, 
         $self->{bpdu_flags},
         $root_pri, $self->{root_mac}, $self->{root_path_cost},
         $bridge_pri, $bridge_mac, $port_pri, $port_num, 
         $message_age, $max_age, $hello_time, $fwd_delay, $version_length) = 
             unpack('nH2H2a1H4H12NH4H12H2H2nnnnH2' , $pkt);
#        print "unpacked: " . unpack ("H*" ,  $pkt) . "\n";
        $self->{protocol_version} = hex($version);
        $self->{bpdu_type} = hex ($bpdu_type);
        if ($self->{bpdu_type} != 128) { # This isn't a topology change...
            if ($self->{bpdu_type} == 2) { # Rapid...
                my ($prole1, $prole2);
                $self->{version_1_length} = hex($version_length);
                ($self->{topology_change_ack},
                 $self->{agreement},
                 $self->{forwarding},
                 $self->{learning},
                 $prole1,
                 $prole2,
                 $self->{proposal},
                 $self->{topology_change}) = 
                     split //, unpack ("B*", $self->{bpdu_flags});
                $self->{port_role} = $prole1*2 + $prole2; 
            } elsif ($self->{bpdu_type} == 0) {
                ($self->{topology_change_ack}, 
                 undef, undef, undef, undef, undef, undef, 
                 $self->{topology_change}) = 
                     split //, unpack ("B*", $self->{bpdu_flags});
            }
            $self->{data} = undef;
            $self->{root_priority} = hex($root_pri);
            $self->{root_id} = $root_pri . $self->{root_mac};
            $self->{bridge_id} = $bridge_pri . $bridge_mac;
            $self->{bridge_priority} = hex($bridge_pri);
            $self->{bridge_mac} = $bridge_mac;
            $self->{port_priority} = hex($port_pri);
            $self->{port_num} = hex($port_num);
            $self->{port_id} = sprintf("%02lx%02lx", hex($port_pri) , hex($port_num));
            
            
            $self->{bpdu_flags} = unpack ("B*", $self->{bpdu_flags});
            
            $self->{message_age} = $message_age/256;
            $self->{max_age} = $max_age/256;
            $self->{forward_delay} = $fwd_delay/256;
            $self->{hello_time} = $hello_time/256;
        }
    }
    # Return a blessed object
    
    bless($self, $class);
    return $self;
}

#
# Strip header from packet and return the data contained in it.  Spanning
# Tree packets contain no encapsulated data.
#

undef &st_strip;        # Create st_strip alias
*st_strip = \&strip;

sub strip {
    return undef;
}   

#
# Encode a packet
#

sub encode {
    my ($self, $data) = @_;
    my $defaults = {
        protocol_id => 0,
        protocol_version => 0,
        bpdu_type => 0,
        topology_change_ack => 1,
        root_priority => 32768,
        bridge_priority => 32768,
        port_priority => 128,
        port_num => 1,
        root_mac => "000000000000",
        root_path_cost => 10,
        bridge_mac => "000000000000",
        message_age => 0,
        max_age => 20,
        hello_time => 2,
        forward_delay => 15,
        topology_change => 0,
    };

    my $packStruct = {
        1 => { 'protocol_id' => 'n' },
        2 => { 'protocol_version' => 'H2' },
        3 => { 'bpdu_type' => 'H2' },
        4 => { 'bpdu_flags' => 'B8' },
        5 => { 'root_priority' => 'n' },
        6 => { 'root_mac' => 'H12' },
        7 => { 'root_path_cost' => 'N', },
        8 => { 'bridge_priority' => 'n', },
        9 => { 'bridge_mac' => 'H12', },
        10 => { 'port_id' => 'H4', },
        12 => { 'message_age' => 'n', },
        13 => { 'max_age' => 'n', },
        14 => { 'hello_time' => 'n', },
        15 => { 'forward_delay' => 'n', },
    };


    #
    # Ensure all required parameters are passed, and those that aren't
    # are defaulted.
    #
    foreach my $name (keys %$defaults) {
        if (defined $data->{$name}) {
            next;
        } else {
            if (defined $defaults->{$name}) { # We have a default...
                $data->{$name} = $defaults->{$name};
            } else {
                die "$name parameter is required to encode spanning tree\n";
            }    
        }
    }


    $data->{bpdu_type} = sprintf("%02lx", $data->{bpdu_type});
    if ($data->{bpdu_type} eq "80") { # topo change notification
        return pack("nH2H2", $data->{protocol_id}, 
                    $data->{protocol_version},
                    $data->{bpdu_type});
    }
    
    #
    # Build a port ID from the number and priority.
    #

    $data->{port_id} = sprintf("%02lx%02lx", 
                               $data->{port_priority}, 
                               $data->{port_num});
    #
    # Build the Bridge PDU flags. 
    #
    if ($data->{bpdu_type} == 0) {
        $data->{bpdu_flags} = $data->{topology_change_ack} . "000000" . 
            $data->{topology_change};
    } elsif ($data->{bpdu_type} == 2) {
        my $prole2=$data->{port_role} % 2; 
        my $prole1=int ($data->{port_role}/2);
        $data->{bpdu_flags} = $data->{topology_change_ack} . 
            $data->{agreement} .
            $data->{forwarding} .
            $data->{learning} .
            $prole1 .
            $prole2 .
            $data->{proposal} .
            $data->{topology_change};
    }

    #
    # Invert the message age for encoding.
    #

    foreach my $name qw(message_age hello_time max_age forward_delay) {
        $data->{$name} = $data->{$name} * 256;
    }

    my $packed_data = "";
    foreach my $key (sort { $a <=> $b; } keys %$packStruct) {
        foreach my $subkey (keys %{$packStruct->{$key}}) {
            $packed_data .= pack ($packStruct->{$key}{$subkey}, 
                                  $data->{$subkey});
        }
    }

    if ($data->{bpdu_type} == 2) { # Rapid Spanning Tree
        my $len = sprintf("%02lx", $data->{version_1_length});
        $packed_data .= pack('H2', $len);
    }

    #
    # Put back the message age.
    #
    foreach my $name qw(message_age hello_time max_age forward_delay) {
        $data->{$name} = $data->{$name} / 256;
    }
    $data->{bpdu_type} = hex ($data->{bpdu_type});
    return $packed_data;
}

#
# Module return value
#
1;

# autoloaded methods go after the END token (&& pod) below

__END__

=head1 NAME

C<NetPacket::SpanningTree> - Assemble and disassemble IEEE 802.1D Spanning
Tree protocol packets.

=head1 SYNOPSIS

 use NetPacket::LLC;
 use NetPacket::SpanningTree;

 $llc_data = NetPacket::Ethernet->strip($raw_packet);
 $st_data = NetPacket::LLC->strip($llc_data);
 $st_obj = NetPacket::SpanningTree->decode($st_data);

=head1 DESCRIPTION

C<NetPacket::SpanningTree> provides a set of routines for assembling and
disassembling packets using the IEEE standard Spanning Tree Protocol.  
Spanning Tree is a layer 2 protocol defined by the IEEE 802.1D
specification.

=head2 Methods

=over

=item C<NetPacket::SpanningTree-E<gt>decode([ST DATA])>

Decode the spanning tree packet data and return an object containing instance
data.  This method will probably decode garbage input, but it won't mean
much.

=item C<NetPacket::SpanningTree-E<gt>encode($st_hash)>

Encode the hash into a raw data stream that may be appended to LLC data, then to an ethernet packet.  This allows the user to create his/her own Spanning Tree
protocol packet and subsequently send it out on the wire (though sending on 
the wire isn't a function of this application).

=back

=head2 Functions

=over

=item C<NetPacket::SpanningTree-E<gt>strip([ST DATA])>

Strip the spanning tree data from the packet, and return any underlying data.
This returns undef since there is no "data" per say included in the spanning
tree packet.

=back

=head2 Instance data

The instance data contains in the hash returned by the encode and decode methodsof the C<NetPacket::SpanningTree> module contain the following fields.  Note,
please refer to the IEEE spec for a description of these fields.  They
are not described in detail here unless relevant to encoding.  When available, values not suppiled will be set to IEEE 802.1D defaults.

=over

=item max_age
    
=item message_age

=item bpdu_flags

    A single octet, representing the topology change flag (TC) (LSB) and the
    topology change notification acknowledgement (TCA) (MSB).  This parameter
    is contructed when encoding, please refer to the TC and TCA items to set 
    the appropriate bits.
 
=item bridge_mac

    This (along with bridge_priority) is used to build the bridge_id when encoding.

=item bpdu_type



=item topology_change



=item bridge_priority

    This (along with bridge_mac) is used to build the bridge_id when encoding.

=item topology_change_ack 



=item protocol_version 

    This value should always be 0, defaults to 0.  Note, this value also
    contains the message type (which is also always 0).

=item forward_delay 



=item hello_time 



=item port_num 



=item root_priority

    This (along with root_mac) is used to build the root_id when encoding.

=item root_path_cost

=item protocol_id

    This value should always be 0, defaults to 0.

=item root_mac 

    This (along with root_priority) is used to build the root_id when encoding.

=item port_priority 

    This (along with port_num) is used to build the port_id when encoding.

=item root_id



=item port_id



=item bridge_id 



=back

=head2 Exports

=over

=item exportable

st_strip

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

#!/usr/bin/perl -w
#
# Perl script to verify that LACP packet intervals are correct
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
