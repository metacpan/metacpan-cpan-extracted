package Net::BitTorrent::DHT;
use Moose;
use Moose::Util;
use AnyEvent;
use AnyEvent::Socket qw[];
use AnyEvent::HTTP;
use Socket qw[/SOCK_/ /F_INET/ inet_aton /sockaddr_in/ inet_ntoa
    SOL_SOCKET SO_REUSEADDR
];
use Net::BitTorrent::Protocol qw[:bencode :compact];
use Bit::Vector;
use Net::BitTorrent::DHT::Node;
use Net::BitTorrent::DHT::RoutingTable;
use 5.10.0;
our $VERSION = 'v1.0.3';
eval $VERSION;

# Stub
sub BUILD {1}
after 'BUILD' => sub {
    my ($s, $a) = @_;

    # Hey! Open up!
    $s->udp6;
    $s->udp4;
};
#
for my $type (qw[requests replies]) {
    for my $var (qw[count length]) {
        my $attr = join '_', '', 'recv_invalid', $var;
        has $attr => (isa      => 'Int',
                      is       => 'ro',
                      init_arg => undef,
                      traits   => ['Counter'],
                      handles  => {'_inc' . $attr => 'inc'},
                      default  => 0
        );
        for my $dir (qw[recv send]) {
            my $attr = join '_', '', $dir, $type, $var;
            has $attr => (isa      => 'Int',
                          is       => 'ro',
                          init_arg => undef,
                          traits   => ['Counter'],
                          handles  => {'_inc' . $attr => 'inc'},
                          default  => 0
            );
        }
    }
}
has nodeid => (isa     => 'Bit::Vector',
               is      => 'ro',
               builder => '_build_nodeid'
);

sub _build_nodeid {
    my $s = shift;

    # TODO: Base on DHT security extention: http://libtorrent.org/dht_sec.html
    AnyEvent::HTTP::http_get(
        'http://icanhazip.com',
        sub {
            chomp $_[0];
            $s->nodeid->from_Hex(
                unpack 'H*', join '',
                AnyEvent::Socket::parse_address($_[0]),    # Ext ipv4 address
                (map { chr rand 16 } 1 .. 16)
            );
        }
    );

    # alt services:
    # myip.dnsomatic.com
    # ipecho.net/plain
    # ipv4.icanhazip.com
    # bot.whatismyipaddress.com
    # www.myip.ru
    return Bit::Vector->new(160);
}
#
sub send {
    my ($s, $node, $packet, $reply) = @_;
    if (defined $s->ip_filter) {
        my $rule = $s->ip_filter->is_banned($node->host);
        if (defined $rule) {
            $s->trigger_ip_filter(
                           {protocol => ($node->ipv6 ? 'udp6' : 'udp4'),
                            severity => 'debug',
                            event    => 'ip_filter',
                            address => [$node->host, $node->port],
                            rule    => $rule,
                            message => 'Outgoing data was blocked by ipfilter'
                           }
            );
            return $s->routing_table->del_node($node);
        }
    }
    my $sock
        = $node->ipv6 && $s->has_udp6_sock ? $s->udp6_sock
        : $s->has_udp4_sock ? $s->udp4_sock
        :                     ();
    my $sent = $sock ? send $sock, $packet, 0, $node->sockaddr : return;
    if ($reply) {
        $s->_inc_send_replies_count;
        $s->_inc_send_replies_length($sent);
    }
    else {
        $s->_inc_send_requests_count;
        $s->_inc_send_requests_length($sent);
    }
    return $sent;
}
#
has ipv4_routing_table => (isa        => 'Net::BitTorrent::DHT::RoutingTable',
                           is         => 'ro',
                           lazy_build => 1,
                           handles    => {
                                       ipv4_add_node => 'add_node',
                                       ipv4_buckets  => 'buckets'
                           }
);
has ipv6_routing_table => (isa        => 'Net::BitTorrent::DHT::RoutingTable',
                           is         => 'ro',
                           lazy_build => 1,
                           handles    => {
                                       ipv6_add_node => 'add_node',
                                       ipv6_buckets  => 'buckets'
                           }
);

sub _build_ipv4_routing_table {
    Net::BitTorrent::DHT::RoutingTable->new(dht => shift);
}

sub _build_ipv6_routing_table {
    Net::BitTorrent::DHT::RoutingTable->new(dht => shift);
}

sub add_node {
    my ($s, $n) = @_;
    AnyEvent::Socket::resolve_sockaddr(
        $n->[0],
        $n->[1],
        0, undef, undef,
        sub {
            my $sockaddr = $_[0]->[3];
            return if !$sockaddr;
            $n
                = blessed $n ? $n
                : Net::BitTorrent::DHT::Node->new(
                           host          => $n->[0],
                           port          => $n->[1],
                           sockaddr      => $sockaddr,
                           routing_table => (
                               length $sockaddr == 28 ? $s->ipv6_routing_table
                               : $s->ipv4_routing_table
                           )
                );
            ($n->ipv6 ?
                 $s->ipv6_routing_table->add_node($n)
             : $s->ipv4_routing_table->add_node($n)
                )->find_node($s->nodeid)
                if !$s->nodeid->is_empty;
        }
    );
}
after 'BUILD' => sub {
    my ($self, $args) = @_;
    return if !defined $args->{'boot_nodes'};
    $self->add_node($_) for @{$args->{'boot_nodes'}};
};
#
for my $type (qw[get_peers announce_peer find_node]) {
    has "_${type}_quests" => (isa      => 'ArrayRef[Ref]',
                              is       => 'ro',
                              init_arg => undef,
                              traits   => ['Array'],
                              handles  => {
                                          "add_${type}_quest"   => 'push',
                                          "${type}_quests"      => 'elements',
                                          "get_${type}_quest"   => 'get',
                                          "grep_${type}_quests" => 'grep',
                                          "map_${type}_quests"  => 'map'
                              },
                              default => sub { [] }
    );
    after "add_${type}_quest" => sub {
        Scalar::Util::weaken $_[0]->{"_${type}_quests"}->[-1];
    };
}
#
sub get_peers {
    my ($self, $infohash, $code) = @_;
    Scalar::Util::weaken $self;
    my $quest = [
        $infohash,
        $code,
        [],
        AE::timer(
            0,
            0.25 * 60,
            sub {
                return if !$self;
                for my $rt ($self->ipv6_routing_table,
                            $self->ipv4_routing_table)
                {   for my $node (@{$rt->nearest_bucket($infohash)->nodes}) {
                        $node->get_peers($infohash);
                    }
                }
            }
        )
    ];
    $self->add_get_peers_quest($quest);
    return $quest;
}

sub announce_peer {
    my ($self, $infohash, $port, $code) = @_;
    Scalar::Util::weaken $self;
    my $quest = [
        $infohash,
        $code, $port,
        [],
        AE::timer(
            10,
            0.25 * 60,
            sub {
                return if !$self;
                for my $rt ($self->ipv6_routing_table,
                            $self->ipv4_routing_table)
                {   for my $node (@{$rt->nearest_bucket($infohash)->nodes}) {
                        $node->announce_peer($infohash, $port);
                    }
                }
            }
        )
    ];
    $self->add_announce_peer_quest($quest);
    return $quest;
}

sub find_node {
    my ($self, $target, $code) = @_;
    Scalar::Util::weaken $self;
    my $quest = [
        $target, $code,
        [],
        AE::timer(
            0,
            0.25 * 60,
            sub {
                return if !$self;
                for my $rt ($self->ipv6_routing_table,
                            $self->ipv4_routing_table)
                {   for my $node (@{$rt->nearest_bucket($target)->nodes}) {
                        $node->find_node($target);
                    }
                }
            }
        )
    ];
    $self->add_find_node_quest($quest);
    return $quest;
}
#
sub _on_udp6_in {
    my ($self, $sock, $sockaddr, $host, $port, $data, $flags) = @_;
    my $packet = bdecode $data;
    if (   !$packet
        || !ref $packet
        || ref $packet ne 'HASH'
        || !keys %$packet)
    {   $self->_inc_recv_invalid_count;
        $self->_inc_recv_invalid_length(length $data);
        return;
    }
    my $node = $self->ipv6_routing_table->find_node_by_sockaddr($sockaddr);
    if (!defined $node) {
        $node =
            Net::BitTorrent::DHT::Node->new(
                                   host          => $host,
                                   port          => $port,
                                   routing_table => $self->ipv6_routing_table,
                                   sockaddr      => $sockaddr
            );
    }
}

sub _on_udp4_in {
    my ($self, $sock, $sockaddr, $host, $port, $data, $flags) = @_;
    my $packet = bdecode $data;
    if (   !$packet
        || !ref $packet
        || ref $packet ne 'HASH'
        || !keys %$packet
        || !defined $packet->{'y'})
    {   $self->_inc_recv_invalid_count;
        $self->_inc_recv_invalid_length(length $data);
        return;
    }
    my $node = $self->ipv4_routing_table->find_node_by_sockaddr($sockaddr);
    if (!defined $node) {
        $node =
            Net::BitTorrent::DHT::Node->new(
                                   host          => $host,
                                   port          => $port,
                                   routing_table => $self->ipv4_routing_table,
                                   sockaddr      => $sockaddr
            );
    }

    # Basic identity checks
    # TODO - if v is set, make sure it matches
    #      - make note of changes in nodeid/sockaddr combinations
    return $node->routing_table->del_node($node)
        if $node->has_nodeid    # Wait, this is me!
        && ($node->nodeid->Lexicompare($self->nodeid) == 0);
    $node->touch;
    #
    if ($packet->{'y'} eq 'r') {
        if (defined $packet->{'r'}) {
            if ($node->is_expecting($packet->{'t'})) {
                $self->_inc_recv_replies_count;
                $self->_inc_recv_replies_length(length $data);
                $node->_v($packet->{'v'})
                    if !$node->has_v && defined $packet->{'v'};
                my $req = $node->del_request($packet->{'t'}); # For future ref
                $req->{'cb'}->($packet, $host, $port)
                    if defined $req->{'cb'};
                my $type = $req->{'type'};
                $node->_set_nodeid(Bit::Vector->new_Hex(
                                        160, unpack 'H*', $packet->{'r'}{'id'}
                                   )
                ) if !$node->has_nodeid;    # Adds node to router table
                if ($type eq 'ping') {
                }
                elsif ($type eq 'find_node') {
                    my ($quest) = $self->grep_find_node_quests(
                        sub {
                            defined $_
                                && $req->{'target'}->equal($_->[0]);
                        }
                    );
                    return if !defined $quest;
                    my @nodes
                        = map { uncompact_ipv4($_) }
                        ref $packet->{'r'}{'nodes'}
                        ?
                        @{$packet->{'r'}{'nodes'}}
                        : $packet->{'r'}{'nodes'};
                    {
                        my %seen = ();
                        @{$quest->[2]}
                            = grep { !$seen{$_->[0]}{$_->[1]}++ }
                            @{$quest->[2]}, @nodes;
                    }
                    $self->ipv4_add_node($_) for @nodes;
                    $quest->[1]->($quest->[0], $node, \@nodes);
                }
                elsif ($type eq 'get_peers') {

                    # TODO - store token by id
                    if (!(    defined $packet->{'r'}{'nodes'}
                           || defined $packet->{'r'}{'values'}
                        )
                        )
                    {    # Malformed packet
                        die '...';
                    }
                    if (defined $packet->{'r'}{'nodes'}) {
                        for my $new_node (    # XXX - may be ipv6
                                       uncompact_ipv4($packet->{'r'}{'nodes'})
                            )
                        {   $new_node = $self->ipv4_add_node($new_node);
                            $new_node->get_peers($req->{'info_hash'})
                                if $new_node;
                        }
                        if (defined $packet->{'r'}{'values'}) {    # peers
                            my ($quest) = $self->grep_get_peers_quests(
                                sub {
                                    defined $_
                                        && $req->{'info_hash'}
                                        ->equal($_->[0]);
                                }
                            );
                            return if !defined $quest;
                            my @peers
                                = map { uncompact_ipv4($_) }
                                ref $packet->{'r'}{'values'}
                                ?
                                @{$packet->{'r'}{'values'}}
                                : $packet->{'r'}{'values'};
                            {
                                my %seen = ();
                                @{$quest->[2]}
                                    = grep { !$seen{$_->[0]}{$_->[1]}++ }
                                    @{$quest->[2]}, @peers;
                            }
                            $quest->[1]
                                ->($req->{'info_hash'}, $node, \@peers);
                        }
                        if (defined $packet->{'r'}{'token'})
                        {    # for announce_peer
                            $node->_set_announce_peer_token_in(
                                                  $req->{'info_hash'}->to_Hex,
                                                  $packet->{'r'}{'token'});
                        }
                    }
                }
                elsif ($type eq 'announce_peer') {
                    my ($quest) = $self->grep_announce_peer_quests(
                        sub {
                            defined $_
                                && $req->{'info_hash'}->equal($_->[0]);
                        }
                    );
                    return if !defined $quest;
                    push @{$quest->[3]}, [$node->host, $node->port];
                    $quest->[1]->($req->{'info_hash'}, $node, $quest->[2]);
                    $node->get_prev_get_peers(0)
                        if    # seek peers sooner than we should
                        $node->defined_prev_get_peers($req->{'info_hash'});
                }
                else {
                    warn sprintf '%s:%d', $node->host, $node->port;

                    #ddx $packet;
                    #ddx $req;
                    #...;
                }
            }
            else {    # A reply we are not expecting. Strange.
                $node->inc_fail;
                $self->_inc_recv_invalid_count;
                $self->_inc_recv_invalid_length(length $data);

                #...;
            }
        }
    }
    elsif ($packet->{'y'} eq 'q' && defined $packet->{'a'}) {
        $self->_inc_recv_requests_count;
        $self->_inc_recv_requests_length(length $data);
        my $type = $packet->{'q'};
        $node->_set_nodeid(
                 Bit::Vector->new_Hex(160, unpack 'H*', $packet->{'a'}{'id'}))
            if !$node->has_nodeid;    # Adds node to router table
        if ($type eq 'ping' && defined $packet->{'t'}) {
            return $node->_reply_ping($packet->{'t'});
        }
        elsif ($type eq 'get_peers'
               && defined $packet->{'a'}{'info_hash'})
        {   return
                $node->_reply_get_peers(
                              $packet->{'t'},
                              Bit::Vector->new_Hex(160, unpack 'H*',
                                                   $packet->{'a'}{'info_hash'}
                              )
                );
        }
        elsif ($type eq 'find_node'
               && defined $packet->{'a'}{'target'})
        {   return
                $node->_reply_find_node(
                                 $packet->{'t'},
                                 Bit::Vector->new_Hex(160, unpack 'H*',
                                                      $packet->{'a'}{'target'}
                                 )
                );
        }
        elsif ($type eq 'announce_peer'
               && defined $packet->{'a'}{'info_hash'})
        {   return
                $node->_reply_announce_peer(
                              $packet->{'t'},
                              Bit::Vector->new_Hex(160, unpack 'H*',
                                                   $packet->{'a'}{'info_hash'}
                              ),
                              $packet->{'a'},
                );
        }
        else {
            die '...';
        }
    }
    elsif ($packet->{'y'} eq 'q' && defined $packet->{'a'}) {
        warn sprintf 'Error from %s:%d', $node->host, $node->port;

        #use Data::Dump;
        #ddx $packet;
    }
    else {
        #use Data::Dump;
        #warn sprintf '%s:%d', $node->host, $node->port;
        #ddx $packet;
        #ddx $data;
        #...;
        # TODO: ID checks against $packet->{'a'}{'id'}
    }
}

sub dump_ipv4_buckets {
    my @return = _dump_buckets($_[0], $_[0]->ipv4_routing_table());
    return wantarray ? @return : sub { say $_ for @_ }
        ->(@return);
}

sub dump_ipv6_buckets {
    my @return = _dump_buckets($_[0], $_[0]->ipv6_routing_table());
    return wantarray ? @return : sub { say $_ for @_ }
        ->(@return);
}

sub _dump_buckets {
    my ($self, $routing_table) = @_;
    my @return = sprintf 'Num buckets: %d. My DHT ID: %s',
        $routing_table->count_buckets, $self->nodeid->to_Hex;
    my ($x, $t_primary, $t_backup) = (0, 0, 0);
    for my $bucket (@{$routing_table->buckets}) {
        push @return, sprintf 'Bucket %s: %s (replacement cache: %d)',
            $x++, $bucket->floor->to_Hex, $bucket->count_backup_nodes;
        for my $node (@{$bucket->nodes}) {
            push @return,
                sprintf '    %s %s:%d fail:%d seen:%d age:%s ver:%s',
                $node->nodeid->to_Hex, $node->host,
                $node->port, $node->fail || 0, $node->seen,
                __duration(time - $node->birth), $node->v || '?';
        }
        $t_primary += $bucket->count_nodes;
        $t_backup  += $bucket->count_backup_nodes;
    }
    push @return, sprintf 'Total peers: %d (in replacement cache %d)',
        $t_primary + $t_backup, $t_backup;
    push @return, sprintf 'Outstanding add nodes: %d',
        scalar $routing_table->outstanding_add_nodes;
    push @return,
        sprintf
        'Received: %d requests (%s), %d replies (%s), %d invalid (%s)',
        $self->_recv_requests_count,
        __data($self->_recv_requests_length),
        $self->_recv_replies_count,
        __data($self->_recv_replies_length),
        $self->_recv_invalid_count,
        __data($self->_recv_invalid_length);
    push @return, sprintf 'Sent: %d requests (%s), %d replies (%s)',
        $self->_send_requests_count,
        __data($self->_send_requests_length),
        $self->_send_replies_count,
        __data($self->_send_replies_length);
    return @return;
}
has 'port' => (is      => 'ro',
               isa     => 'Int|ArrayRef[Int]',
               builder => '_build_port',
               writer  => '_set_port'
);

sub _build_port {
    0;    # Let the system pick
}
my %_sock_types = (4 => '0.0.0.0', 6 => '::');
for my $ipv (keys %_sock_types) {
    has 'udp'
        . $ipv => (is         => 'ro',
                   init_arg   => undef,
                   isa        => 'Maybe[Object]',
                   lazy_build => 1,
                   writer     => '_set_udp' . $ipv
        );
    has 'udp'
        . $ipv
        . '_sock' => (is         => 'ro',
                      init_arg   => undef,
                      isa        => 'GlobRef',
                      lazy_build => 1,
                      weak_ref   => 1,
                      writer     => '_set_udp' . $ipv . '_sock'
        );
    has 'udp'
        . $ipv
        . '_host' => (is      => 'ro',
                      isa     => 'Str',
                      default => $_sock_types{$ipv},
                      writer  => '_set_udp' . $ipv . '_host'
        );
}
#
has 'ip_filter' => (is       => 'ro',
                    isa      => 'Maybe[Config::IPFilter]',
                    init_arg => undef,
                    builder  => '_build_ip_filter'
);

sub _build_ip_filter {
    return eval('require Config::IPFilter;') ? Config::IPFilter->new() : ();
}

sub _build_udp6 {
    my $s = shift;
    my ($server, $actual_socket, $actual_host, $actual_port);
    for my $port (ref $s->port ? @{$s->port} : $s->port) {
        $server = server(
            $s->udp6_host,
            $port,
            sub { $s->_on_udp6_in(@_); },
            sub {
                ($actual_socket, $actual_host, $actual_port) = @_;

                #if ($self->port != $port) { ...; }
                $s->_set_udp6_sock($actual_socket);
                $s->_set_udp6_host($actual_host);
                $s->_set_port($actual_port);
            },
            'udp'
        );
        last if defined $server;
    }
    if ($server) {
        $s->trigger_listen_success(
                      {port     => $actual_port,
                       protocol => 'udp6',
                       severity => 'debug',
                       event    => 'listen_success',
                       message  => sprintf
                           'Bound UDP port %d to the outside world over IPv6',
                       $actual_port
                      }
        );
    }
    else {
        $s->trigger_listen_failure(
                {port     => $s->port,
                 protocol => 'udp6',
                 severity => 'fatal',
                 event    => 'listen_failure',
                 message =>
                     'Failed to bind UDP port for the outside world over IPv6'
                }
        );
    }
    return $server;
}

sub _build_udp4 {
    my $s = shift;
    my ($server, $actual_socket, $actual_host, $actual_port);
    for my $port (ref $s->port ? @{$s->port} : $s->port) {
        $server = server(
            $s->udp4_host,
            $port,
            sub { $s->_on_udp4_in(@_); },
            sub {
                ($actual_socket, $actual_host, $actual_port) = @_;

                #if ($self->port != $port) { ...; }
                $s->_set_udp4_sock($actual_socket);
                $s->_set_udp4_host($actual_host);
                $s->_set_port($actual_port);
            },
            'udp'
        );
        last if defined $server;
    }
    if ($server) {
        $s->trigger_listen_success(
                      {port     => $actual_port,
                       protocol => 'udp4',
                       severity => 'debug',
                       event    => 'listen_success',
                       message  => sprintf
                           'Bound UDP port %d to the outside world over IPv4',
                       $actual_port
                      }
        );
    }
    else {
        $s->trigger_listen_failure(
                {port     => $s->port,
                 protocol => 'udp4',
                 severity => 'fatal',
                 event    => 'listen_failure',
                 message =>
                     'Failed to bind UDP port for the outside world over IPv4'
                }
        );
    }
    return $server;
}
around '_on_udp4_in' => sub {
    my ($c, $s, $sock, $sockaddr, $host, $port, $data, $flags) = @_;
    if (defined $s->ip_filter) {
        my $rule = $s->ip_filter->is_banned($host);
        if (defined $rule) {
            $s->trigger_ip_filter(
                           {protocol => 'udp4',
                            severity => 'debug',
                            event    => 'ip_filter',
                            address  => [$host, $port],
                            rule     => $rule,
                            message => 'Incoming data was blocked by ipfilter'
                           }
            );
            return;
        }
    }
    $c->($s, $sock, $sockaddr, $host, $port, $data, $flags);
};
around '_on_udp6_in' => sub {
    my ($c, $s, $sock, $sockaddr, $host, $port, $data, $flags) = @_;
    my $rule = $s->ip_filter->is_banned($host);
    if (defined $rule) {
        $s->trigger_ip_filter(
                           {protocol => 'udp6',
                            severity => 'debug',
                            event    => 'ip_filter',
                            address  => [$host, $port],
                            rule     => $rule,
                            message => 'Incoming data was blocked by ipfilter'
                           }
        );
        return;
    }
    $c->($s, $sock, $sockaddr, $host, $port, $data, $flags);
};

# Callback system
sub _build_callback_no_op {
    sub {1}
}
has "on_$_" => (isa        => 'CodeRef',
                is         => 'ro',
                traits     => ['Code'],
                handles    => {"trigger_$_" => 'execute_method'},
                lazy_build => 1,
                builder    => '_build_callback_no_op',
                clearer    => "_no_$_",
                weak_ref   => 1
    )
    for qw[
    listen_failure listen_success
];

sub server ($$&;&$) {
    my ($host, $port, $callback, $prepare, $proto) = @_;
    $proto //= 'tcp';
    my $sockaddr = Net::BitTorrent::DHT::sockaddr($host, $port) or return;
    my $type = length $sockaddr == 16 ? PF_INET : PF_INET6;
    socket my ($socket), $type,
        $proto eq 'udp' ? SOCK_DGRAM : SOCK_STREAM, getprotobyname($proto)
        or return;

    # - What is the difference between SO_REUSEADDR and SO_REUSEPORT?
    #    [http://www.unixguide.net/network/socketfaq/4.11.shtml]
    # SO_REUSEPORT is undefined on Win32 and pre-2.4.15 Linux distros.
    setsockopt $socket, SOL_SOCKET, SO_REUSEADDR, pack('l', 1)
        or return
        if $^O !~ m[Win32];
    return if !bind $socket, $sockaddr;
    my $listen = 8;
    if (defined $prepare) {
        my ($_port, $packed_ip)
            = Net::BitTorrent::DHT::unpack_sockaddr(getsockname $socket);
        my $return = $prepare->($socket, paddr2ip($packed_ip), $_port);
        $listen = $return if defined $return;
    }
    require AnyEvent::Util;
    AnyEvent::Util::fh_nonblocking $socket, 1;
    listen $socket, $listen or return if $proto ne 'udp';
    return AE::io(
        $socket, 0,
        $proto eq 'udp' ?
            sub {
            my $flags = 0;
            if ($socket
                && (my $peer = recv $socket, my ($data), 16 * 1024, $flags))
            {   my ($service, $host)
                    = Net::BitTorrent::DHT::unpack_sockaddr($peer);
                $callback->($socket, $peer, paddr2ip($host), $service,
                            $data, $flags
                );
            }
            }
        : sub {
            while ($socket
                   && (my $peer = accept my ($fh), $socket))
            {   my ($service, $host)
                    = Net::BitTorrent::DHT::unpack_sockaddr($peer);
                $callback->($fh, $peer, paddr2ip($host), $service);
            }
        }
    );
}

sub paddr2ip ($) {
    return inet_ntoa($_[0]) if length $_[0] == 4;    # ipv4
    return inet_ntoa($1)
        if length $_[0] == 16
        && $_[0] =~ m[^\0{10}\xff{2}(.{4})$];        # ipv4
    return unless length($_[0]) == 16;
    my @hex = (unpack('n8', $_[0]));
    $hex[9] = $hex[7] & 0xff;
    $hex[8] = $hex[7] >> 8;
    $hex[7] = $hex[6] & 0xff;
    $hex[6] >>= 8;
    my $return = sprintf '%X:%X:%X:%X:%X:%X:%D:%D:%D:%D', @hex;
    $return =~ s|(0+:)+|:|x;
    $return =~ s|^0+    ||x;
    $return =~ s|^:+    |::|x;
    $return =~ s|::0+   |::|x;
    $return =~ s|^::(\d+):(\d+):(\d+):(\d+)|$1.$2.$3.$4|x;
    return $return;
}

sub __duration ($) {
    my %dhms = (d => int($_[0] / (24 * 60 * 60)),
                h => ($_[0] / (60 * 60)) % 24,
                m => ($_[0] / 60) % 60,
                s => $_[0] % 60
    );
    return join ' ', map { $dhms{$_} ? $dhms{$_} . $_ : () } sort keys %dhms;
}

sub unpack_sockaddr ($) {
    my ($packed_host) = @_;
    return length $packed_host == 28 ?
        (unpack('SnLa16L', $packed_host))[1, 3]
        : unpack_sockaddr_in($packed_host);
}

sub sockaddr ($$) {
    my $resolver = AE::cv();
    AnyEvent::Socket::resolve_sockaddr(
        $_[0],
        $_[1],
        0, undef, undef,
        sub {
            $resolver->send($_[0]->[3]);
        }
    );
    return $resolver->recv();
}

sub __data($) {
          $_[0] >= 1073741824 ? sprintf('%0.2f GB', $_[0] / 1073741824)
        : $_[0] >= 1048576    ? sprintf('%0.2f MB', $_[0] / 1048576)
        : $_[0] >= 1024       ? sprintf('%0.2f KB', $_[0] / 1024)
        :                       $_[0] . ' bytes';
}
1;

=pod

=head1 NAME

Net::BitTorrent::DHT - Kademlia-like DHT Node for BitTorrent

=head1 Synopsis

    use Net::BitTorrent::DHT;
    use AnyEvent;
    use Bit::Vector;
    # Standalone node with user-defined port and boot_nodes
    my $dht = Net::BitTorrent::DHT->new(
          port => [1337 .. 1340, 0],
          boot_nodes =>
              [['router.bittorrent.com', 6881], ['router.utorrent.com', 6881]]
    );

    my $peer_quest
    = $dht->get_peers(Bit::Vector->new_Hex('ab97a7bca78f2628380e6609a8241a7fb02aa981'), \&dht_cb);

    # tick, tick, tick, ...
    AnyEvent->condvar->recv;

    sub dht_cb {
        my ($infohash, $node, $peers) = @_;
        printf "We found %d peers for %s from %s:%d via DHT\n\t%s\n",
            scalar(@$peers),
            $infohash->to_Hex, $node->host, $node->port,
            join ', ', map { sprintf '%s:%d', @$_ } @$peers;
    }

=head1 Description

BitTorrent uses a "distributed sloppy hash table" (DHT) for storing peer
contact information for "trackerless" torrents. In effect, each peer becomes a
tracker. The protocol is based on L<Kademila|/Kademlia> and is implemented
over UDP.

=head1 Methods

L<Net::BitTorrent::DHT|Net::BitTorrent::DHT>'s API is simple but powerful.
...well, I think so anyway.

=head1 Net::BitTorrent::DHT->new( )

The constructor accepts a number different arguments which all greatly affect
the function of your DHT node. Any combination of the following arguments may
be used during construction.

For brevity, the following examples assume you are building a
L<standalone node|Net::BitTorrent::DHT::Standalone> (for reasearch, etc.).

=head2 Net::BitTorrent::DHT->new( nodeid => ... )

During construction, our local DHT nodeID can be set during construction. This
is mostly useful when creating a
L<standalone DHT node|Net::BitTorrent::DHT::Standalone>.

    use Net::BitTorrent::DHT;
    # Bit::Vector object
    use Bit::Vector;
    my $node_c = Net::BitTorrent::DHT->new(
        nodeid => Bit::Vector->new_Hex( 160, 'ABCD' x 10 )
    );
    # A SHA1 digest
    use Digest::SHA;
    my $node_d = Net::BitTorrent::DHT->new(
            nodeid => Bit::Vector->new_Hex( 160, Digest::SHA::sha1( $possibly_random_value ) )
    );

Note that storing and reusing DHT nodeIDs over a number of sessions may seem
advantagious (as if you had a "reserved parking place" in the DHT network) but
will likely not improve performance as unseen nodeIDs are removed from remote
routing tables after a half hour.

NodeIDs, are 160-bit integers.

=head2 Net::BitTorrent::DHT->new( port => ... )

Opens a specific UDP port number to the outside world on both IPv4 and IPv6.

    use Net::BitTorrent::DHT;
    # A single possible port
    my $node_a = Net::BitTorrent::DHT->new( port => 1123 );
    # A list of ports
    my $node_b = Net::BitTorrent::DHT->new( port => [1235 .. 9875] );

Note that when handed a list of ports, they are each tried until we are able
to bind to the specific port.

=head1 Net::BitTorrent::DHT->find_node( $target, $callback )

This method asks for remote nodes with nodeIDs closer to our target. As the
remote nodes respond, the callback is called with the following arguments:

=over

=item * target

This is the target nodeid. This is useful when you've set the same callback
for multiple, concurrent C<find_node( )> L<quest|/"Quests and Callbacks">.

Targets are 160-bit L<Bit::Vector|Bit::Vector> objects.

=item * node

This is a blessed object. TODO.

=item * nodes

This is a list of ip:port combinations the remote node claims are close to our
target.

=back

A single C<find_node> L<quest|Net::BitTorrent::Notes/"Quests and Callbacks">
is an array ref which contains the following data:

=over

=item * target

This is the target nodeID.

=item * coderef

This is the callback triggered as we locate new peers.

=item * nodes

This is a list of nodes we have announced to so far.

=item * timer

This is an L<AnyEvent|AnyEvent> timer which is triggered every few minutes.

Don't modify this.

=back

=head1 Net::BitTorrent::DHT->get_peers( $infohash, $callback )

This method initiates a search for peers serving a torrent with this infohash.
As they are found, the callback is called with the following arguments:

=over

=item * infohash

This is the infohash related to these peers. This is useful when you've set
the same callback for multiple, concurrent C<get_peers( )> quests. This is a
160-bit L<Bit::Vector|Bit::Vector> object.

=item * node

This is a blessed object. TODO.

=item * peers

This is an array ref of peers sent to us by aforementioned remote node.

=back

A single C<get_peers> L<quest|Net::BitTorrent::Notes/"Quests and Callbacks">
is an array ref which contains the following data:

=over

=item * infohash

This is the infohash related to these peers. This is a 160-bit
L<Bit::Vector|Bit::Vector> object.

=item * coderef

This is the callback triggered as we locate new peers.

=item * peers

This is a compacted list of all peers found so far. This is probably more
useful than the list passed to the callback.

=item * timer

This is an L<AnyEvent|AnyEvent> timer which is triggered every five minutes.
When triggered, the node requests new peers from nodes in the bucket nearest
to the infohash.

Don't modify this.

=back

=head1 Net::BitTorrent::DHT->B<announce_peer>( $infohash, $port, $callback )

This method announces that the peer controlling the querying node is
downloading a torrent on a port. These outgoing queries are sent to nodes
'close' to the target infohash. As the remote nodes respond, the callback is
called with the following arguments:

=over

=item * infohash

This is the infohash related to this announcment. This is useful when you've
set the same callback for multiple, concurrent C<announce_peer( )>
L<quest|/"Quests and Callbacks">. Infohashes are 160-bit
L<Bit::Vector|Bit::Vector> objects.

=item * port

This is port you defined above.

=item * node

This is a blessed object. TODO.

=back

A single C<announce_peer> L<quest|/"Quests and Callbacks"> is an array ref
which contains the following data:

=over

=item * infohash

This is the infohash related to these peers. This is a 160-bit
L<Bit::Vector|Bit::Vector> object.

=item * coderef

This is the callback triggered as we locate new peers.

=item * port

This is port you defined above.

=item * nodes

This is a list of nodes we have announced to so far.

=item * timer

This is an L<AnyEvent|AnyEvent> timer which is triggered every few minutes.

Don't modify this.

=back

C<announce_peer> queries require a token sent in reply to a C<get_peers> query
so they should be used together.

=for meditation
Should I automatically send get_peers queries before an announce if the token
is missing?

    use Net::BitTorrent::DHT;
    my $node = Net::BitTorrent::DHT->new( );
    my $quest_a = $dht->announce_peer(Bit::Vector->new_Hex('A' x 40), 6881, \&dht_cb);
    my $quest_b = $dht->announce_peer(Bit::Vector->new_Hex('1' x 40), 9585, \&dht_cb);

    sub dht_cb {
        my ($infohash, $port, $node) = @_;
        say sprintf '%s:%d now knows we are serving %s on port %d',
            $node->host, $node->port, $infohash->to_Hex, $port;
    }

=head1 Net::BitTorrent::DHT->dump_ipv4_buckets( )

This is a quick utility method which returns or prints (depending on context)
a list of the IPv4-based routing table's bucket structure.

    use Net::BitTorrent::DHT;
    my $node = Net::BitTorrent::DHT->new( );
    # After some time has passed...
    $node->dump_ipv4_buckets; # prints to STDOUT with say
    my @dump = $node->dump_ipv4_buckets; # returns list of lines

=head1 Net::BitTorrent::DHT->dump_ipv6_buckets( )

This is a quick utility method which returns or prints (depending on context)
a list of the IPv6-based routing table's bucket structure.

    use Net::BitTorrent::DHT;
    my $node = Net::BitTorrent::DHT->new( );
    # After some time has passed...
    $node->dump_ipv6_buckets; # prints to STDOUT with say
    my @dump = $node->dump_ipv6_buckets; # returns list of lines

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
