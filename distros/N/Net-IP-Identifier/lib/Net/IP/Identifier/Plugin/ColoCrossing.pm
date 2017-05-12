#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::ColoCrossing
#     ABSTRACT:  identify ColoCrossing (AS36352) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sun Oct 12 19:33:06 PDT 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::ColoCrossing;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known ColoCrossing (AS36352) IP blocks as of May 2015
    $self->ips(
        # 37 Network Blocks
        '23.94.0.0/15',
        '65.99.193.0/24',
        '65.99.246.0/24',
        '66.225.194.0/23',
        '66.225.198.0/24',
        # extending 66.225.231.0/24 to include 66.225.232.0/24
        '66.225.231.0-66.225.232.255',
        '69.31.134.0/24',
        '72.249.94.0/24',
        '72.249.124.0/24',
        '75.102.10.0/24',
        '75.102.27.0/24',
        '75.102.34.0/24',
        '75.102.38.0/23',
        '75.127.0.0/20',
        '96.8.112.0/20',
        '104.168.0.0/17',
        '107.172.0.0/14',
        '108.174.48.0/20',
        '172.245.0.0/16',
        '192.3.0.0/16',
        '192.210.128.0/17',
        '192.227.128.0/17',
        '198.12.64.0/18',
        '198.23.128.0/17',
        '198.46.128.0/17',
        '198.144.176.0/20',
        '199.21.112.0/22',
        '199.188.100.0/22',
        # extending 205.234.152.0/24 to include 205.234.153.0/24
        '205.234.152.0/23',
        '205.234.159.0/24',
        '205.234.203.0/24',
        '206.123.95.0/24',
        '206.217.128.0/20',
        '207.210.239.0/24',
        '216.246.49.0/24',
        # extending 216.246.108.0/24 to include 216.246.109.0/24
        '216.246.108.0/23',
        '2607:9d00::/32',
    );
    return $self;
}

sub name {
    return 'ColoCrossing';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::ColoCrossing - identify ColoCrossing (AS36352) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::ColoCrossing;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::ColoCrossing identifies ColoCrossing (AS36352) host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::ColoCrossing object.

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
