#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::OVH
#     ABSTRACT:  identify OVH (AS16276) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Tue Nov 11 10:29:26 PST 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::OVH;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known OVH (AS16276) IP blocks as of May 2015
    $self->ips(
        # 24 Network Blocks
        '5.39.0.0/17',
        '5.135.0.0/16',
        '5.196.0.0/16',
        '37.59.0.0/16',
        '37.187.0.0/16',
        '46.105.0.0/16',
        '87.98.128.0/17',
        '91.121.0.0/16',
        '92.222.0.0/16',
        '94.23.0.0/16',
        '109.190.0.0/16',
        '142.4.192.0/19',
        '167.114.0.0/16',
        '176.31.0.0/16',
        '178.32.0.0/15',
        '188.165.0.0/16',
        '192.95.0.0/18',
        '192.99.0.0/16',
        '198.27.64.0/18',
        '198.50.128.0/17',
        '198.100.144.0/20',
        '198.245.48.0/20',
        '213.186.32.0/19',
        '213.251.128.0/18',
    );
    return $self;
}

sub name {
    return 'OVH';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::OVH - identify OVH (AS16276) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::OVH;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::OVH identifies OVH (AS16276) host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::OVH object.

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
