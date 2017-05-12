#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::LeaseWeb
#     ABSTRACT:  identify LeaseWeb owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Fri Mar 27 11:10:01 PDT 2015
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::LeaseWeb;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known LeaseWeb IP blocks as of May 2015
    $self->ips(
        # 45 Network Blocks
        '5.79.64.0/18',
        '31.31.32.0/21',
        '37.48.64.0/18',
        '37.58.48.0/20',
        '43.249.36.0/22',
        '46.165.192.0/18',
        '46.182.120.0/21',
        '62.212.64.0/19',
        # extending 77.221.144.0/24 to include 77.221.145.0/24
        '77.221.144.0/23',
        '78.159.96.0/19',
        '82.192.64.0/19',
        '83.149.64.0/18',
        '84.16.224.0/19',
        '85.17.0.0/16',
        '87.255.32.0/19',
        '89.149.192.0/18',
        '91.109.16.0/20',
        '94.75.192.0/18',
        '95.168.160.0/19',
        '95.211.0.0/16',
        '108.59.0.0/20',
        '109.120.180.0/22',
        '162.210.192.0/21',
        '178.162.128.0/17',
        '185.17.144.0/22',
        '185.17.184.0/22',
        # extending 185.28.68.0/24 to include 185.28.69.0/24
        # extending 185.28.68.0/23 to include 185.28.70.0/24
        # extending 185.28.68.0-185.28.70.255 to include 185.28.71.0/24
        '185.28.68.0/22',
        '188.72.192.0/18',
        '192.96.200.0/21',
        '198.7.56.0/21',
        '199.58.84.0/22',
        '199.115.112.0/21',
        '207.244.64.0/18',
        '209.58.128.0/18',
        '209.192.128.0/17',
        '212.95.32.0/19',
        '217.20.112.0/20',
        '2001:df1:800::/47',
        '2001:1af8::/32',
        '2604:9a00::/32',
        '2a00:c98::/32',
        '2a00:ec8::/32',
        '2a00:9d20::/32',
        '2a03:2280::/32',
        '2a04:1880:1111::/48',
    );
    return $self;
}

sub name {
    return 'LEASEWEB';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::LeaseWeb - identify LeaseWeb owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::LeaseWeb;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::LeaseWeb identifies LeaseWeb host IPs.
    AS59253     Leaseweb Asia Pacific pte. ltd.  Singapore
    AS133752    Leaseweb Asia Pacific pte. ltd.
    AS30878     Leaseweb Germany GmbH Germany
    AS28753     Leaseweb Germany GmbH Germany
    AS60781     LeaseWeb B.V.  Netherlands
    AS16265     LeaseWeb B.V.  Netherlands
    AS38930     LeaseWeb Network B.V.  Netherlands
    AS60626     LeaseWeb CDN B.V.  Netherlands
    AS7203      Leaseweb USA, Inc.  United States
    AS30633     Leaseweb USA, Inc.  United States

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::LeaseWeb object.

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
