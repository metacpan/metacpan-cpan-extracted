#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::DataShack
#     ABSTRACT:  identify DataShack (AS33387) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Tue Nov 11 10:10:29 PST 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

# _ENTITY_REGEX_ data.?shack

package Net::IP::Identifier::Plugin::DataShack;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known DataShack (AS33387) IP blocks as of May 2015
    # (apparently associated with WholeSale Internet and Zhou Pizhong)
    $self->ips(
        # 11 Network Blocks
        '63.141.224.0/19',
        '74.91.16.0/20',
        '107.150.32.0/19',
        '142.54.160.0/19',
        '173.208.166.0/24',
        '173.208.250.0/24',
        '192.151.144.0/20',
        '192.187.96.0/19',
        '198.204.224.0/19',
        '199.168.96.0/21',
        '2604:4300::/32',
    );
    return $self;
}

sub name {
    return 'DataShack';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::DataShack - identify DataShack (AS33387) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::DataShack;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::DataShack identifies DataShack (AS33387) host
IPs (apparently associated with WholeSale Internet and Zhou Pizhong).

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::DataShack object.

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
