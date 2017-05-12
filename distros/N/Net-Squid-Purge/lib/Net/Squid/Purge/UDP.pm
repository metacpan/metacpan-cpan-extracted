package Net::Squid::Purge::UDP;

use strict;
use warnings;

use base qw(Net::Squid::Purge);

use Socket;
use IO::Socket::INET;

Net::Squid::Purge::UDP->mk_accessors(qw(squid_servers));

our $VERSION = '0.1';

sub purge {
    my ($self, @urls) = @_;
    if (! $self->squid_servers) { die 'squid_servers must be set!'; }
    for my $squid_host (@{$self->squid_hosts}) {
        my $s = IO::Socket::INET->new(
            PeerAddr => $squid_host->{'host'},
            PeerPort => $squid_host->{'port'} || 3128,
            Proto    => 'udp',
            Type     => SOCK_DGRAM
        );
        if (! $s) { die 'Could not create socket to host ' . $squid_host->{'host'}; }
        for my $url (@urls) {
        if (! $s->send($self->_format_purge($url))) { die 'Purge request failed'; }
        }
    }
    return 1;
}

sub _format_purge {
    my ($self, $url) = @_;
    if (! $url) { die 'url parameter must be passed'; }
    my $spec = pack(
        'na4na*na8n',
        4, 'NONE', length( $url ), $url,
        8, 'HTTP/1.0', 0
    );
    my $dlen = 8 + 2 + length( $spec );
    my $len = 4 + $dlen + 2;
    return pack( 'nxxnCxNxxa*n', $len, $dlen, 4, rand(), $spec, 2);
}

1;
__END__

=pod

=head1 NAME

Net::Squid::Purge::UDP

=head1 SYNOPSIS

  use Net::Squid::Purge;
  my $purger = Net::Squid::Purge->new({
    'squid_servers' => [ { host => '192.168.100.3' }, ],
  }, 'UDP');
  $purger->purge('http://search.cpan.org/', 'http://blog.socklabs.com/');

=head1 FUNCTIONS

=head2 purge

This function performs the purge action on the designated squid servers.

=head2 squid_servers

Set the squid servers to use at run time. This is just an accessor, the same
information can be set on object creation (new( squid_servers => [...])).

=head1 CREDIT

Paul Lindner C<< <lindner at inuus.com> >> wrote the proof of concept for this
module and provided the example code.

=head1 SEE ALSO

Please see L<Net::Squid::Purge> for more information.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
