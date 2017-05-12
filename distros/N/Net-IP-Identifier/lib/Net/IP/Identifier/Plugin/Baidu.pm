#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Baidu
#     ABSTRACT:  identify Baidu (AS63288, AS55967, AS45085, AS45076, AS38627, AS38365, AS264376, AS199506) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sun Dec 21 11:39:36 PST 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::Baidu;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # List of known Baidu (AS63288, AS55967, AS45085, AS45076, AS38627,
    #        AS38365, AS264376, AS199506) IP blocks as of May 2015
    $self->ips(
        # 7 Network Blocks
        '119.63.192.0/21',
        '119.75.208.0/20',
        '180.76.0.0/16',
        '182.61.0.0/16',
        '185.10.104.0/22',
        '222.199.188.0/22',
        '2400:da00::/32',
    );
    return $self;
}

sub name {
    return 'Baidu';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Baidu - identify Baidu (AS63288, AS55967, AS45085, AS45076, AS38627, AS38365, AS264376, AS199506) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::Baidu;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::Baidu identifies Baidu (AS63288, AS55967, AS45085, AS45076, AS38627, AS38365, AS264376, AS199506) host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::Baidu object.

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
