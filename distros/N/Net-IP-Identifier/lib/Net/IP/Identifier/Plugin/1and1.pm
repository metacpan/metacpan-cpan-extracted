#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::1and1
#     ABSTRACT:  identify 1and1 / FastHosts (AS8560, AS15418) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sun Oct 12 19:32:46 PDT 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

# _ENTITY_REGEX_ 1and1|1\&1|fasthosts

package Net::IP::Identifier::Plugin::1and1;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known 1and1 (AS8560, AS15418) IP blocks as of May 2015
    $self->ips(
        # 30 Network Blocks
        '50.21.176.0/20',
        '66.175.232.0/21',
        '70.35.192.0/20',
        '74.208.0.0/16',
        '77.68.0.0/17',
        '79.99.40.0/21',
        '82.165.0.0/16',
        '87.106.0.0/16',
        '88.208.192.0/18',
        '93.90.192.0/20',
        '104.192.4.0/22',
        '104.219.40.0/22',
        '104.254.244.0/22',
        '108.175.0.0/20',
        '109.228.0.0/18',
        '162.222.200.0/21',
        '162.252.156.0/22',
        '162.255.84.0/22',
        '195.20.224.0/19',
        '198.71.48.0/20',
        '198.251.64.0/20',
        '212.227.0.0/16',
        '213.165.64.0/19',
        '213.171.192.0/19',
        '216.250.112.0/20',
        '217.72.192.0/20',
        '217.160.0.0/16',
        '217.174.240.0/20',
        '2001:8d8::/32',
        '2607:f1c0::/32',
    );
    return $self;
}

sub name {
    return '1and1';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::1and1 - identify 1and1 / FastHosts (AS8560, AS15418) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::1and1;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::1and1 identifies 1and1 / FastHosts (AS8560, AS15418) host IPs.

Note: United Internet (of Germany) owns both 1and1 and Fasthosts.  Both are
included in this module.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::1and1 object.

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
