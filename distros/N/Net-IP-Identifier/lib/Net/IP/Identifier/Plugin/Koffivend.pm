#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Koffivend
#     ABSTRACT:  identify Koffivend Corp (AS201305) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Thu Mar 26 10:41:08 PDT 2015
#===============================================================================

use 5.008;
use strict;
use warnings;

# _ENTITY_REGEX_ koffi-?vend

package Net::IP::Identifier::Plugin::Koffivend;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known Koffivend Corp (AS201305) IP blocks as of May 2015
    $self->ips(
        # 18 Network Blocks
        '78.159.156.0/24',
        # extending 87.243.67.0/24 to include 87.243.68.0/24
        # extending 87.243.67.0-87.243.68.255 to include 87.243.69.0/24
        # extending 87.243.67.0-87.243.69.255 to include 87.243.70.0/24
        # extending 87.243.67.0-87.243.70.255 to include 87.243.71.0/24
        # extending 87.243.67.0-87.243.71.255 to include 87.243.72.0/24
        # extending 87.243.67.0-87.243.72.255 to include 87.243.73.0/24
        # extending 87.243.67.0-87.243.73.255 to include 87.243.74.0/24
        # extending 87.243.67.0-87.243.74.255 to include 87.243.75.0/24
        # extending 87.243.67.0-87.243.75.255 to include 87.243.76.0/24
        '87.243.67.0-87.243.76.255',
        '87.243.79.0/24',
        # extending 87.243.83.0/24 to include 87.243.84.0/24
        '87.243.83.0-87.243.84.255',
        '87.243.88.0/24',
        # extending 87.243.90.0/24 to include 87.243.91.0/24
        '87.243.90.0/23',
        # extending 87.243.94.0/24 to include 87.243.95.0/24
        # extending 87.243.94.0/23 to include 87.243.96.0/24
        # extending 87.243.94.0-87.243.96.255 to include 87.243.97.0/24
        # extending 87.243.94.0-87.243.97.255 to include 87.243.98.0/24
        '87.243.94.0-87.243.98.255',
        '87.243.100.0/24',
        # extending 87.243.102.0/24 to include 87.243.103.0/24
        # extending 87.243.102.0/23 to include 87.243.104.0/24
        '87.243.102.0-87.243.104.255',
        # extending 87.243.106.0/24 to include 87.243.107.0/24
        '87.243.106.0/23',
        # extending 87.243.109.0/24 to include 87.243.110.0/24
        '87.243.109.0-87.243.110.255',
        '94.73.9.0/24',
        '94.73.16.0/24',
        '109.160.10.0/24',
        # extending 109.160.44.0/24 to include 109.160.45.0/24
        # extending 109.160.44.0/23 to include 109.160.46.0/24
        '109.160.44.0-109.160.46.255',
        # extending 109.160.64.0/24 to include 109.160.65.0/24
        # extending 109.160.64.0/23 to include 109.160.66.0/24
        # extending 109.160.64.0-109.160.66.255 to include 109.160.67.0/24
        '109.160.64.0/22',
        '109.160.121.0/24',
        # extending 195.230.26.0/24 to include 195.230.27.0/24
        # extending 195.230.26.0/23 to include 195.230.28.0/24
        # extending 195.230.26.0-195.230.28.255 to include 195.230.29.0/24
        # extending 195.230.26.0-195.230.29.255 to include 195.230.30.0/24
        # extending 195.230.26.0-195.230.30.255 to include 195.230.31.0/24
        '195.230.26.0-195.230.31.255',
    );
    return $self;
}

sub name {
    return 'Koffivend';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Koffivend - identify Koffivend Corp (AS201305) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::Koffivend;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::Koffivend identifies Koffivend Corp (AS201305) host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::Koffivend object.

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
