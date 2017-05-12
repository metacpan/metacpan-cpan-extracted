package Net::BitTorrent::DHT::Node;
use Moose;
use Moose::Util::TypeConstraints;
use AnyEvent;
use Net::BitTorrent::Protocol qw[:dht :compact];
use feature qw[state];
use Scalar::Util;
use Types::Standard qw[Bool Int Ref Str];
our $VERSION = 'v1.0.3';
eval $VERSION;
#
sub BUILD {1}

#
has port     => (isa => Int, is => 'ro', required => 1);
has host     => (isa => Str, is => 'ro', required => 1);
has sockaddr => (isa => Str, is => 'ro', required => 1, lazy_build => 1);

sub _build_sockaddr {
    Net::BitTorrent::DHT::sockaddr($_[0]->host, $_[0]->port);
}
has ipv6 => (isa => Bool, is => 'ro', lazy_build => 1);
sub _build_ipv6 { length shift->sockaddr == 28 }
for my $dir (qw[in out]) {
    has 'announce_peer_token_'
        . $dir => (isa     => 'HashRef[Str]',
                   is      => 'ro',
                   traits  => ['Hash'],
                   handles => {'_set_announce_peer_token_' . $dir => 'set',
                               '_get_announce_peer_token_' . $dir => 'get',
                               '_del_announce_peer_token_' . $dir => 'delete',
                               'has_announce_peer_token_' . $dir  => 'defined'
                   },
                   default => sub { {} }
        );
}
has v => (isa => Str, is => 'ro', writer => '_v', predicate => 'has_v');
has bucket => (isa       => 'Net::BitTorrent::DHT::Bucket',
                 is        => 'ro',
                 writer    => 'assign_bucket',
                 weak_ref  => 1,
                 predicate => 'has_bucket'
);
has routing_table => (isa        => 'Net::BitTorrent::DHT::RoutingTable',
                        is         => 'ro',
                        predicate  => 'has_routing_table',
                        writer     => '_routing_table',
                        weak_ref   => 1,
                        lazy_build => 1,
                        handles    => [qw[send dht tracker]]
);
around send => sub {
    my ($code, $self, $packet, $reply) = @_;
    $code->($self, $self, $packet, !!$reply);
};
has nodeid => (isa       => 'Bit::Vector',
                 is        => 'ro',
                 writer    => '_set_nodeid',
                 predicate => 'has_nodeid'
);
after _set_nodeid => sub {
    $_[0]->routing_table->assign_node($_[0]);
    $_[0]->routing_table->del_node($_[0]) if !$_[0]->has_bucket;
};
has outstanding_requests => (isa     => 'HashRef[HashRef]',
                               is      => 'ro',
                               traits  => ['Hash'],
                               handles => {add_request    => 'set',
                                           get_request    => 'get',
                                           del_request    => 'delete',
                                           expire_request => 'delete',
                                           is_expecting   => 'defined'
                               },
                               init_arg => undef,
                               default  => sub { {} }
);
after expire_request => sub { shift->inc_fail };
around add_request => sub {
    my ($code, $self, $tid, $args) = @_;
    Scalar::Util::weaken $self;
    $args->{'timeout'} //= AE::timer(
        20, 0,
        sub {
            $self->expire_request($tid) if $self;    # May ((poof)) $self
        }
    );
    $code->($self, $tid, $args);
};
has ping_timer => (
         isa      => Ref,                               # ArrayRef|EV::Timer
         builder  => '_build_ping_timer',
         is       => 'ro',
         init_arg => undef,
         writer   => '_ping_timer'
);

sub _build_ping_timer {
    my ($self) = @_;
    Scalar::Util::weaken $self;
    AE::timer(60 * 10, 60 * 10, sub { $self->ping if $self });
}
has seen => (
    isa        => Int,
    is         => 'ro',
    lazy_build => 1,
    init_arg   => undef,
    writer     => '_set_seen',
    handles    => {
        touch  => sub { shift->_set_seen(time) },
        active => sub {
            return time - shift->seen <= 15 * 60;
            }
    }
);
for my $type (qw[get_peers find_node announce_peer]) {
    has 'prev_'
        . $type => (isa        => 'HashRef[Int]',
                    is         => 'ro',
                    lazy_build => 1,
                    builder    => '_build_prev_X',
                    init_arg   => undef,
                    traits     => ['Hash'],
                    handles    => {
                                'get_prev_' . $type     => 'get',
                                'set_prev_' . $type     => 'set',
                                'defined_prev_' . $type => 'defined'
                    }
        );
}
sub _build_prev_X { {} }
after BUILD => sub {
    my ($self) = @_;
    Scalar::Util::weaken $self;
    $self->_ping_timer(AE::timer(rand(30), 0, sub { $self->ping }));
};
has birth => (is         => 'ro',
                isa        => Int,
                init_arg   => undef,
                lazy_build => 1
);
sub _build_birth {time}

sub ping {
    my ($self) = @_;
    state $tid = 'a';
    my $packet = build_ping_query('p_' . $tid,
                                      pack('H*', $self->dht->nodeid->to_Hex));
    my $sent = $self->send($packet);
    return $self->inc_fail() if !$sent;
    $self->add_request('p_' . $tid, {type => 'ping'});
    $tid++;
}

sub _reply_ping {
    my ($self, $tid) = @_;
    my $packet
        = build_ping_reply($tid, pack('H*', $self->dht->nodeid->to_Hex));
    my $sent = $self->send($packet, 1);
    $self->inc_fail() if !$sent;
    return $sent;
}

sub find_node {
    my ($self, $target) = @_;
    return
        if $self->defined_prev_find_node($target->to_Hex)
        && $self->get_prev_find_node($target->to_Hex) > time - (60 * 15);
    state $tid = 'a';
    my $packet =
        build_find_node_query('fn_' . $tid,
                                  pack('H*', $self->dht->nodeid->to_Hex),
                                  pack('H*', $target->to_Hex));
    my $sent = $self->send($packet);
    return $self->inc_fail() if !$sent;
    $self->add_request('fn_' . $tid,
                       {type => 'find_node', target => $target});
    $tid++;
    $self->set_prev_find_node($target->to_Hex, time);
}

sub _reply_find_node {
    my ($self, $tid, $target) = @_;
    my $nodes
        = compact_ipv4(
                 map { [$_->host, $_->port] }
                     @{$self->routing_table->nearest_bucket($target)->nodes});
    return if !$nodes;
    my $packet = build_find_node_reply($tid, pack('H*', $target->to_Hex),
                                           $nodes);
    my $sent = $self->send($packet, 1);
    $self->inc_fail() if !$sent;
    return $sent;
}

sub get_peers {
    my ($self, $info_hash) = @_;
    return
        if $self->defined_prev_get_peers($info_hash->to_Hex)
        && $self->get_prev_get_peers($info_hash->to_Hex) > time - (60 * 15);
    state $tid = 'a';
    my $packet =
        build_get_peers_query('gp_' . $tid,
                                  pack('H*', $self->dht->nodeid->to_Hex),
                                  pack('H*', $info_hash->to_Hex)
        );
    my $sent = $self->send($packet);
    return $self->inc_fail() if !$sent;
    $self->add_request('gp_' . $tid,
                       {type => 'get_peers', info_hash => $info_hash});
    $tid++;
    $self->set_prev_get_peers($info_hash->to_Hex, time);
}

sub _reply_get_peers {
    my ($self, $tid, $id) = @_;
    if (!$self->has_announce_peer_token_out($id->to_Hex)) {
        state $announce_peer_token = 'aa';
        $announce_peer_token = 'aa' if length $announce_peer_token == 3;
        $self->_set_announce_peer_token_out($id->to_Hex,
                                            $announce_peer_token++);
    }
    my $nodes
        = compact_ipv4(
                     map { [$_->host, $_->port] }
                         @{$self->routing_table->nearest_bucket($id)->nodes});
    my @values = grep { defined $_ } map {
        Net::BitTorrent::Protocol::BEP23::Compact::compact_ipv4(
                                                           [$_->[0], $_->[1]])
    } @{$self->tracker->get_peers($id) || []};
    return if (!@values && !$nodes);
    my $packet =
        build_get_peers_reply($tid,
                                  $id->to_Hex,
                                  \@values,
                                  $nodes,
                                  $self->_get_announce_peer_token_out(
                                                                   $id->to_Hex
                                  )
        );
    my $sent = $self->send($packet, 1);
    $self->inc_fail() if !$sent;
    return $sent;
}

sub announce_peer {
    my ($self, $info_hash, $port) = @_;
    return
        if $self->defined_prev_announce_peer($info_hash->to_Hex)
        && $self->get_prev_announce_peer($info_hash->to_Hex)
        > time - (60 * 30);
    return if !$self->has_announce_peer_token_in($info_hash->to_Hex);
    state $tid = 'a';
    my $packet =
        build_announce_peer_query('an_' . $tid,
                                      pack('H*', $self->dht->nodeid->to_Hex),
                                      pack('H*', $info_hash->to_Hex),
                                      $self->_get_announce_peer_token_in(
                                                            $info_hash->to_Hex
                                      ),
                                      $port
        );
    my $sent = $self->send($packet);
    return $self->inc_fail() if !$sent;
    $self->add_request('an_' . $tid,
                       {type => 'announce_peer', info_hash => $info_hash});
    $tid++;
    $self->set_prev_announce_peer($info_hash->to_Hex, time);
}

sub _reply_announce_peer {
    my ($self, $tid, $info_hash, $a_ref) = @_;
    my $packet;
    if ((!$self->has_announce_peer_token_out($info_hash->to_Hex))
        || ($self->_get_announce_peer_token_out($info_hash->to_Hex) ne
            $a_ref->{'token'})
        )
    {   $packet =
            build_error_reply($tid,
                                  [203,
                                   'Incorrect write token in announce_peer'
                                  ]
            );
    }
    elsif (
         !$self->tracker->add_peer($info_hash, [$self->host, $a_ref->{'port'}]
         )
        )
    {   $packet = build_error_reply($tid,
                                      [202, 'Failed to add peer to tracker']);
    }
    else {
        $packet = build_announce_peer_reply($tid,
                                      pack('H*', $self->dht->nodeid->to_Hex));
    }
    my $sent = $self->send($packet, 1);
    $self->inc_fail() if !$sent;
    return $sent;
}
has fail => (
    isa      => Int,
    traits   => ['Counter'],
    default  => 0,
    is       => 'ro',
    handles  => {inc_fail => 'inc'},
    init_arg => undef,
    trigger  => sub {
        my ($self, $new, $old) = @_;
        $self->routing_table->del_node($self)
            if $new == ($self->has_bucket ? 5 : 1);
    }
);
1;

=pod

=head1 NAME

Net::BitTorrent::DHT::Node - A single node in a DHT routing table

=head1 Description

TODO

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
