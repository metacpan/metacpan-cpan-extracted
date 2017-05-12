#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Facebook
#     ABSTRACT:  identify Facebook (AS32934) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Thu Oct 30 14:28:30 PDT 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::Facebook;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known Facebook (AS32934) IP blocks as of May 2015
    $self->ips(
        # 14 Network Blocks
        '31.13.24.0/21',
        '31.13.64.0/18',
        '66.220.144.0/20',
        '69.63.176.0/20',
        '69.171.224.0/19',
        '74.119.76.0/22',
        '173.252.64.0/18',
        '185.60.216.0/22',
        '199.201.64.0/22',
        '204.15.20.0/22',
        '2401:db00::/32',
        '2620:0:1c00::/40',
        '2620:10d:c000::/40',
        '2a03:2880::/32',
    );
    return $self;
}

sub name {
    return 'Facebook';
}

sub refresh {
    my ($self) = @_;

    my @fb = system `whois -h whois.radb.net '!gAS32934'`;
    my @cidrs = split(/\s+/, join('', map { m|/| } @fb));

    delete $self->{ips};
    $self->ips(@cidrs);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Facebook - identify Facebook (AS32934) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::Facebook;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::Facebook identifies Facebook (AS32934) host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::Facebook object.

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
