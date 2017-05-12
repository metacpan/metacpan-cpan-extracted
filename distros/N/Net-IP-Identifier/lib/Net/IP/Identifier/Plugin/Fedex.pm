#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Fedex
#     ABSTRACT:  identify Fedex (AS7726 AS27619 AS25676) owned IP addresses

#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sun Oct 12 19:32:46 PDT 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::Fedex;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known Fedex (AS7726 AS27619 AS25676) IP blocks as of May 2015
    $self->ips(
        # 12 Network Blocks
        '12.168.77.0/24',
        '65.162.10.0/24',
        '146.18.0.0/16',
        '155.161.0.0/16',
        '165.150.0.0/16',
        '170.5.0.0/16',
        '170.170.0.0/16',
        '192.67.56.0/24',
        # extending 198.140.0.0/22 to include 198.140.4.0/23
        '198.140.0.0-198.140.5.255',
        # extending 199.81.0.0/16 to include 199.82.0.0/16
        '199.81.0.0-199.82.255.255',
        '203.208.20.0/24',
        '204.135.0.0/16',
    );
    return $self;
}

sub name {
    return 'Fedex';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Fedex - identify Fedex (AS7726 AS27619 AS25676) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::Fedex;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::Fedex identifies Fedex (AS7726 AS27619 AS25676) host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::Fedex object.

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
