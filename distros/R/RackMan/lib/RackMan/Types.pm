package RackMan::Types;

use strict;
use warnings;

use File::Basename;
use Path::Class;
use RackMan;


my %racktables2rackman = (
    "BlackBox"          => "BlackBox",
    "CableOrganizer"    => "CableOrganizer",
    "console"           => "Console",
    "DiskArray"         => "DiskArray",
    "FC switch"         => "FCSwitch",
    "KVM switch"        => "KVMSwitch",
    "MediaConverter"    => "MediaConverter",
    "Modem"             => "Modem",
    "multiplexer"       => "Multiplexer",
    "Network chassis"   => "NetworkChassis",
    "Network security"  => "NetworkSecurity",
    "Network switch"    => "Switch",
    "PatchPanel"        => "PatchPanel",
    "PDU"               => "PDU",
    "Power supply"      => "PowerSupply",
    "Power supply chassis"  => "PowerSupplyChassis",
    "Router"            => "Router",
    "Server"            => "Server",
    "Server chassis"    => "ServerChassis",
    "Server Ext"        => "ServerExt",
    "Shelf"             => "Shelf",
    "spacer"            => "Spacer",
    "TapeLibrary"       => "TapeLibrary",
    "UPS"               => "UPS",
    "VM"                => "VM",
    "VM Cluster"        => "VMCluster",
    "VM Resource Pool"  => "VMResourcePool",
    "VM Virtual Switch" => "VMVirtualSwitch",
    "Voice/video"       => "VoiceVideo",
    "Wireless"          => "Wireless",
);

my %rackman2racktables = reverse %racktables2rackman;
my %lowercase2racktables
    = map { lc $racktables2rackman{$_} => $_ } keys %racktables2rackman;


#
# enum()
# ----
sub enum {
    return keys %rackman2racktables
}

#
# from_racktables()
# ---------------
sub from_racktables {
    my ($self, $type) = @_;
    RackMan->error("unknown type '$type'") unless $racktables2rackman{$type};
    return $racktables2rackman{$type}
}


#
# to_racktables()
# -------------
sub to_racktables {
    my ($self, $type) = @_;
    RackMan->error("unknown type '$type'")
        if not $rackman2racktables{$type} and not $lowercase2racktables{$type};
    return $rackman2racktables{$type} || $lowercase2racktables{$type}
}


#
# implemented()
# -----------
sub implemented {
    my $dir = file(__FILE__)->dir->subdir("Device");
    my $dh = $dir->open or RackMan->error("can't read directory '$dir': $!");
    my @modules = map { s/\.pm$//; $_ } grep /\.pm$/, $dh->read;
    return @modules
}


__PACKAGE__

__END__

=pod

=head1 NAME

RackMan::Types - RackTables <-> RackMan types translation

=head1 DESCRIPTION

This module contains methods to translate RackTables types into RackMan
types (classes) and vice versa. It is mostly for internal RackMan use.


=head1 METHODS

All methods are class methods

=head2 enum

Return the list of all RackMan types.

=head2 implemented

Return the list of implemented RackMan types.

=head2 from_racktables

Translate a RackTables type to a RackMan type.

=head2 to_racktables

Translate a RackMan type to a RackTables type.


=head1 AUTHOR

Sebastien Aperghis-Tramoni (sebastien@aperghis.net)

=cut

