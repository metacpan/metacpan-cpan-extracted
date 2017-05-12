#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Toqen
#     ABSTRACT:  identify Toqen LLC (AS30186) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sun Oct 12 19:32:46 PDT 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

# _ENTITY_REGEX_ toqen|ross

package Net::IP::Identifier::Plugin::Toqen;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known Toqen LLC (AS30186) IP blocks as of May 2015
    $self->ips(
        # 6 Network Blocks
        '108.175.48.0/20',
        '198.41.96.0/19',
        '198.54.112.0/20',
        '199.36.120.0/22',
        '199.38.240.0/21',
        '2604:9080::/32',
    );
    return $self;
}

sub name {
    return 'Toqen';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Toqen - identify Toqen LLC (AS30186) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::Toqen;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::Toqen identifies Toqen LLC (AS30186) host IPs.

These netblocks seem to be owned by Ross Technology Inc. (as of May 2015).

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::Toqen object.

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
