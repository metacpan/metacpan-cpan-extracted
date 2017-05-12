#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Microsoft
#     ABSTRACT:  identify Microsoft (AS8075) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sun Oct 12 19:32:46 PDT 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::Microsoft;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known Microsoft (AS8075) IP blocks as of May 2015
    $self->ips(
        # 100 Network Blocks
        '8.6.176.0/24',
        # extending 13.64.0.0/11 to include 13.96.0.0/13
        # extending 13.64.0.0-13.103.255.255 to include 13.104.0.0/14
        '13.64.0.0-13.107.255.255',
        '23.96.0.0/13',
        '40.64.0.0/10',
        '42.159.0.0/16',
        '64.4.0.0/18',
        '64.41.193.0/24',
        '65.52.0.0/14',
        '65.221.5.0/24',
        '66.119.144.0/20',
        # extending 70.37.0.0/17 to include 70.37.128.0/18
        '70.37.0.0-70.37.191.255',
        '70.42.230.0/23',
        '94.245.64.0/18',
        '103.9.8.0/22',
        '104.40.0.0/13',
        '104.146.0.0/15',
        '104.208.0.0/13',
        '111.221.16.0/21',
        '111.221.64.0/18',
        '125.16.28.0/24',
        '131.107.0.0/16',
        '131.253.1.0/24',
        '131.253.3.0/24',
        # extending 131.253.5.0/24 to include 131.253.6.0/24
        '131.253.5.0-131.253.6.255',
        '131.253.8.0/24',
        # extending 131.253.12.0/22 to include 131.253.16.0/23
        # extending 131.253.12.0-131.253.17.255 to include 131.253.18.0/24
        '131.253.12.0-131.253.18.255',
        # extending 131.253.21.0/24 to include 131.253.22.0/23
        # extending 131.253.21.0-131.253.23.255 to include 131.253.24.0/21
        # extending 131.253.21.0-131.253.31.255 to include 131.253.32.0/20
        '131.253.21.0-131.253.47.255',
        # extending 131.253.61.0/24 to include 131.253.62.0/23
        # extending 131.253.61.0-131.253.63.255 to include 131.253.64.0/18
        # extending 131.253.61.0-131.253.127.255 to include 131.253.128.0/17
        '131.253.61.0-131.253.255.255',
        '132.245.0.0/16',
        '134.170.0.0/16',
        '137.116.0.0/16',
        '137.135.0.0/16',
        '138.91.0.0/16',
        # extending 157.54.0.0/15 to include 157.56.0.0/14
        # extending 157.54.0.0-157.59.255.255 to include 157.60.0.0/16
        '157.54.0.0-157.60.255.255',
        # extending 167.220.0.0/17 to include 167.220.128.0/18
        # extending 167.220.0.0-167.220.191.255 to include 167.220.192.0/19
        '167.220.0.0-167.220.223.255',
        # extending 168.61.0.0/16 to include 168.62.0.0/15
        '168.61.0.0-168.63.255.255',
        '190.210.77.0/24',
        # extending 191.232.0.0/14 to include 191.236.0.0/14
        '191.232.0.0/13',
        '192.48.225.0/24',
        '192.84.159.0/24',
        '192.92.90.0/24',
        '192.92.214.0/24',
        '192.197.157.0/24',
        '193.149.64.0/19',
        '193.221.113.0/24',
        '194.69.96.0/19',
        '194.121.59.0/24',
        '198.49.8.0/24',
        '198.105.232.0/22',
        # extending 198.180.95.0/24 to include 198.180.96.0/23
        '198.180.95.0-198.180.97.255',
        '198.200.130.0/24',
        '198.206.164.0/24',
        '199.2.137.0/24',
        '199.30.16.0/20',
        '199.60.28.0/24',
        '199.74.210.0/24',
        '199.103.90.0/23',
        '199.103.122.0/24',
        # extending 199.242.32.0/20 to include 199.242.48.0/21
        '199.242.32.0-199.242.55.255',
        # extending 202.89.224.0/21 to include 202.89.232.0/21
        '202.89.224.0/20',
        '202.159.8.0/24',
        '203.124.0.0/22',
        '204.14.180.0/22',
        '204.79.135.0/24',
        # extending 204.79.179.0/24 to include 204.79.180.0/23
        '204.79.179.0-204.79.181.255',
        # extending 204.79.195.0/24 to include 204.79.196.0/23
        '204.79.195.0-204.79.197.255',
        '204.79.252.0/24',
        '204.95.96.0/20',
        '204.152.140.0/23',
        '204.182.144.0/20',
        # extending 204.231.194.0/23 to include 204.231.196.0/22
        # extending 204.231.194.0-204.231.199.255 to include 204.231.200.0/21
        # extending 204.231.194.0-204.231.207.255 to include 204.231.208.0/20
        '204.231.194.0-204.231.223.255',
        '204.231.236.0/24',
        '206.73.203.0/24',
        '206.191.224.0/19',
        '207.46.0.0/16',
        '207.68.128.0/18',
        '208.68.136.0/21',
        '208.76.44.0/22',
        '208.84.0.0/21',
        '209.1.15.0/24',
        '209.185.128.0/22',
        '209.240.192.0/19',
        '213.146.167.0/24',
        # extending 213.146.188.0/24 to include 213.146.189.0/24
        '213.146.188.0/23',
        '213.199.128.0/18',
        '216.32.180.0/22',
        '216.32.240.0/22',
        '216.33.240.0/22',
        '216.34.51.0/24',
        '216.220.208.0/20',
        '2001:df0:7::/48',
        '2001:df0:d7::/48',
        # extending 2001:4898::/31 to include 2001:489a::/32
        '2001:4898:0000:0000:0000:0000:0000:0000-2001:489a:ffff:ffff:ffff:ffff:ffff:ffff',
        '2404:f800::/31',
        '2603:1000::/24',
        '2620:0:30::/45',
        '2620:b4:4000::/48',
        '2620:1ec::/36',
        '2801:80:1d0::/48',
        '2a01:110::/31',
    );
    return $self;
}

sub name {
    return 'Microsoft';
}

sub children {
    return qw( Hotmail );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Microsoft - identify Microsoft (AS8075) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::Microsoft;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::Microsoft identifies Microsoft (AS8075) host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::Microsoft object.

=back

=head1 SEE ALSO

=over

=item IP::Net

=item IP::Net::Identifier

=item IP::Net::Identifier_Role

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
