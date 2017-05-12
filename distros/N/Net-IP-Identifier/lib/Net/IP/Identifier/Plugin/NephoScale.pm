#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::NephoScale
#     ABSTRACT:  identify NephoScale (AS13332 AS32105 AS46717) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sun Oct 12 19:32:46 PDT 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::NephoScale;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known NephoScale (AS13332 AS32105 AS46717) IP blocks as of
    #    May 2015
    $self->ips(
        # 19 Network Blocks
        '23.252.240.0/20',
        '64.58.112.0/20',
        '67.207.192.0/20',
        '69.50.224.0/19',
        '96.46.176.0/20',
        '142.0.192.0/20',
        '142.0.240.0/20',
        '173.0.144.0/20',
        '173.233.128.0/19',
        # extending 173.237.0.0/18 to include 173.237.64.0/20
        '173.237.0.0-173.237.79.255',
        '198.89.96.0/19',
        '198.100.160.0/19',
        '199.188.116.0/22',
        '204.74.224.0/19',
        '208.69.176.0/21',
        '208.78.240.0/21',
        '208.166.48.0/20',
        '2607:e000::/32',
        '2607:f258::/32',
    );
    return $self;
}

sub name {
    return 'NephoScale';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::NephoScale - identify NephoScale (AS13332 AS32105 AS46717) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::NephoScale;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::NephoScale identifies NephoScale (AS13332 AS32105 AS46717) host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::NephoScale object.

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
