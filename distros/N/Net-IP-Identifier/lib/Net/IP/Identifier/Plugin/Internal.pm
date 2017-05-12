#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Internal
#     ABSTRACT:  identify Internal (non-routable) IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Wed Apr  1 12:11:51 PDT 2015
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::Internal;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of internal (non-routable) IP blocks
    $self->ips(
        '10.0.0.0 - 10.255.255.255',        # for general public use - RFC 1918
        '100.64.0.0/10',                    # carrier grade (not for general public use!) RFC 6598
        '169.254.1.0 - 169.254.254.255',    # Link Local (zero-conf) RFC 6890 and RFC 3927
        '172.16.0.0 - 172.31.255.255',      # for general public use - RFC 1918
        '192.168.0.0 - 192.168.255.255',    # for general public use - RFC 1918
        'fc00::/7',         # Unique Local Address (ULA) RFC 4193 (global scope!)
        'fec0::/10',        # deprecated since Sept 2004 RFC 3879
        'fe80::/10',        # Link Local RFC 4862
    );
    return $self;
}

sub name {
    return 'internal';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Internal - identify Internal (non-routable) IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::Internal;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::Internal identifies internal (non-routable)
host IPs.  These should all be hosts on your internal network.
Communication between these hosts and the outside internet can only occur
through a NAT (Network Address Translation) gateway or a proxy server.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::Internal object.

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
