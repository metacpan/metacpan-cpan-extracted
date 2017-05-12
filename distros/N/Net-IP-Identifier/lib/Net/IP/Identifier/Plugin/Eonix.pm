#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Eonix
#     ABSTRACT:  identify Eonix (AS30693) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sun Oct 12 19:32:46 PDT 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::Eonix;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known Eonix (AS30693) IP blocks as of May 2015
    $self->ips(
        # 14 Network Blocks
        '23.90.0.0/18',
        '23.231.0.0/17',
        '50.2.0.0/15',
        '75.75.224.0/19',
        '104.140.0.0/16',
        '104.206.0.0/16',
        '107.158.0.0/16',
        '170.130.0.0/16',
        '173.44.128.0/17',
        '173.213.64.0/18',
        '173.232.0.0/16',
        '206.214.64.0/19',
        '208.89.216.0/21',
        '2607:ff28::/32',
    );
    return $self;
}

sub name {
    return 'Eonix';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Eonix - identify Eonix (AS30693) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::Eonix;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::Eonix identifies Eonix (AS30693) host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::Eonix object.

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
