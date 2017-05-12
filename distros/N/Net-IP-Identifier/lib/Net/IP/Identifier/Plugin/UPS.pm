#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::UPS
#     ABSTRACT:  identify UPS (AS4973, AS4972, AS4145, AS12217) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sun Oct 12 19:32:46 PDT 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::UPS;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known UPS (AS12217) IP blocks as of May 2015
    $self->ips(
        # 8 Network Blocks
        '63.171.196.0/24',
        '65.174.66.0/24',
        '65.174.169.0/24',
        '153.2.0.0/16',
        '156.134.0.0/16',
        '192.55.236.0/24',
        '205.173.112.0/21',
        '208.14.182.0/24',
    );
    return $self;
}

sub name {
    return 'UPS';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::UPS - identify UPS (AS4973, AS4972, AS4145, AS12217) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::UPS;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::UPS identifies UPS (AS4973, AS4972, AS4145, AS12217) host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::UPS object.

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
