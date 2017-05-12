#
# NetPacket::LACP - Decode and encode Link Aggregation Control Protocol
# packets
#
# Comments/suggestions to cganesan@cpan.org
#

package NetPacket::LACP;

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

    @EXPORT_OK = qw(lacp_strip 
                    );

# Tags:

    %EXPORT_TAGS = (
    ALL         => [@EXPORT, @EXPORT_OK],
    strip       => [qw(lacp_strip)],
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

    # Decode LACP packet

    #
    # Here's the format of the packet.  We can pass this in to unpack to
    # unpack it...
    #

    #
    # Perform hex to decimal conversions on these fields..
    #
    my @convert_from_hex = qw(version partner_info_length
                              collector_info_length 
                              actor_info_length);
    my $lacp_contents = _get_decoder();
    
    if (defined($pkt)) {
        my ($key, $rest);
        $rest = $pkt;
        foreach $key (sort numerically keys %$lacp_contents) {
            foreach (keys %{$lacp_contents->{$key}}) {
                ($self->{$_}, $rest) = unpack($lacp_contents->{$key}{$_} .
                                              "a*", $rest);
            }
        }


        ($self->{AS_expired},
         $self->{AS_defaulted},
         $self->{AS_distributing},
         $self->{AS_collecting},
         $self->{AS_synchronization},
         $self->{AS_aggregation},
         $self->{AS_lacp_timeout},
         $self->{AS_lacp_activity}) = split "", $self->{AS};         

    
        ($self->{PS_expired},
         $self->{PS_defaulted},
         $self->{PS_distributing},
         $self->{PS_collecting},
         $self->{PS_synchronization},
         $self->{PS_aggregation},
         $self->{PS_lacp_timeout},
         $self->{PS_lacp_activity}) = split "", $self->{PS};

        #
        # Perform hex to decimal conversion where necessary.
        #

        foreach (@convert_from_hex) {
            $self->{$_} = hex($self->{$_});
        }
    }
    # Return a blessed object
    return undef unless ($self->{version} == 1); # Verion 1 is LACP..    
    bless($self, $class);
    return $self;
}

#
# Strip header from packet and return the data contained in it.  Spanning
# Tree packets contain no encapsulated data.
#

undef &lacp_strip;        # Create st_strip alias
*lacp_strip = \&strip;

sub strip {
    return undef;
}   

#
# Encode a packet
#

sub encode {
    my ($class, $data)= @_;
    my $self = {};
    my $pkt;
    # Encode LACP packet

    #
    # Set some sensible defaults
    #
    my $defaults = {
        'lacp' => '01' ,
        'version' => '01' ,
        'actor_info' => '01' ,
        'actor_info_length' => '20' ,
        'actor_system_priority' => '25600' ,
        'actor_system' => '000000000000' ,
        'actor_key' => '193' ,
        'actor_port_priority' => '0' ,
        'actor_port' => '1' ,
        'reserved_1' => '0' x 6 ,
        'partner_info' => '02' ,
        'partner_info_length' => '20' ,
        'partner_system_priority' => '0' ,
        'partner_system' => '000000000000' ,
        'partner_key' => '0' ,
        'partner_port_priority' => '0' ,
        'partner_port' => '1' ,
        'reserved_2' => '0' x 6 ,
        'collector_info' => '03' ,
        'collector_info_length' => '16' ,
        'collector_max_delay' => '10000' ,
        'reserved_3' => '0' x 24 ,
        'terminator_info' => '00' ,
        'terminator_length' => '00' ,
        'reserved_4' => '0' x 100,
    };        

    foreach (keys %$defaults) {
        if (! defined $data->{$_}) {
            $data->{$_} = $defaults->{$_};
        }
    }
    #
    # Perform decimal to hex conversions on these fields..
    #
    my @convert_from_hex = qw(version partner_info_length
                              collector_info_length 
                              actor_info_length);
    my $lacp_contents = _get_decoder();
    
    #
    # Perform decimal to hex conversion where necessary.
    #
    foreach (@convert_from_hex) {
        $data->{$_} = sprintf("%02lx", $data->{$_});
    }
    
    $data->{AS} = join "", $data->{AS_expired},
                            $data->{AS_defaulted},
                            $data->{AS_distributing},
                            $data->{AS_collecting},
                            $data->{AS_synchronization},
                            $data->{AS_aggregation},
                            $data->{AS_lacp_timeout},
                            $data->{AS_lacp_activity};


    $data->{PS} = join "", $data->{PS_expired},
                            $data->{PS_defaulted},
                            $data->{PS_distributing},
                            $data->{PS_collecting},
                            $data->{PS_synchronization},
                            $data->{PS_aggregation},
                            $data->{PS_lacp_timeout},
                            $data->{PS_lacp_activity};
    
    #
    # Encode the data...
    #

    my ($key, $rest);
    $rest = $pkt;
    foreach $key (sort numerically keys %$lacp_contents) {
        foreach (keys %{$lacp_contents->{$key}}) {
            $pkt .= pack($lacp_contents->{$key}{$_}, 
                         $data->{$_});
        }
    }

    #
    # Perform hex to decimal conversion where necessary.
    #
    foreach (@convert_from_hex) {
        $data->{$_} = hex($data->{$_});
    }
    return $pkt;
}

sub _get_decoder {
    return {
        0 => { 'lacp' => 'H2' },
        1 => { 'version' => 'H2' },
        2 => { 'actor_info' => 'H2' },
        3 => { 'actor_info_length' => 'H2' },
        4 => { 'actor_system_priority' => 'n' },
        5 => { 'actor_system' => 'H12' },
        6 => { 'actor_key' => 'n' },
        7 => { 'actor_port_priority' => 'n' },
        8 => { 'actor_port' => 'n' },
        10 => { 'AS' => 'B8' },
        17 => { 'reserved_1' => 'H6' },
        18 => { 'partner_info' => 'H2' },
        19 => { 'partner_info_length' => 'H2' },
        20 => { 'partner_system_priority' => 'n' },
        21 => { 'partner_system' => 'H12' },
        22 => { 'partner_key' => 'n' },
        23 => { 'partner_port_priority' => 'n' },
        24 => { 'partner_port' => 'n' },
        25 => { 'PS' => 'B8' },
        33 => { 'reserved_2' => 'H6' },
        34 => { 'collector_info' => 'H2' },
        35 => { 'collector_info_length' => 'H2' },
        36 => { 'collector_max_delay' => 'n' },
        37 => { 'reserved_3' => 'H24' },
        38 => { 'terminator_info' => 'H2' },
        39 => { 'terminator_length' => 'H2' },
        40 => { 'reserved_4' => 'H100' },
    };
}
#
# provided for sorting.
#
sub numerically {
    $a <=> $b;
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
