#!/usr/bin/perl -w
package Net::BitTorrent::DHT;
{
    use strict;
    use warnings;
    use Digest::SHA qw[sha1_hex];
    use Scalar::Util qw[blessed weaken refaddr];
    use Carp qw[carp];
    use Socket qw[/inet_/ /pack_sockaddr_in/];
    use lib q[../../../lib/];
    use Net::BitTorrent::Util qw[:bencode :compact];
    use Net::BitTorrent::Protocol qw[:dht];
    use Net::BitTorrent::Version;
    use version qw[qv];
    our $VERSION_BASE = 50; our $UNSTABLE_RELEASE = 0; our $VERSION = sprintf(($UNSTABLE_RELEASE ? q[%.3f_%03d] : q[%.3f]), (version->new(($VERSION_BASE))->numify / 1000), $UNSTABLE_RELEASE);
    my @CONTENTS
        = \my (%_client, %tid, %node_id, %outstanding_p, %nodes, %tracking);
    my %REGISTRY;

    sub new {
        my ($class, $args) = @_;
        my $self = undef;
        if (!$args or (ref($args) ne q[HASH])) {
            carp __PACKAGE__
                . q[->new( { ... } ) requires parameters passed as a hashref];
            return;
        }
        if (   !$args->{q[Client]}
            or !blessed($args->{q[Client]})
            or !$args->{q[Client]}->isa(q[Net::BitTorrent]))
        {   carp __PACKAGE__
                . q[->new( { ... } ) requires parameters passed as a hashref];
            return;
        }
        my $node_id = Net::BitTorrent::Version->gen_node_id();
        $self = bless \$node_id, $class;

        # Defaults
        $_client{refaddr $self} = $args->{q[Client]};
        weaken $_client{refaddr $self};
        $node_id{refaddr $self} = $node_id;
        $nodes{refaddr $self}   = {};
        $tid{refaddr $self}     = q[aaaaa];

        # Boot
        $_client{refaddr $self}->_schedule(
                                          {Code => sub { shift->_pulse() },
                                           Time   => time + 3,
                                           Object => $self
                                          }
        );
        $_client{refaddr $self}->_schedule(    # boot up
            {Code => sub {
                 my ($s) = @_;
                 for my $node (values %{$nodes{refaddr $s}}) {
                     $self->_ping_out($node);
                     $self->_find_node_out($node, $node_id{refaddr $s});
                 }
             },
             Time   => time + 2,
             Object => $self
            }
        );
        weaken($REGISTRY{refaddr $self} = $self);
        return $self;
    }

    # Accessors | Private
    sub _client {
        return if defined $_[1];
        return $_client{refaddr + $_[0]};
    }

    sub _peers {
        my ($self, $info_hash) = @_;
        return q[] if !$tracking{refaddr $self}{$info_hash};
        $tracking{refaddr $self}{$info_hash}{q[touch]} = time;
        return $tracking{refaddr $self}{$info_hash}{q[peers]};
    }

    # Accesors | Public
    sub node_id {
        return if defined $_[1];
        return $node_id{refaddr + $_[0]};
    }

    sub nodes {
        return if defined $_[1];
        return [map { {ip => $_->{q[ip]}, port => $_->{q[port]}} }
                values %{$nodes{refaddr + $_[0]}}];
    }

    # Setters | Private
    sub _set_node_id {
        return if not defined $_[1];
        return $node_id{refaddr + $_[0]} = $_[1];
    }

    # Methods | Public
    sub add_node {
        my ($self, $args) = @_;
        return if !$_client{refaddr $self}->_use_dht;
        return if scalar keys %{$nodes{refaddr $self}} >= 300; # max 300 nodes
        return if ref $args ne q[HASH];
        return if !$args->{q[port]};
        return if !$args->{q[ip]};
        my $ok = $_client{refaddr $self}->_event(q[ip_filter],
             {Address => sprintf q[%s:%d], $args->{q[ip]}, $args->{q[port]}});
        if (defined $ok and $ok == 0) { return; }
        my $_resolved = inet_aton($args->{q[ip]});
        return if !$_resolved;
        my $paddr = pack_sockaddr_in($args->{q[port]}, $_resolved);
        $nodes{refaddr $self}{$paddr} = {
                                       birth     => time,
                                       fail      => 0,
                                       id        => undef,
                                       ip        => $args->{q[ip]},
                                       okay      => 0,
                                       paddr     => $paddr,
                                       ping      => time - 61,          # lies
                                       port      => $args->{q[port]},
                                       prev_find => 0,
                                       prev_get  => 0,
                                       prev_ann  => 0,
                                       seen      => time - 60,          # lies
                                       token_i   => undef,
                                       token_o   => undef
            }
            if !$nodes{refaddr $self}{$paddr};
        return $nodes{refaddr $self}{$paddr};
    }

    sub _pulse {
        my ($self) = @_;
        return if !$_client{refaddr $self}->_use_dht;
        for my $tid (
            grep {
                $outstanding_p{refaddr $self}{$_}{q[sent]} < time - 20
            }
            keys %{$outstanding_p{refaddr $self}}
            )
        {    # old packets
            $nodes{refaddr $self}
                {$outstanding_p{refaddr $self}{$tid}{q[paddr]}}{q[fail]}++;
            delete $outstanding_p{refaddr $self}{$tid};
        }
        for my $paddr (
            grep {
                (!defined $nodes{refaddr $self}{$_}
                 {q[seen]})    # XXX - mystery bug
                    or
                    (($nodes{refaddr $self}{$_}{q[seen]} < time - (60 * 15)))
                    or ($nodes{refaddr $self}{$_}{q[fail]} > 10)
            } keys %{$nodes{refaddr $self}}
            )
        {                      # old/bad nodes
            delete $nodes{refaddr $self}{$paddr};
        }
        for my $paddr (
            grep {
                (($nodes{refaddr $self}{$_}{q[ping]}
                      > $nodes{refaddr $self}{$_}{q[seen]}
                 )
                     and
                     ($nodes{refaddr $self}{$_}{q[ping]} < time - (60 * 8))
                    )
            } keys %{$nodes{refaddr $self}}
            )
        {    # old/bad nodes
            $self->_ping_out($nodes{refaddr $self}{$paddr});
        }
        for my $info_hash (keys %{$tracking{refaddr $self}})
        {    # stale tracker data
            delete $tracking{refaddr $self}{$info_hash}
                if $tracking{refaddr $self}{$info_hash}{q[touch]}
                    < time - (60 * 30);
        }

        # TODO: remove bad nodes, etc.
        $_client{refaddr $self}->_schedule(
                                          {Code => sub { shift->_pulse() },
                                           Time   => time + 45,
                                           Object => $self
                                          }
        );
    }

    sub _on_data {
        my ($self, $paddr, $data) = @_;
        return if !$_client{refaddr $self}->_use_dht;
        my ($packet, $leftover) = bdecode($data);
        my $node;
        if (    (defined $packet)
            and (ref $packet eq q[HASH])
            and $packet->{q[y]})
        {   if ($packet->{q[y]} eq q[q]) {    # query
                if ($packet->{q[q]} eq q[ping]) {
                    $self->_ping_reply($paddr, $packet->{q[t]});
                    if (q[XXX - I don't want this in the final version. ...do I?]
                        and !$nodes{refaddr $self}{$paddr})
                    {   my ($_port, $_ip) = unpack_sockaddr_in($paddr);
                        $_ip = inet_ntoa($_ip);
                        my $ok = $_client{refaddr $self}->_event(q[ip_filter],
                                 {Address => sprintf q[%s:%d], $_ip, $_port});
                        if (defined $ok and $ok == 0) { return; }
                        my $new_node
                            = $self->add_node({ip => $_ip, port => $_port});
                        return if !$new_node;
                    }
                    if (defined $nodes{refaddr $self}{$paddr}) {
                        $nodes{refaddr $self}{$paddr}{q[id]}
                            ||= $packet->{q[a]}{q[id]};
                        $nodes{refaddr $self}{$paddr}{q[ping]} = time;
                        $nodes{refaddr $self}{$paddr}{q[seen]} = time;
                        $self->_find_node_out($nodes{refaddr $self}{$paddr},
                                              $node_id{refaddr $self});
                    }
                    return;
                }
                elsif ($packet->{q[q]} eq q[find_node]) {
                    my ($_port, $_ip) = unpack_sockaddr_in($paddr);
                    $_ip = inet_ntoa($_ip);
                    my $ok = $_client{refaddr $self}->_event(q[ip_filter],
                                 {Address => sprintf q[%s:%d], $_ip, $_port});
                    if (defined $ok and $ok == 0) { return; }

          # if (!$nodes{refaddr $self}{$paddr}) {
          #    my ($port, $host) = unpack_sockaddr_in($paddr);
          #    $self->add_node({ip=>inet_ntoa($host), port=>$port}) || return;
          #}
          #$node = $nodes{refaddr $self}{$paddr};
          #$nodes{refaddr $self}{$paddr}{q[id]}||=
          #        $packet->{q[a]}{q[id]};
                    my $nodes = compact(
                          map { sprintf q[%s:%d], $_->{q[ip]}, $_->{q[port]} }
                              grep { $_->{q[ip]} =~ m[^[\d\.]+$] }
                              $self->_locate_nodes_near_target(
                                                    $packet->{q[a]}{q[target]}
                              )
                    );
                    $self->_find_node_reply($paddr, $packet->{q[t]},
                                            $packet->{q[a]}{q[id]}, $nodes)

                        #if $nodes;
                }
                elsif ($packet->{q[q]} eq q[get_peers]) {
                    if (!$nodes{refaddr $self}{$paddr}) {
                        my ($port, $host) = unpack_sockaddr_in($paddr);
                        $self->add_node(
                                     {ip => inet_ntoa($host), port => $port});
                        return if !$nodes{refaddr $self}{$paddr};
                    }
                    $node = $nodes{refaddr $self}{$paddr};
                    $node->{q[id]} ||= $packet->{q[a]}{q[id]};
                    $node->{q[seen]} = time;
                    $node->{q[okay]}++;
                    $node->{q[fail]}    = 0;
                    $node->{q[token_o]} = q[NB_] . $self->_generate_token;
                    if ($tracking{refaddr $self}
                        {$packet->{q[a]}{q[info_hash]}})
                    {   my @values = uncompact($tracking{refaddr $self}
                                   {$packet->{q[a]}{q[info_hash]}}{q[peers]});
                        @values = map { compact($_) }
                            grep {$_} @values[0 .. 7];    # max 8
                        my $outgoing_packet
                            = _build_dht_reply_values(
                                      $packet->{q[t]}, $packet->{q[a]}{q[id]},
                                      \@values,        $node->{q[token_o]});
                        send($_client{refaddr $self}->_udp(),
                             $outgoing_packet, 0, $paddr);
                        $tracking{refaddr $self}
                            {$packet->{q[a]}{q[info_hash]}}{q[touch]} = time;
                    }
                    else {
                        my $nodes = compact(
                            map {
                                sprintf q[%s:%d], $_->{q[ip]}, $_->{q[port]}
                                } grep { $_->{q[ip]} =~ m[^[\d\.]+$] }
                                $self->_locate_nodes_near_target(
                                                 $packet->{q[a]}{q[info_hash]}
                                )
                        );
                        send($_client{refaddr $self}->_udp(),
                             _build_dht_reply_get_peers(
                                      $packet->{q[t]}, $packet->{q[a]}{q[id]},
                                      $nodes,          $node->{q[token_o]}
                             ),
                             0, $paddr
                        );
                    }
                }
                elsif ($packet->{q[q]} eq q[announce_peer]) {
                    if (!$nodes{refaddr $self}{$paddr}) {

                        # XXX - reply with an error msg
                        #die q[...we don't know this node];
                        return;
                    }
                    $node = $nodes{refaddr $self}{$paddr};
                    $node->{q[id]} ||= $packet->{q[a]}{q[id]};
                    $node->{q[seen]} = time;
                    $node->{q[okay]}++;
                    $node->{q[fail]} = 0;
                    if (   (!$node->{q[token_o]})
                        || ($packet->{q[a]}{q[token]} ne $node->{q[token_o]}))
                    {    # XXX - reply with token error msg
                            #die pp $node;
                        return;
                    }
                    elsif ((!$tracking{refaddr $self}
                            {$packet->{q[a]}{q[info_hash]}}
                           )
                           and (scalar(keys %{$tracking{refaddr $self}}) > 64)
                        )
                    {       # enough torrents
                            # XXX - reply with error msg?
                            #
                        return;
                    }
                    else {
                        my @current_peers = uncompact($tracking{refaddr $self}
                                   {$packet->{q[a]}{q[info_hash]}}{q[peers]});
                        if (scalar(@current_peers) > 128)
                        {    # enough peers for this torrent
                                # XXX - reply with error msg?
                                #
                            return;
                        }
                        $tracking{refaddr $self}
                            {$packet->{q[a]}{q[info_hash]}}{q[peers]}
                            = compact(@current_peers,
                                      sprintf(q[%s:%d],
                                              $node->{q[ip]},
                                              $packet->{q[a]}{q[port]})
                            );
                        $self->_ping_reply($paddr, $packet->{q[t]});
                        $tracking{refaddr $self}
                            {$packet->{q[a]}{q[info_hash]}}{q[touch]} = time;

                        #warn q[Now on hand: ]
                        #    . pp uncompact($tracking{refaddr $self}
                        #                   {$packet->{q[a]}{q[info_hash]}});
                    }
                }
                else {

                    #die pp $packet;
                }
            }
            elsif ($packet->{q[y]} eq q[r]) {    # reply
                my $original_packet
                    = $outstanding_p{refaddr $self}{$packet->{q[t]}};
                if (!$original_packet) {

                    #warn q[...unexpected reply: ] . pp $packet;
                    #warn pp $outstanding_p{refaddr $self}{$packet->{q[t]}};
                    #
                    return;
                }
                return if !$nodes{refaddr $self}{$paddr};
                $node = $nodes{refaddr $self}{$paddr};
                if ($original_packet->{q[paddr]} ne $paddr) {
                    my ($fake_port, $fake_host) = unpack_sockaddr_in($paddr);
                    $fake_host = inet_ntoa($fake_host);
                    my ($real_port, $real_host)
                        = unpack_sockaddr_in($original_packet->{q[paddr]});
                    $real_host = inet_ntoa($real_host);

#warn sprintf
#    qq[...wrong remote node sent this reply %s to %s |\n %s:%d|%s\n  vs\n %s:%d|%s],
#    pp($packet),
#    pp($original_packet),
#    $fake_host, $fake_port, pp($paddr),
#    $real_host, $real_port,
#    pp($original_packet->{q[paddr]});
                    return;
                }
                delete $outstanding_p{refaddr $self}{$packet->{q[t]}};
                $node->{q[seen]} = time;
                $node->{q[okay]}++;
                $node->{q[fail]} = 0;
                $node->{q[id]}
                    = $node->{q[id]}
                    ? $node->{q[id]}
                    : $packet->{q[r]}{q[id]};
                $node->{q[token_i]}
                    = $packet->{q[r]}{q[token]}
                    ? $packet->{q[r]}{q[token]}
                    : $node->{q[token_i]};

                #warn sprintf q[%s:%d sent us %s in reply to %s],
                #    $node->{q[ip]}, $node->{q[port]},
                #    pp(bdecode($data)), pp($original_packet);
                if ($packet->{q[r]}{q[nodes]}) {
                    for my $_node (uncompact($packet->{q[r]}{q[nodes]})) {
                        my ($ip, $port) = split q[:], $_node, 2;
                        my $new_node
                            = $self->add_node({ip => $ip, port => $port});
                        next if !$new_node;

                        #$self->_ping_out($new_node);
                        #
                        #warn pp $original_packet;
                        my $_data = bdecode($original_packet->{q[packet]});

                        #warn pp $_data;
                        my $info_hash
                            = $_data->{q[a]}{q[target]}
                            ? $_data->{q[a]}{q[target]}
                            : $_data->{q[a]}{q[info_hash]};

                        #    warn pp $info_hash;
                        $self->_get_peers_out($new_node, $info_hash);
                    }
                }
                if ($packet->{q[r]}{q[values]}) {

                    #warn pp $original_packet;
                    my $torrent =
                        $_client{refaddr $self}->_locate_torrent(
                                        unpack q[H40],
                                        bdecode($original_packet->{q[packet]})
                                            ->{q[a]}{q[info_hash]}
                        );
                    if ($torrent) {
                        $tracking{refaddr $self}{$torrent->infohash} = {
                                    peers =>
                                        compact(
                                        uncompact(
                                            $tracking{refaddr $self}
                                                {$torrent->infohash}{q[peers]}
                                        ),
                                        (map { uncompact($_) }
                                             @{$packet->{q[r]}{q[values]}}
                                        )
                                        ),
                                    touch => time
                        };
                    }
                    $self->_find_node_out($node, $node_id{refaddr $self});
                }
            }
            elsif ($packet->{q[y]} eq q[e]) {    # error
                    #if ( $packet->{q[e]}->[0] ==  ) {  }
                    # XXX - Should DHT have events?
                    #use Data::Dump qw[pp];
                    #warn sprintf qq[Error: %s\from %s\nnoriginal packet: %s],
                    #    pp($packet), pp($nodes{refaddr $self}{$paddr}),
                    #    pp(scalar bdecode(
                 #                $outstanding_p{refaddr $self}{$packet->{q[t]}}
                 #                    {q[packet]}
                 #       )
                 #    );
                delete $outstanding_p{refaddr $self}{$packet->{q[t]}};
            }
            else {    #warn q[...what just happend? ] . pp bdecode($data)
            }
        }
        else {

            # AZ or garbage. ...as if the two were different.
            #use Data::Dump qw[pp];
            #warn q[Bad packet: ] . pp($data);
        }
    }

    sub _ping_out {
        my ($self, $node) = @_;
        return if !$_client{refaddr $self}->_use_dht;
        return if $node->{q[seen]} > time - 120;
        my $tid = $self->_generate_token;
        my $packet = _build_dht_query_ping($tid, $node_id{refaddr $self});
        $outstanding_p{refaddr $self}{$tid} = {attempts => 1,
                                               sent     => time,
                                               packet   => $packet,
                                               paddr    => $node->{q[paddr]}
        };
        return
            send($_client{refaddr $self}->_udp(),
                 $packet, 0, $node->{q[paddr]});
    }

    sub _ping_reply {
        my ($self, $paddr, $tid) = @_;
        return if !$_client{refaddr $self}->_use_dht;
        return
            send($_client{refaddr $self}->_udp(),
                 _build_dht_reply_ping($tid, $node_id{refaddr $self}),
                 0, $paddr);
    }

    sub _announce_peer_out {
        my ($self, $node, $infohash) = @_;
        return if !$_client{refaddr $self}->_use_dht;
        return if $node->{q[prev_ann]} > time - (60 * 15);
        my $tid = $self->_generate_token;
        return if !$node->{q[token_i]};
        my $packet =
            _build_dht_query_announce($tid,
                                      $node_id{refaddr $self},
                                      $infohash,
                                      $node->{q[token_i]},
                                      $_client{refaddr $self}->_tcp_port
            );
        $outstanding_p{refaddr $self}{$tid} = {attempts => 1,
                                               sent     => time,
                                               packet   => $packet,
                                               paddr    => $node->{q[paddr]}
        };
        $node->{q[prev_find]} = 0;
        $node->{q[prev_ann]}  = time;
        return
            send($_client{refaddr $self}->_udp(),
                 $packet, 0, $node->{q[paddr]});
    }

    sub _find_node_out {
        my ($self, $node, $target) = @_;
        return if !$_client{refaddr $self}->_use_dht;
        return if $node->{q[prev_find]} > time - (60 * 5);
        my $tid = $self->_generate_token;
        my $packet = _build_dht_query_find_node($tid, $node_id{refaddr $self},
                                                $target);
        $outstanding_p{refaddr $self}{$tid} = {attempts => 1,
                                               sent     => time,
                                               packet   => $packet,
                                               paddr    => $node->{q[paddr]}
        };
        $node->{q[prev_find]} = time;
        return
            send($_client{refaddr $self}->_udp(),
                 $packet, 0, $node->{q[paddr]});
    }

    # Send find_node result to peer
    sub _find_node_reply {
        my ($self, $paddr, $tid, $id, $nodes) = @_;
        return if !$_client{refaddr $self}->_use_dht;
        return
            send($_client{refaddr $self}->_udp(),
                 _build_dht_reply_find_node($tid, $id, $nodes),
                 0, $paddr);
    }

    sub _get_peers_out {
        my ($self, $node, $info_hash) = @_;
        return if !$_client{refaddr $self}->_use_dht;
        return if $node->{q[prev_get]} > time - (60 * 10);
        my $tid    = $self->_generate_token;
        my $packet = _build_dht_query_get_peers($tid, $node_id{refaddr $self},
                                                $info_hash);
        $outstanding_p{refaddr $self}{$tid} = {attempts => 1,
                                               sent     => time,
                                               packet   => $packet,
                                               paddr    => $node->{q[paddr]}
        };
        $node->{q[prev_get]} = time;
        return
            send($_client{refaddr $self}->_udp(),
                 $packet, 0, $node->{q[paddr]});
    }

    # Methods | Private | Fake routing table
    sub _locate_nodes_near_target {
        my ($self, $target) = @_;
        return if !$_client{refaddr $self}->_use_dht;
        my $_target = hex unpack q[H4], $target;
        my @nodes;
        for my $node (
            sort {
                hex(unpack q[H4], $a->{q[id]}) ^ $_target cmp
                    hex(unpack q[H4], $b->{q[id]}) ^ $_target
            }
            grep { $_->{q[id]} } values %{$nodes{refaddr $self}}
            )
        {   push @nodes, $node;
            last if scalar @nodes == 8;
        }
        return @nodes;
    }

    # Methods | Private | Peer search
    sub _scrape {
        my ($self, $torrent) = @_;
        return if !$_client{refaddr $self}->_use_dht;
        if (   (!$torrent)
            || (!blessed $torrent)
            || (!$torrent->isa(q[Net::BitTorrent::Torrent])))
        {   carp
                q[Net::BitTorrent::DHT::Node->_scrape() requires a Net::BitTorrent::Torrent];
            return;
        }
        if ($torrent->private) {
            carp q[Private torrents disallow DHT];
            return;
        }
        my $info_hash = pack q[H40], $torrent->infohash;
        for my $node ($self->_locate_nodes_near_target($info_hash)) {
            $self->_find_node_out($node, $info_hash);
            $self->_get_peers_out($node, $info_hash);
        }
        return 1;
    }

    sub _announce {
        my ($self, $torrent) = @_;
        return if !$_client{refaddr $self}->_use_dht;
        if (   (!$torrent)
            || (!blessed $torrent)
            || (!$torrent->isa(q[Net::BitTorrent::Torrent])))
        {   carp
                q[Net::BitTorrent::DHT::Node->_scrape() requires a Net::BitTorrent::Torrent];
            return;
        }
        if ($torrent->private) {
            carp q[Private torrents disallow DHT];
            return;
        }
        my $info_hash = pack q[H40], $torrent->infohash;
        for my $node ($self->_locate_nodes_near_target($info_hash)) {

            #if !$node->{q[token_i]};
            $self->_find_node_out($node, $info_hash);
            $self->_announce_peer_out($node, $info_hash);
        }
        return 1;
    }

    sub _generate_token {
        my ($self) = @_;
        return if !$_client{refaddr $self}->_use_dht;
        return ++$tid{refaddr $self};
    }

    sub as_string {
        my ($self, $advanced) = @_;
        my $dump = !$advanced ? $node_id{refaddr $self} : sprintf <<'END',
Net::BitTorrent::DHT

Node ID: %s
END
            $node_id{refaddr $self};
        return defined wantarray ? $dump : print STDERR qq[$dump\n];
    }

    sub CLONE {
        for my $_oID (keys %REGISTRY) {
            my $_obj = $REGISTRY{$_oID};
            my $_nID = refaddr $_obj;
            for (@CONTENTS) {
                $_->{$_nID} = $_->{$_oID};
                delete $_->{$_oID};
            }
            weaken $_client{$_nID};
            delete $outstanding_p{$_nID};
            weaken($REGISTRY{$_nID} = $_obj);
            delete $REGISTRY{$_oID};
        }
        return 1;
    }
    DESTROY {
        my ($self) = @_;
        for (@CONTENTS) { delete $_->{refaddr $self}; }
        return delete $REGISTRY{refaddr $self};
    }
}
1;

=pod

=head1 NAME

Net::BitTorrent::DHT - Kademlia based Distributed Hash Table

=head1 Constructor

=over

=item C<new ( [ARGS] )>

Creates a C<Net::BitTorrent::DHT> object.  This constructor should not be
used directly.

=back

=head1 Methods

=over

=item C<add_node ( { [...] } )>

Adds a single node to the routing table.  Expects a hashref with the
following keys:

=over

=item C<ip>

The hostname/IP address of the remote node.

=item C<port>

The port the remote node has open for DHT.

=back

This is an advanced method and should not (normally) should not be used.

=item C<node_id ( )>

Get the Node ID used to identify this L<client|/Net::BitTorrent> in the
DHT swarm.

=item C<nodes ( )>

Returns a list of nodes from the routing table in a format suitable for
handing off to L<add_node( )|/"add_node ( { [...] } )"> one by one.

=item C<as_string ( [ VERBOSE ] )>

Returns a 'ready to print' dump of the  object's data structure.  If
called in void context, the structure is printed to C<STDERR>.
C<VERBOSE> is a boolean value.

=back

=head1 Bugs

In this alpha, there are a number of places where I break away from the
specification.  These will all be fixed in a future version.

=over

=item *

The routing table is flat.

=back

=head1 Notes

While bandwidth to/from DHT nodes will probably never be limited like
other traffic, in the future, it will be taken into account and "drained"
from the rate limiter.  If there's a burst of DHT traffic, the peer
traffic may be limited to avoid the total to exceed the global limit.

=head1 See Also

I have used a number of references for implementation second opinions:

=over

=item The Kademlia Paper

http://pdos.csail.mit.edu/~petar/papers/maymounkov-kademlia-lncs.pdf

=item BEP 5: DHT

http://www.bittorrent.org/beps/bep_0005.html

=item Notes about the BitTorrent DHT Protocol from GetRight

http://getright.com/torrentdev.html

=back



=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2008-2009 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify
it under the terms of The Artistic License 2.0.  See the F<LICENSE>
file included with this distribution or
http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered
by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

Neither this module nor the L<Author|/Author> is affiliated with
BitTorrent, Inc.

=for svn $Id: DHT.pm d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $

=cut
