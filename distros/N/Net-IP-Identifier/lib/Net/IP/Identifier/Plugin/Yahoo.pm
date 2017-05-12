#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Yahoo
#     ABSTRACT:  identify Yahoo owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sun Oct 12 19:32:46 PDT 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::Yahoo;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known Yahoo IP blocks as of May 2015
    $self->ips(
        # 88 Network Blocks
        '8.3.34.0/23',
        '8.8.178.0/24',
        '27.123.32.0/19',
        # extending 27.123.196.0/23 to include 27.123.198.0/23
        # extending 27.123.196.0/22 to include 27.123.200.0/21
        '27.123.196.0-27.123.207.255',
        '46.228.32.0/20',
        '63.250.192.0/19',
        '64.56.160.0/19',
        '64.157.4.0/24',
        '66.94.224.0/19',
        '66.163.160.0/19',
        '66.218.64.0/19',
        '67.28.112.0/22',
        '67.72.118.0/23',
        '67.195.0.0/16',
        '68.180.128.0/17',
        '69.147.64.0/18',
        '76.13.0.0/16',
        '77.238.160.0/19',
        '87.248.96.0/19',
        '98.136.0.0/14',
        '103.2.12.0/22',
        # extending 106.10.128.0/18 to include 106.10.192.0/19
        '106.10.128.0-106.10.223.255',
        # extending 115.178.0.0/23 to include 115.178.2.0/23
        # extending 115.178.0.0/22 to include 115.178.4.0/23
        # extending 115.178.0.0-115.178.5.255 to include 115.178.6.0/23
        # extending 115.178.0.0/21 to include 115.178.8.0/23
        '115.178.0.0-115.178.9.255',
        '116.214.0.0/20',
        # extending 117.104.190.0/24 to include 117.104.191.0/24
        '117.104.190.0/23',
        '118.151.224.0/19',
        '119.160.240.0/20',
        '121.101.144.0/20',
        '124.108.64.0/21',
        '124.108.80.0/22',
        '124.108.86.0/23',
        # extending 124.108.90.0/23 to include 124.108.92.0/22
        # extending 124.108.90.0-124.108.95.255 to include 124.108.96.0/22
        '124.108.90.0-124.108.99.255',
        '180.222.96.0/20',
        # extending 180.233.112.0/22 to include 180.233.116.0/24
        # extending 180.233.112.0-180.233.116.255 to include 180.233.117.0/24
        # extending 180.233.112.0-180.233.117.255 to include 180.233.118.0/24
        # extending 180.233.112.0-180.233.118.255 to include 180.233.119.0/24
        '180.233.112.0/21',
        '182.22.0.0/17',
        '183.79.0.0/16',
        # extending 183.177.64.0/22 to include 183.177.68.0/22
        '183.177.64.0/21',
        '183.177.80.0/23',
        # extending 183.177.84.0/22 to include 183.177.88.0/23
        '183.177.84.0-183.177.89.255',
        '183.177.94.0/23',
        '184.165.0.0/16',
        '188.125.64.0/19',
        # absorbs:
        #    188.125.64.0/21
        #    188.125.72.0/21
        #    188.125.80.0/21
        '189.125.135.0/24',
        '193.93.196.0/22',
        '194.88.69.0/24',
        '202.4.164.0/24',
        '202.43.192.0/21',
        '202.46.19.0/24',
        '202.86.4.0/22',
        '202.160.176.0/20',
        '202.171.234.0/24',
        '202.174.4.0/24',
        '203.14.212.0/24',
        '203.83.216.0/23',
        '203.95.16.0/21',
        '203.99.254.0/24',
        '203.110.236.0/22',
        '203.141.32.0/20',
        '203.145.224.0/19',
        '203.188.192.0/20',
        '203.216.128.0/19',
        '206.3.0.0/19',
        '206.190.32.0/19',
        '207.126.224.0/20',
        '208.67.64.0/21',
        '208.71.40.0/21',
        '209.131.32.0/19',
        '209.191.64.0/18',
        '211.14.12.0/22',
        '211.14.20.0/22',
        '212.82.96.0/19',
        # absorbs:
        #    212.82.96.0/22
        #    212.82.100.0/22
        #    212.82.104.0/21
        '216.115.96.0/20',
        '216.145.48.0/20',
        '216.155.192.0/20',
        '216.252.96.0/19',
        '216.255.224.0/20',
        '217.12.0.0/20',
        '217.146.176.0/20',
        '217.163.20.0/23',
        '2001:df0:ed::/48',
        '2001:4998::/32',
        '2001:49a0::/32',
        '2400:7e00::/32',
        '2406:2000::/32',
        '2406:6e00::/32',
        '2406:8600::/32',
        '2804:1bc::/32',
        '2a00:1288::/32',
    );
    return $self;
}

sub name {
    return 'Yahoo';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Yahoo - identify Yahoo owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::Yahoo;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::Yahoo identifies Yahoo host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::Yahoo object.

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
