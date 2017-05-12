package Net::Squid::Purge::Multicast;

use warnings;
use strict;

use base qw(Net::Squid::Purge);

use IO::Socket::Multicast;

Net::Squid::Purge::Multicast->mk_accessors(qw(multicast_group multicast_port));

our $VERSION = '0.1';

sub purge {
	my ($self, @urls) = @_;
    if (! $self->multicast_group) { die 'multicast_group must be set!'; }
    if (! $self->multicast_port) { die 'multicast_port must be set!'; }

	my $socket = IO::Socket::Multicast->new( Proto => 'icp', LocalPort => $self->multicast_port);
    if (! $socket->mcast_add($self->multicast_group)) {
        die "Couldn't set group: $!\n";
    }
    for my $url (@urls) {
        if (! $socket->mcast_send($self->_format_request($url))) { warn 'purge request failed'; }
	}
	return 1;
}

sub _format_purge {
	my ($self, $url) = @_;
	return <<"EOF";
	PURGE $url HTTP/1.0
	Accept: */*

EOF
}

1;
__END__

=pod

=head1 NAME

Net::Squid::Purge::Multicast

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

  use Net::Squid::Purge::Multicast;
  my $purger = Net::Squid::Purge::Multicast->new();
  $purger->multicast_group('192.168.100.3');
  $purger->multicast_port('2000');
  $purger->purge('http://localhost/', 'http://localhost/home/');

=head1 FUNCTIONS

=head2 purge

This function performs the purge action on the designated squid servers.

=head2 multicast_group

=head2 multicast_port

=head1 SEE ALSO

Please see L<Net::Squid::Purge> for more information.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
