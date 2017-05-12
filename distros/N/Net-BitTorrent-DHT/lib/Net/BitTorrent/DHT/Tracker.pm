package Net::BitTorrent::DHT::Tracker;
use Moose;
our $VERSION = 'v1.0.3';
eval $VERSION;
#
has peers => (isa      => 'HashRef[ArrayRef]',
                is       => 'ro',
                default  => sub { {} },
                init_arg => undef,
                traits   => ['Hash'],
                handles  => {
                            get_peers  => 'get',
                            _set_peers => 'set',
                            has_peers  => 'defined',
                            del_peers  => 'delete'
                }
);
around get_peers => sub {
    my ($code, $self, $infohash) = @_;
    $code->($self, blessed $infohash ? $infohash->to_Hex : $infohash);
};

sub add_peer {
    my ($self, $infohash, $peer) = @_;
    return $self->_set_peers($infohash->to_Hex, [$peer])
        if !$self->has_peers($infohash->to_Hex);
    push(@{$self->get_peers($infohash->to_Hex)}, $peer)
        if !grep { $_->[0] eq $peer->[0] && $_->[1] eq $peer->[1] }
        @{$self->get_peers($infohash->to_Hex)};
}
has routing_table => (isa      => 'Net::BitTorrent::DHT::RoutingTable',
                        is       => 'ro',
                        required => 1,
                        weak_ref => 1,
                        handles  => [qw[dht]]
);
1;

=pod

=head1 NAME

Net::BitTorrent::DHT::Tracker - Psudo-tracker for the DHT

=head1 Description

Nothing to see here.

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2008-2014 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

Neither this module nor the L<Author|/Author> is affiliated with BitTorrent,
Inc.

=cut
