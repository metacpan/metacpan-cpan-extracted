#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Google
#     ABSTRACT:  identify Google (AS15169) owned IP addresses
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:   Mon Oct  6 14:01:00 PDT 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

#_ENTITY_REGEX_ google|postini

package Net::IP::Identifier::Plugin::Google;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

        # List of known Google (AS15169) IP blocks as of May 2015
    $self->ips(
        # 17 Network Blocks
        '8.8.4.0/24',
        '8.8.8.0/24',
        '64.18.0.0/20',
        '64.233.160.0/19',
        '66.102.0.0/20',
        '66.249.64.0/19',
        '72.14.192.0/18',
        '74.125.0.0/16',
        '173.194.0.0/16',
        '207.126.144.0/20',
        '209.85.128.0/17',
        '216.239.32.0/19',
        '2001:4860::/32',
        '2404:6800::/32',
        '2607:f8b0::/32',
        '2800:3f0::/32',
        '2c0f:fb50::/32',
    );
    # NOTE: jwhois 207.126.144.0 - 207.126.159.255 and
    #   64.18.0.0 - 64.18.15.255 indicate Postini, which is 'Google email
    #   security and archiving services'
    # NOTE: 2a00:1450:4000::/36 is returned by the refresh method suggested
    #   by Google (see below), but "jwhois 2a00:1450:4000::" indicates it's
    #   unassigned.
    return $self;
}

sub name {
    return 'Google';
}

sub refresh {
    my ($self) = @_;

    my $google_DNS = '8.8.8.8';     # public Goodle DNS server _NO_CHECK_
    # from https://support.google.com/a/answer/60764?hl=en
    my $spf = `nslookup -q=TXT _spf.google.com $google_DNS`;
#print "$spf\n";
    my (@blocks) = $spf =~ m/ include:(\S+)/g;
    my @cidrs;
    for my $block (@blocks) {
        my $net_blocks = `nslookup -q=TXT $block $google_DNS`;
#print $net_blocks;
        push @cidrs, $net_blocks =~ m/ ip.:(\S+)/g;
    }
    # not included in the above algorithm for some reason
    unshift @cidrs, '8.8.8.0/24', '8.8.4.0/24';     # _NO_CHECK_
    delete $self->{ips};
    $self->ips(@cidrs);
#print join "\n", '', @cidrs, '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Google - identify Google (AS15169) owned IP addresses

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Plugin::Google;

=head1 DESCRIPTION

Net::IP::Identifier::Plugin::Google identifies Google (AS15169) host IPs.

=head2 Methods

=over

=item new

Creates a new Net::IP::Identifier::Plugin::Google object.

=item refresh

Uses a method described by Google (https://support.google.com/a/answer/60764?hl=en)
to fetch the current list of Google net blocks.  Replaces the default list of hard-coded
netblocks (which is current as of August 2014).

This method requires about four DNS queries (currently).  If having
up-to-date netblock information is more important than the time it takes to
do the queries, arrange to call this method after the object is created,
and perhaps periodically thereafter.

NOTE: 2a00:1450:4000::/36 is returned by the this method but "jwhois
2a00:1450:4000::" indicates it's unassigned.

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
