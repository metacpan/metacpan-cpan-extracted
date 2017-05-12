#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Amazon
#     ABSTRACT:  identify Amazon owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sun Nov 16 17:18:54 PST 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::Amazon;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known Amazon  IP blocks as of May 2015
    # AS9059 AS8987 AS7224 AS58588 AS39111 AS38895 AS17493 AS16509 AS14618 AS10124
    $self->ips(
        # 43 Network Blocks
        # extending 8.18.144.0/24 to include 8.18.145.0/24
        '8.18.144.0/23',
        '23.20.0.0/14',
        '27.0.0.0/22',
        '46.51.128.0/17',
        '46.137.0.0/16',
        '50.16.0.0/14',
        '50.112.0.0/16',
        '52.0.0.0/11',
        # extending 54.64.0.0/13 to include 54.72.0.0/13
        # extending 54.64.0.0/12 to include 54.80.0.0/12
        '54.64.0.0/11',
        # extending 54.144.0.0/12 to include 54.160.0.0/12
        # extending 54.144.0.0-54.175.255.255 to include 54.176.0.0/12
        # extending 54.144.0.0-54.191.255.255 to include 54.192.0.0/12
        # extending 54.144.0.0-54.207.255.255 to include 54.208.0.0/13
        # extending 54.144.0.0-54.215.255.255 to include 54.216.0.0/14
        # extending 54.144.0.0-54.219.255.255 to include 54.220.0.0/15
        '54.144.0.0-54.221.255.255',
        # extending 54.224.0.0/12 to include 54.240.0.0/12
        '54.224.0.0/11',
        '67.202.0.0/18',
        '72.21.192.0/19',
        '72.44.32.0/19',
        '75.101.128.0/17',
        '79.125.0.0/17',
        '87.238.80.0/21',
        '96.127.0.0/17',
        '103.246.148.0/22',
        '107.20.0.0/14',
        '122.248.192.0/18',
        '174.129.0.0/16',
        '176.32.64.0/18',
        '176.34.0.0/16',
        '178.236.0.0/20',
        '184.72.0.0/15',
        '184.169.128.0/17',
        '185.48.120.0/22',
        '199.127.232.0/22',
        '199.255.192.0/22',
        '203.83.220.0/22',
        '204.236.128.0/17',
        '204.246.160.0/19',
        '205.251.192.0/18',
        '207.171.160.0/19',
        '216.137.32.0/19',
        '216.182.224.0/20',
        '2400:6500::/32',
        '2403:b300::/32',
        '2406:da00::/24',
        '2620:107:3000::/44',
        '2620:108:7000::/44',
        '2a01:578::/32',
    );
    return $self;
}

sub name {
    return 'Amazon';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Amazon - identify Amazon owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::Amazon;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::Amazon identifies Amazon (AS9059 AS8987
AS7224 AS58588 AS39111 AS38895 AS17493 AS16509 AS14618 AS10124) IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::Amazon object.

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
