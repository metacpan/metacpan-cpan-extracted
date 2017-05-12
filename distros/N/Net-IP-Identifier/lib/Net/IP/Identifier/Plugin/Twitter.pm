#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Twitter
#     ABSTRACT:  identify Twitter (AS13414 AS35995 AS54888) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sun Oct 12 19:32:46 PDT 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::Twitter;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known Twitter (AS13414 AS35995 AS54888) IP blocks as of May 2015.
    $self->ips(
        # 10 Network Blocks
        # extending 8.25.194.0/23 to include 8.25.196.0/23
        '8.25.194.0-8.25.197.255',
        '185.45.4.0/22',
        '192.133.76.0/22',
        '199.16.156.0/22',
        '199.59.148.0/22',
        '199.96.56.0/21',
        '209.170.99.0/24',
        '2400:6680::/32',
        '2620:fe::/40',
        '2a04:9d40::/29',
    );
    return $self;
}

sub name {
    return 'Twitter';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Twitter - identify Twitter (AS13414 AS35995 AS54888) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::Twitter;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::Twitter identifies Twitter (AS13414 AS35995 AS54888) host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::Twitter object.

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
