#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::VPLS
#     ABSTRACT:  identify VPLS/Krypt (AS45652, AS4213, AS35908) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sun Oct 12 19:32:46 PDT 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

#_ENTITY_REGEX_ vpls|krypt

package Net::IP::Identifier::Plugin::VPLS;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known VPLS/Krypt (AS45652, AS4213, AS35908) IP blocks as of May 2015
    $self->ips(
        # 24 Network Blocks
        '23.91.192.0/19',
        '23.251.0.0/19',
        '43.252.120.0/22',
        '66.186.32.0/19',
        '67.198.128.0/17',
        '67.229.0.0/16',
        '74.222.128.0/18',
        '96.62.0.0/16',
        '98.126.0.0/16',
        '100.43.128.0/18',
        '103.233.80.0/22',
        '104.200.192.0/19',
        '107.6.192.0/18',
        '110.34.139.0/24',
        '110.34.220.0/22',
        '173.214.0.0/17',
        '174.139.0.0/16',
        '184.75.176.0/20',
        '184.83.0.0/16',
        '184.164.192.0/19',
        '192.174.96.0/19',
        '198.61.96.0/19',
        '209.11.240.0/20',
        '2607:f180::/31',
    );
    return $self;
}

sub name {
    return 'VPLS';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::VPLS - identify VPLS/Krypt (AS45652, AS4213, AS35908) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::VPLS;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::VPLS identifies VPLS/Krypt host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::VPLS object.

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
