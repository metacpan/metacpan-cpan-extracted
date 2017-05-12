package Net::Squid::Purge::HTTP;

use strict;
use warnings;

use base qw(Net::Squid::Purge);

use Net::HTTP;
use HTTP::Status;

Net::Squid::Purge::HTTP->mk_accessors(qw(squid_servers));

our $VERSION = '0.1';

sub purge {
    my ($self, @urls) = @_;
    if (! $self->squid_servers) { die 'squid_servers must be set!'; }
    for my $squid_host (@{$self->squid_hosts}) {
        my $squid_host = Net::HTTP->new(
            Host => $squid_host->{'host'},
            PeerPort => $squid_host->{'port'} || 3128,
            Timeout => 2,
            KeepAlive => 1,
        );
        if (! $squid_host) { warn "Could not connect to squid host $squid_host->{'host'}"; next; }
        for my $url (@urls) {
            $squid_host->write_request($self->_format_purge($url));
            my ($status, $message) = $squid_host->read_response_headers;
            if (! is_success($status)) { warn "Purge request failed: $message"; }
        }
    }
    return 1;
}

sub _format_purge {
    my ($self, $url) = @_;
    if (! $url) { die 'url parameter must be passed'; }
    return ('PURGE', $url, 'Accept', '*/*');
}

1;
__END__

=pod

=head1 NAME

Net::Squid::Purge::HTTP

=head1 SYNOPSIS

  use Net::Squid::Purge;
  my $purger = Net::Squid::Purge->new({
    'squid_servers' => [
      { host => '192.168.100.3' },
      { host => '192.168.100.4' },
      { host => '192.168.100.5', port => '8080' },
    ],
  }, 'HTTP');
  $purger->purge('http://search.cpan.org/', 'http://blog.socklabs.com/');

=head1 FUNCTIONS

=head2 purge

This function performs the purge action on the designated squid servers.

=head2 squid_servers

Set the squid servers to use at run time. This is just an accessor, the same
information can be set on object creation (new( squid_servers => [...])).

=head1 SEE ALSO

Please see L<Net::Squid::Purge> for more information.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
