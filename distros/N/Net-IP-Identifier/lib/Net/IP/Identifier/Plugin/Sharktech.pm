#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Sharktech
#     ABSTRACT:  identify Sharktech (AS46844) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Wed Nov 12 09:37:48 PST 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::Sharktech;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known Sharktech (AS46844) IP blocks as of May 2015
    $self->ips(
        # 15 Network Blocks
        '45.58.128.0/18',
        '64.32.0.0/19',
        '67.21.64.0/19',
        '70.39.64.0/18',
        '104.37.244.0/22',
        '104.160.160.0/19',
        '104.201.64.0/18',
        '107.167.0.0/19',
        '170.178.160.0/19',
        '174.128.224.0/19',
        '198.148.80.0/20',
        '199.115.96.0/21',
        '204.188.192.0/18',
        '208.98.0.0/18',
        '2610:150::/32',
    );
    return $self;
}

sub name {
    return 'Sharktech';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Sharktech - identify Sharktech (AS46844) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::Sharktech;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::Sharktech identifies Sharktech (AS46844) host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::Sharktech object.

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
