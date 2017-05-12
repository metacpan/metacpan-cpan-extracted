#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Enzu
#     ABSTRACT:  identify Enzu/ScalableDNS owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Tue Nov 11 10:10:29 PST 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::Enzu;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known Enzu/ScalableDNS IP blocks as of May 2015
    $self->ips(
        # 22 Network Blocks
        '23.88.0.0/15',
        '23.244.0.0/15',
        '37.77.80.0/20',
        '104.151.0.0/16',
        '104.202.0.0/15',
        '107.183.0.0/16',
        '172.246.0.0/16',
        '184.105.219.0/24',
        '188.215.80.0/21',
        '188.215.104.0/21',
        '192.80.128.0/18',
        '192.157.192.0/18',
        '198.56.128.0/17',
        '198.71.80.0/20',
        '198.98.96.0/19',
        '199.48.68.0/22',
        '199.188.72.0/22',
        '199.193.248.0/21',
        '199.229.232.0/22',
        '199.231.208.0/21',
        '2605:f700::/32',
        '2a00:8c40::/32',
    );
    return $self;
}

sub name {
    return 'Enzu';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Enzu - identify Enzu/ScalableDNS owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::Enzu;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::Enzu identifies Enzu/ScalableDNS host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::Enzu object.

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
