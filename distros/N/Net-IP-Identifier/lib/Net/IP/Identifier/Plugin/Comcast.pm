#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Comcast
#     ABSTRACT:  identify Comcast owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Thu Nov  6 11:03:17 PST 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::Comcast;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known Comcast IP blocks as of May 2015
    $self->ips(
        # 89 Network Blocks
        '12.41.68.0/22',
        '12.109.232.0/22',
        '23.24.0.0/15',
        '23.30.0.0/15',
        '23.68.0.0/14',
        # extending 24.0.0.0/12 to include 24.16.0.0/13
        '24.0.0.0-24.23.255.255',
        # extending 24.30.0.0/18 to include 24.30.64.0/19
        # extending 24.30.0.0-24.30.95.255 to include 24.30.96.0/19
        '24.30.0.0/17',
        '24.34.0.0/16',
        # extending 24.40.0.0/18 to include 24.40.64.0/20
        '24.40.0.0-24.40.79.255',
        '24.60.0.0/14',
        '24.91.0.0/16',
        '24.98.0.0/15',
        # extending 24.104.0.0/17 to include 24.104.128.0/19
        '24.104.0.0-24.104.159.255',
        '24.118.0.0/16',
        # extending 24.124.128.0/17 to include 24.125.0.0/16
        # extending 24.124.128.0-24.125.255.255 to include 24.126.0.0/15
        # extending 24.124.128.0-24.127.255.255 to include 24.128.0.0/16
        # extending 24.124.128.0-24.128.255.255 to include 24.129.0.0/17
        '24.124.128.0-24.129.127.255',
        '24.130.0.0/15',
        '24.147.0.0/16',
        '24.149.128.0/17',
        '24.153.64.0/19',
        '24.218.0.0/16',
        '24.245.0.0/18',
        '50.73.0.0/16',
        '50.76.0.0/14',
        '50.128.0.0/9',
        '64.56.32.0/19',
        '64.78.64.0/18',
        '64.139.64.0/19',
        '64.235.160.0/19',
        '65.34.128.0/17',
        # extending 65.96.0.0/16 to include 65.97.0.0/19
        '65.96.0.0-65.97.31.255',
        '66.30.0.0/15',
        '66.41.0.0/16',
        '66.56.0.0/18',
        '66.176.0.0/15',
        '66.208.192.0/18',
        '66.229.0.0/16',
        '66.240.0.0/18',
        '67.160.0.0/11',
        '68.32.0.0/11',
        '68.80.0.0/13',
        '69.136.0.0/13',
        '69.180.0.0/15',
        '69.240.0.0/12',
        '70.88.0.0/14',
        '71.24.0.0/14',
        '71.56.0.0/13',
        '71.192.0.0/12',
        '71.224.0.0/12',
        '72.55.0.0/17',
        '73.0.0.0/8',
        '74.16.0.0/12',
        '74.81.128.0/19',
        '74.92.0.0/14',
        '74.144.0.0/12',
        # extending 75.64.0.0/13 to include 75.72.0.0/15
        # extending 75.64.0.0-75.73.255.255 to include 75.74.0.0/16
        # extending 75.64.0.0-75.74.255.255 to include 75.75.0.0/17
        # extending 75.64.0.0-75.75.127.255 to include 75.75.128.0/18
        '75.64.0.0-75.75.191.255',
        '75.144.0.0/13',
        '76.16.0.0/12',
        # extending 76.96.0.0/11 to include 76.128.0.0/11
        '76.96.0.0-76.159.255.255',
        # extending 96.64.0.0/11 to include 96.96.0.0/12
        # extending 96.64.0.0-96.111.255.255 to include 96.112.0.0/13
        # extending 96.64.0.0-96.119.255.255 to include 96.120.0.0/14
        # extending 96.64.0.0-96.123.255.255 to include 96.124.0.0/16
        '96.64.0.0-96.124.255.255',
        # extending 96.128.0.0/10 to include 96.192.0.0/11
        '96.128.0.0-96.223.255.255',
        '98.32.0.0/11',
        '98.192.0.0/10',
        # extending 107.0.0.0/14 to include 107.4.0.0/15
        '107.0.0.0-107.5.255.255',
        '108.171.224.0/20',
        '147.191.0.0/16',
        '162.17.0.0/16',
        '162.148.0.0/14',
        '165.137.0.0/16',
        '169.152.0.0/16',
        '172.244.0.0/16',
        '173.8.0.0/13',
        '173.160.0.0/13',
        '174.48.0.0/12',
        '174.160.0.0/11',
        # extending 184.108.0.0/14 to include 184.112.0.0/12
        '184.108.0.0-184.127.255.255',
        '198.0.0.0/16',
        '198.137.252.0/23',
        '198.178.8.0/21',
        '199.182.100.0/22',
        '206.18.184.0/24',
        '207.223.0.0/20',
        '208.39.128.0/18',
        '208.110.192.0/19',
        '209.23.192.0/18',
        '216.45.128.0/17',
        # extending 2001:558::/31 to include 2001:55a::/31
        # extending 2001:558::/30 to include 2001:55c::/30
        '2001:558::/29',
        '2601::/20',
        '2604:6a00::/32',
        '2620:fd:8000::/48',
    );
    return $self;
}

sub name {
    return 'Comcast';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Comcast - identify Comcast owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::Comcast;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::Comcast identifies Comcast host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::Comcast object.

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
