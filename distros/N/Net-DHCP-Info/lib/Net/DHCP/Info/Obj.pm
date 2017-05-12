package Net::DHCP::Info::Obj;

=head1 NAME

Net::DHCP::Info::Obj - Storage module for dhcp-information

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

This module contains methods that can access the data C<Net::DHCP::Info>
has extracted. It inherits from C<NetAddr::IP>, so it provides all the methods
from that package as well.

=head1 SYNOPSIS

    use Net::DHCP::Info::Obj;

    my $ip  = "127.0.0.1";
    my $obj = Net::DHCP::Info::Obj->new($ip);

    $obj->mac("aa:b:02:3d:0:01");

    print $obj->mac; # prints the above mac

=cut

use strict;
use warnings;
use DateTime;
use NetAddr::IP;

our @ISA     = qw/NetAddr::IP/;
our $VERSION = '0.01';
our $AUTOLOAD;

=head1 METHODS

=head2 binding

Returns the dhcp leases binding.

=head2 circuit_id

Returns the dhcp leases circuit id.

=head2 hostname

Returns the client-hostname

=head2 mac

Returns the dhcp leases mac.

=head2 range

Returns a list of ranges in a subnet in this format:

[$low_ip, $high_ip]

=head2 remote_id

Returns the dhcp leases remote id.

=head2 routers

Returns a list of routers in a subnet.

=cut
 
BEGIN { ## no critic # for strict
    my @keys = qw/
                   circuit_id binding ends hostname
                   mac range remote_id routers starts
               /;

    no strict 'refs';

    for my $k (@keys) {
        *$k = sub {
            my $self = shift;
            $self->{$k} = $_[0] if(defined $_[0]);
            $self->{$k};
        }
    }
}

=head2 add_range

=cut

sub add_range {
    my $self  = shift;
    my $range = shift;

    return unless(ref $range eq 'ARRAY');

    push @{ $self->{'range'} }, $range;
    return;
}

=head2 starts

=head2 starts_datetime

Returns the dhcp leases start time as string / DateTime object.

=cut

sub starts_datetime {
    my $self = shift;
    return $self->_datetime($self->starts);
}

=head2 ends

=head2 ends_datetime

Returns the dhcp leases end time as string / DateTime object.

=cut

sub ends_datetime {
    my $self = shift;
    return $self->_datetime($self->ends);
}

sub _datetime {

    ### init
    my $self = shift;
    my @time = split m"[\s\:/]"mx, shift;

    return DateTime->new(
        year      => $time[0],
        month     => $time[1],
        day       => $time[2],
        hour      => $time[3],
        minute    => $time[4],
        second    => $time[5],
        time_zone => 'UTC',
    );
}

=head1 AUTHOR

Jan Henning Thorsen, C<< <pm at flodhest.net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jan Henning Thorsen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
