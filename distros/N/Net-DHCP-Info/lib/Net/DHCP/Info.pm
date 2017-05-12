package Net::DHCP::Info;

=head1 NAME

Net::DHCP::Info - Fast dhcpd.leases and dhcpd.conf parser

=head1 NOTE

=head2 DEPRECATED

This module is not very flexible, and not maintained.
Use L<Net::ISC::DHCPd> instead.

=head1 VERSION

Version 0.11

=head1 SYNOPSIS

    use Net::DHCP::Info;

    my $conf  = Net::DHCP::Info->new($path_to_dhcpd_conf);
    my $lease = Net::DHCP::Info->new($path_to_dhcpd_leases);

    while(my $net = $conf->fetch_subnet) {
        # .. do stuff with $net
    }

    while(my $lease = $lease->fetch_lease) {
        # .. do stuff with $lease
    }

=cut

use strict;
use warnings;
use Net::DHCP::Info::Obj;

our $VERSION     = '0.12';
our $FIND_NET    = qr{^([^s]*)subnet\s+([\d\.]+)\s+netmask\s+([\d\.]+)};
our $ROUTERS     = qr{^\W*option\s+routers\s+([\d\.\s]+)};
our $RANGE       = qr{^\W*range\s+([\d\.]+)\s*([\d\.]*)};
our $FIND_LEASE  = qr{^lease\s([\d\.]+)};
our $STARTS      = qr{^\W+starts\s\d+\s(.+)};
our $ENDS        = qr{^\W+ends\s\d+\s(.+)};
our $HW_ETHERNET = qr{^\W+hardware\sethernet\s(.+)};
our $REMOTE_ID   = qr{option\sagent.remote-id\s(.+)};
our $BINDING     = qr{^\W+binding\sstate\s(.+)};
our $HOSTNAME    = qr{^\W+client-hostname\s\"([^"]+)\"};
our $CIRCUIT_ID  = qr{^\W+option\sagent.circuit-id\s(.+)};
our $END         = qr{^\}$};

my %stash;

=head2 METHODS

=head2 new($file)

Object constructor. Takes one argument; a filename to parse. This can be
either a dhcpd.conf or dhcpd.leases file.

=cut

sub new {
    my $class = shift;
    my $file  = shift;

    if(ref $file eq 'GLOB') {
        return bless $file, $class;
    }
    else {
        return 'file does not exist'  unless(-f $file);
        return 'file is not readable' unless(-r $file);
        open(my $self, '<', $file) or return $!;
        return bless $self, $class;
    }
}

=head2 fetch_subnet

This method returns an object of the C<Net::DHCP::Info::Obj> class.

=cut

sub fetch_subnet {
    my $self = shift;
    my $tab  = "";
    my $net;

    FIND_NET:
    while(readline $self) {
        if(my($tab, @ip) = /$FIND_NET/mx) {
            $net = Net::DHCP::Info::Obj->new(@ip);
            last FIND_NET;
        }
    }

    READ_NET:
    while(readline $self) {

        s/\;//mx;

        if(/$ROUTERS/mx) {
            $net->routers([ split /\s+/mx, $1 ]);
        }
        elsif(my @net = /$RANGE/mx) {
            $net[1] = $net[0] unless($net[1]);
            $net->add_range(\@net);
        }
        elsif(/$tab\}/mx) {
            last READ_NET;
        }
    }

    return ref $net ? $net : undef;
}

=head2 fetch_lease

This method returns an object of the C<Net::DHCP::Info::Obj> class.

=cut

sub fetch_lease {
    my $self = shift;
    my $lease;

    FIND_LEASE:
    while(readline $self) {
        if(my($ip) = /$FIND_LEASE/mx) {
            $lease = Net::DHCP::Info::Obj->new($ip);
            last FIND_LEASE;
        }
    }

    READ_LEASE:
    while(readline $self) {

        s/\;//mx;

        if(/$STARTS/mx) {
            $lease->starts($1);
        }
        elsif(/$ENDS/mx) {
            $lease->ends($1);
        }
        elsif(/$HW_ETHERNET/mx) {
            $lease->mac( fixmac($1) );
        }
        elsif(/$REMOTE_ID/mx) {
            $lease->remote_id( fixmac($1) );
        }
        elsif(/$CIRCUIT_ID/mx) {
            $lease->circuit_id( fixmac($1) );
        }
        elsif(/$BINDING/mx) {
            $lease->binding($1);
        }
        elsif(/$HOSTNAME/mx) {
            $lease->hostname($1);
        }
        elsif(/$END/mx) {
            last READ_LEASE;
        }
    }

    return ref $lease ? $lease : undef;
}

=head1 FUNCTIONS

=head2 fixmac

Takes a mac in various formats as an argument, and returns it as a 12 char
string.

=cut

sub fixmac {
    my $mac = shift;

    $mac =  unpack('H*', $mac) if($mac =~ /[\x00-\x1f]/mx);
    $mac =~ y/a-fA-F0-9\://cd;
    $mac =  join "", map {
                             my $i = 2 - length($_);
                             ($i < 0) ? $_ : ("0" x $i) .$_;
                         } split /:/mx, $mac;

    return $mac;
}

sub DESTROY {
    my $self = shift;
    delete $stash{$self};
}

=head1 AUTHOR

Jan Henning Thorsen, C<< <pm at flodhest.net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jan Henning Thorsen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
