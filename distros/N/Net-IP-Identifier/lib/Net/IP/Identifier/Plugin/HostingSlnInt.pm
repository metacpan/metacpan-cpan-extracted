#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::HostingSlnInt
#     ABSTRACT:  identify Hosting Solutions International (ASN30083) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Wed Nov 19 11:00:13 PST 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

# _ENTITY_REGEX_ hosting.solutions.international

package Net::IP::Identifier::Plugin::HostingSlnInt;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known Hosting Solutions International (ASN30083) IP blocks as
    #   of May 2015
    $self->ips(
        # 8 Network Blocks
        '50.30.32.0/20',
        '69.64.32.0/19',
        '173.224.112.0/20',
        '199.189.84.0/22',
        '199.217.112.0/21',
        '209.126.96.0/19',
        '209.239.112.0/20',
        '2605:de00::/32',
    );
    return $self;
}

sub name {
    return 'HostingSlnInt';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::HostingSlnInt - identify Hosting Solutions International (ASN30083) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::HostingSlnInt;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::HostingSlnInt identifies Hosting Solutions International (ASN30083) host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::HostingSlnInt object.

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
