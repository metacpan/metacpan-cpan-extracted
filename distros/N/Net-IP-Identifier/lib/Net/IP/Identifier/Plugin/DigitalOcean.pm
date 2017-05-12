#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::DigitalOcean
#     ABSTRACT:  identify DigitalOcean owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Tue Nov 11 10:29:26 PST 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

# _ENTITY_REGEX_ digital.?ocean

package Net::IP::Identifier::Plugin::DigitalOcean;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known DigitalOcean IP blocks as of March 2015
    #   AS62567 AS393406 AS202109 AS202018 AS201229 AS200130 AS14061 AS133165
    $self->ips(
        # 25 Network Blocks
        # extending 5.101.96.0/21 to include 5.101.104.0/21
        '5.101.96.0/20',
        '37.139.0.0/19',
        '45.55.0.0/16',
        '46.101.0.0/16',
        '80.240.128.0/20',
        '82.196.0.0/20',
        '95.85.0.0/18',
        '103.253.144.0/22',
        '104.131.0.0/16',
        '104.236.0.0/16',
        '107.170.0.0/16',
        '162.243.0.0/16',
        '178.62.0.0/17',
        '185.14.184.0/22',
        '188.166.0.0/16',
        '188.226.128.0/17',
        '192.34.56.0/21',
        '192.81.208.0/20',
        '192.241.128.0/17',
        '198.199.64.0/18',
        '198.211.96.0/19',
        '208.68.36.0/22',
        '2400:6180::/32',
        '2604:a880::/32',
        '2a03:b0c0::/32',
    );
    return $self;
}

sub name {
    return 'DigitalOcean';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::DigitalOcean - identify DigitalOcean owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::DigitalOcean;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::DigitalOcean identifies DigitalOcean host IPs
(AS62567 AS393406 AS202109 AS202018 AS201229 AS200130 AS14061 AS133165).

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::DigitalOcean object.

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
