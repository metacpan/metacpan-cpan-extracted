#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Centarra
#     ABSTRACT:  identify Centarra (AS36137 AS40440) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sat Nov  8 15:59:36 PST 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

# _ENTITY_REGEX_ centarra|avante

package Net::IP::Identifier::Plugin::Centarra;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known Centarra (AS36137 AS40440) IP blocks as of May 2015
    $self->ips(
        # 7 Network Blocks
        '66.248.192.0/19',
        '192.119.144.0/20',
        '192.161.192.0/18',
        '192.241.8.0/21',
        '198.52.128.0/17',
        '199.195.156.0/22',
        '2607:bd00::/32',
    );
    return $self;
}

sub name {
    return 'Centarra';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Centarra - identify Centarra (AS36137 AS40440) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::Centarra;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::Centarra identifies Centarra (AS36137 AS40440)
IPs.  Associated with Avante Hosting Services.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::Centarra object.

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
