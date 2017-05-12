package Redis::Cluster;

use strict;
use warnings;

use Carp 'croak';
use Data::Dumper;
use Digest::CRC 'crc';
use List::MoreUtils qw(any bsearch);
use Params::Validate ':all';
use Redis;
use Try::Tiny;

{
  $Data::Dumper::Indent = 0;
  $Data::Dumper::Terse  = 1;
}

use constant {
  # Default maximum number of slot redirects.
  DEFAULT_MAX_REDIRECTS  => 5,
  # Default cluster state refresh interval (in seconds).
  # If set to zero, cluster state will be updated only on MOVED redirect.
  DEFAULT_REFRESH        => 0,
  # Default maximum internal queue size (used in 'multi' mode)
  DEFAULT_MAX_QUEUE_SIZE => 10,
  # Minimum number of nodes
  MIN_NODES              => 3,
  # Total slots in cluster. Used for execution commands
  # without keys in arguments on random nodes.
  TOTAL_SLOTS            => 0x4000,
  # Redis responses
  REDIS_RESPONSE_OK      => 'OK',
  REDIS_RESPONSE_QUEUED  => 'QUEUED',
};

our $VERSION = '0.14';
our $AUTOLOAD;

my %NODES;

# Supported commands.
# - 'key' may be a Scalar (index of first key in command
#   arguments) or CodeRef (should return key value)
# - 'allow_slave' flag means that command may be executed
#   on a slave node
my %CMD = (
  append          => { key => 0 },
  bitcount        => { key => 0, allow_slave => 1 },
  bitop           => { key => 1 },
  bitpos          => { key => 0, allow_slave => 1 },
  blpop           => { key => 0 },
  brpop           => { key => 0 },
  brpoplpush      => { key => 0 },
  debug_object    => { key => 0 },
  decr            => { key => 0 },
  decrby          => { key => 0 },
  del             => { key => 0 },
  discard         => {
    key => sub {
      my $self = shift(@_);

      croak('[discard] without [multi] is not allowed') unless $self->{_multi};
      return $self->{_multi_key};
    },
  },
  dump            => { key => 0, allow_slave => 1 },
  eval            => {
    key => sub {
      my $self = shift(@_);
      my ($args) = @_;

      return $args->[1] ? $args->[2] : undef;
    },
  },
  evalsha         => {
    key => sub {
      my $self = shift(@_);
      my ($args) = @_;

      return $args->[1] ? $args->[2] : undef;
    },
  },
  exec            => {
    key => sub {
      my $self = shift(@_);

      croak('[exec] without [multi] is not allowed') unless $self->{_multi};
      return $self->{_multi_key};
    },
  },
  exists          => { key => 0, allow_slave => 1 },
  expire          => { key => 0 },
  expireat        => { key => 0 },
  geoadd          => { key => 0 },
  geodist         => { key => 0, allow_slave => 1 },
  geohash         => { key => 0, allow_slave => 1 },
  geopos          => { key => 0, allow_slave => 1 },
  georadius       => { key => 0, allow_slave => 1 },
  georadiusmember => { key => 0, allow_slave => 1 },
  get             => { key => 0, allow_slave => 1 },
  getbit          => { key => 0, allow_slave => 1 },
  getrange        => { key => 0, allow_slave => 1 },
  getset          => { key => 0 },
  hdel            => { key => 0 },
  hexists         => { key => 0, allow_slave => 1 },
  hget            => { key => 0, allow_slave => 1 },
  hgetall         => { key => 0, allow_slave => 1 },
  hincrby         => { key => 0 },
  hincrbyfloat    => { key => 0 },
  hkeys           => { key => 0, allow_slave => 1 },
  hlen            => { key => 0, allow_slave => 1 },
  hmget           => { key => 0, allow_slave => 1 },
  hmset           => { key => 0 },
  hscan           => { key => 0, allow_slave => 1 },
  hset            => { key => 0 },
  hsetnx          => { key => 0 },
  hstrlen         => { key => 0, allow_slave => 1 },
  hvals           => { key => 0, allow_slave => 1 },
  incr            => { key => 0 },
  incrby          => { key => 0 },
  incrbyfloat     => { key => 0 },
  lindex          => { key => 0, allow_slave => 1 },
  linsert         => { key => 0 },
  llen            => { key => 0, allow_slave => 1 },
  lpop            => { key => 0 },
  lpush           => { key => 0 },
  lpushx          => { key => 0 },
  lrange          => { key => 0, allow_slave => 1 },
  lrem            => { key => 0 },
  lset            => { key => 0 },
  ltrim           => { key => 0 },
  mget            => { key => 0, allow_slave => 1 },
  move            => { key => 0 },
  mset            => { key => 0 },
  msetnx          => { key => 0 },
  multi           => {
    key => sub {
      my $self = shift(@_);

      croak("Nested [multi] is not allowed") if $self->{_multi};
      return $self->{_watch} ? $self->{_multi_key} : undef;
    },
  },
  persist         => { key => 0 },
  pexpire         => { key => 0 },
  pexpireat       => { key => 0 },
  pfadd           => { key => 0 },
  pfcount         => { key => 0, allow_slave => 1 },
  pfmerge         => { key => 0 },
  psetex          => { key => 0 },
  pttl            => { key => 0, allow_slave => 1 },
  rename          => { key => 0 },
  renamenx        => { key => 0 },
  restore         => { key => 0 },
  rpop            => { key => 0 },
  rpoplpush       => { key => 0 },
  rpush           => { key => 0 },
  rpushx          => { key => 0 },
  sadd            => { key => 0 },
  scard           => { key => 0, allow_slave => 1 },
  sdiff           => { key => 0, allow_slave => 1 },
  sdiffstore      => { key => 0 },
  set             => { key => 0 },
  setbit          => { key => 0 },
  setex           => { key => 0 },
  setnx           => { key => 0 },
  setrange        => { key => 0 },
  sinter          => { key => 0, allow_slave => 1 },
  sinterstore     => { key => 0 },
  sismember       => { key => 0, allow_slave => 1 },
  smembers        => { key => 0, allow_slave => 1 },
  smove           => { key => 0 },
  sort            => { key => 0, allow_slave => 1 },
  spop            => { key => 0 },
  srandmember     => { key => 0, allow_slave => 1 },
  srem            => { key => 0 },
  sscan           => { key => 0, allow_slave => 1 },
  strlen          => { key => 0, allow_slave => 1 },
  sunion          => { key => 0, allow_slave => 1 },
  sunionstore     => { key => 0 },
  ttl             => { key => 0, allow_slave => 1 },
  type            => { key => 0, allow_slave => 1 },
  unwatch         => {
    key => sub {
      my $self = shift(@_);
      return $self->{_watch} ? $self->{_multi_key} : undef;
    },
  },
  wait            => {
    key => sub {
      my $self = shift(@_);

      if (defined($self->{_last_key})) { return $self->{_last_key}; }
      else { croak('[wait] cannot select node'); }
    },
  },
  watch           => {
    key => sub {
      my $self = shift(@_);
      my ($args) = @_;

      return $self->{_watch} ? $self->{_multi_key} : $args->[0];
    },
  },
  zadd             => { key => 0 },
  zcard            => { key => 0, allow_slave => 1 },
  zcount           => { key => 0, allow_slave => 1 },
  zincrby          => { key => 0 },
  zinterstore      => { key => 0 },
  zlexcount        => { key => 0, allow_slave => 1 },
  zrange           => { key => 0, allow_slave => 1 },
  zrangebylex      => { key => 0, allow_slave => 1 },
  zrangebyscore    => { key => 0, allow_slave => 1 },
  zrank            => { key => 0, allow_slave => 1 },
  zrem             => { key => 0 },
  zremrangebylex   => { key => 0 },
  zremrangebyrank  => { key => 0 },
  zremrangebyscore => { key => 0 },
  zrevrange        => { key => 0, allow_slave => 1 },
  zrevrangebylex   => { key => 0, allow_slave => 1 },
  zrevrangebyscore => { key => 0, allow_slave => 1 },
  zrevrank         => { key => 0, allow_slave => 1 },
  zscan            => { key => 0, allow_slave => 1 },
  zscore           => { key => 0, allow_slave => 1 },
  zunionstore      => { key => 0 },
);

# Validation spec
my %SPEC = (
  new => {
    server         => {
      type    => SCALAR | ARRAYREF,
      default => $ENV{REDIS_CLUSTER} || '',
    },
    refresh        => {
      type      => SCALAR,
      regex     => qr/^\d+$/,
      default   => DEFAULT_REFRESH,
    },
    max_redirects  => {
      type      => SCALAR,
      regex     => qr/^\d+$/,
      default   => DEFAULT_MAX_REDIRECTS,
    },
    max_queue_size => {
      type      => SCALAR,
      regex     => qr/^\d+$/,
      default   => DEFAULT_MAX_QUEUE_SIZE,
    },
    allow_slave    => { type => BOOLEAN, default => 0 },
    default_slot   => {
      type      => SCALAR,
      callbacks => { 'total_slots' => sub { int($_[0] || 0) <= TOTAL_SLOTS } },
      regex     => qr/^\d+$/,
      optional  => 1,
    },
    debug          => {
      type    => BOOLEAN,
      default => $ENV{REDIS_CLUSTER_DEBUG} || 0,
    },
  },
);

####
sub new {
  my $class = shift(@_);

  my $self = {
    validate_with(
      params      => \@_,
      spec        => $SPEC{new},
      allow_extra => 1,
   ),
    _slots     => [],
    _redirects => 0,
  };

  # Parse nodes from string
  unless (ref($self->{server})) {
    $self->{server} = [ split(m/[\s,;]+/, $self->{server}) ];
  }

  # Check minimum number of nodes
  if (@{$self->{server}} < MIN_NODES) {
    croak('At least ' . MIN_NODES . ' nodes should be specified');
  }

  return bless($self, $class);
}

####
sub get_master_by_key {
  my $self = shift(@_);
  my ($key) = @_;

  my $slot = $self->_get_slot_by_key($key);
  return $self->_get_master_by_slot($slot);
}

####
sub get_slave_by_key {
  my $self = shift(@_);
  my ($key, $num) = @_;

  my $slot = $self->_get_slot_by_key($key);
  return $self->_get_slave_by_slot($slot, $num);
}

####
sub get_node_by_key {
  my $self = shift(@_);
  my ($key, $num) = @_;

  my $slot = $self->_get_slot_by_key($key);
  return $self->_get_node_by_slot($slot, $num);
}

####
sub get_node {
  my $self = shift(@_);
  my ($node) = @_;

  unless ($self->_is_member($node)) {
    croak("Node is not a member of cluster: $node");
  }

  return $self->_get_node($node);
}

####
sub get_random_master {
  my $self = shift(@_);
  return $self->_get_master_by_slot(int(rand(TOTAL_SLOTS)));
}

####
sub get_random_slave {
  my $self = shift(@_);
  return $self->_get_slave_by_slot(int(rand(TOTAL_SLOTS)));
}

####
sub AUTOLOAD {
  my $cmd = $AUTOLOAD;
  $cmd =~ s/.*://;

  my $method = sub {
    my $self = shift(@_);

    my $res = $self->_exec_cmd($cmd, @_);
    warn("[debug] - result: " . Dumper($res) . "\n") if $self->{debug};

    return $res;
  };

  # Create method if not exists
  no strict 'refs'; ## no critic
  *$AUTOLOAD = $method;

  goto $method;
}

####
sub DESTROY { } # Avoid AUTOLOAD

####
sub _exec_cmd {
  my $self = shift(@_);
  my ($cmd, @args) = @_;

  $cmd = lc($cmd);

  if ($self->{debug}) {
    my $multi = $self->{_multi} ? ' [multi]' : '';
    my $watch = $self->{_watch} ? ' [watch]' : '';
    my $cmd_with_args = join(' ', $cmd, @args);
    warn("[debug]${watch}${multi} command: $cmd_with_args\n");
  }

  my $multi = $self->{_multi} || $self->{_watch};
  my $cmd_params = exists($CMD{$cmd}) ? $CMD{$cmd} : undef;
  my $key;

  if ($multi && defined($self->{_multi_key})) {
    # Use 'multi' key
    $key = $self->{_multi_key};
  }
  else {
    # Use command key
    $key = $cmd_params ? $cmd_params->{key} : undef;

    if (defined($key)) {
      # Key is CodeRef, perform function call to get value
      if (ref($key) eq 'CODE') { $key = &{$key}($self, \@args); }
      # Get key value from command arguments
      elsif (!ref($key)) { $key = $args[$key]; }
      # Invalid key
      else { croak("Invalid key: $key"); }
    }
  }

  # Store last key for 'wait' command
  $self->{_last_key} = $key;
  warn('[debug] - key: ' . ($key || '') . "\n") if $self->{debug};

  my ($redis, $node_type);

  if (defined($key)) {
    # Store 'multi' key if nesessary
    $self->{_multi_key} = $key if !defined($self->{_multi_key}) &&
      ($multi || any { $cmd eq $_ } qw(multi watch));

    # Check if command may be executed on a slave node
    my $allow_slave = $self->{allow_slave} &&
      $cmd_params && $cmd_params->{allow_slave} && !$multi;

    # Get any node by key
    if ($allow_slave) { $redis = $self->get_node_by_key($key); }
    # Get master node by key
    else { $redis = $self->get_master_by_key($key); }

    $node_type = $allow_slave ? 'any' : 'master';
  }
  else {
    my $enqueue = ($self->{_multi} || $cmd eq 'multi') &&
      !any { $cmd eq $_ } qw(exec discard);

    my $ignore_exec = $cmd eq 'exec' && $self->{_queue} &&
      @{$self->{_queue}} == 1 && $self->{_queue}->[0]->[0] eq 'multi';

    if ($enqueue) {
      # Enqueue command without key in 'multi' mode except 'exec' and 'discard'
      $self->_enqueue($cmd, @args);
      $self->_set_mode_by_cmd($cmd) if $cmd eq 'multi';

      return $cmd eq 'multi' ? REDIS_RESPONSE_OK : REDIS_RESPONSE_QUEUED;
    }
    elsif ($ignore_exec || any { $cmd eq $_ } qw(discard unwatch)) {
      # - Ignore 'exec' command if queue is empty
      # - Ignore all enqueued commands on 'discard'
      # - Ignore 'unwatch' command without previous 'watch'
      #   or after execution of 'exec' or 'discard' commands
      $self->_set_mode_by_cmd($cmd);
      return $cmd eq 'exec' ? [] : REDIS_RESPONSE_OK;
    }
    else {
      if (defined($self->{default_slot})) {
        # Get default master node
        $redis = $self->_get_master_by_slot($self->{default_slot});
        $node_type = 'default master';
      }
      else {
        # Get random master node
        $redis = $self->get_random_master();
        $node_type = 'random master';
      }
    }
  }

  warn("[debug] - node ($node_type): $redis->{server}\n") if $self->{debug};
  my $res;

  try {
    # Execute all enqueued commands
    my $queue = delete($self->{_queue}) || [];
    $redis->__std_cmd(@$_) for @$queue; ## no critic

    # Execute current command
    $res = $redis->__std_cmd($cmd, @args); ## no critic
    $self->{_redirects} = 0 if $self->{_redirects};
  }
  catch {
    $res = $self->_on_error($redis, $cmd, \@args, $_);
  };

  # Set mode
  $self->_set_mode_by_cmd($cmd);
  return $res;
}

####
sub _enqueue {
  my $self = shift(@_);
  my ($cmd, @args) = @_;

  $self->{_queue} ||= [];

  # Check if max queue size is exceeded
  if (@{$self->{_queue}} >= $self->{max_queue_size}) {
    croak('Max queue size exceeded');
  }

  push(@{$self->{_queue}}, [ $cmd, @args ]);
}

####
sub _set_mode_by_cmd {
  my $self = shift(@_);
  my ($cmd) = @_;

  if (any { $cmd eq $_ } qw(exec discard unwatch)) {
    # Reset 'multi' and/or 'watch' mode if nesessary
    delete($self->{_multi}) if $cmd ne 'unwatch';
    delete($self->{_multi_key}) unless $cmd eq 'unwatch' && $self->{_multi};
    delete($self->{_queue}) if any { $cmd eq $_ } qw(exec discard);
    delete($self->{_watch});
  }
  else {
    # Set 'multi' and/or 'watch' mode if nesessary
    $self->{_multi} = 1 if $cmd eq 'multi';
    $self->{_watch} = 1 if $cmd eq 'watch';
  }
}

####
sub _on_error {
  my $self = shift(@_);
  my ($redis, $cmd, $args, $err_msg) = @_;

  # Parse error message
  my @err = split(m/[\s,]+/, $err_msg);

  # Rethrow error unless redirect
  my ($type, $node) = ($err[1], $err[3]);
  my $redirect = any { $type eq $_ } qw(MOVED ASK);
  croak($err_msg) unless $redirect;

  warn("[warn] $err_msg") if $self->{debug} || !$self->{_test};

  # Redirect inside 'multi' is not allowed
  if (exists($self->{_multi})) {
    $self->_set_mode_by_cmd('discard');
    $redis->__std_cmd('discard'); ## no critic
    croak('Redirect inside [multi] is not allowed');
  }

  # Redirect inside 'watch' is not allowed
  if (exists($self->{_watch})) {
    $self->_set_mode_by_cmd('unwatch');
    $redis->__std_cmd('unwatch'); ## no critic
    croak('Redirect inside [watch] is not allowed');
  }

  # Check if max number of slot redirects exceeded
  if ($self->{_redirects} >= $self->{max_redirects}) {
    croak('Too many redirects');
  }

  # Perform redirect
  $self->{_redirects}++;
  # Refresh cluster state immediately if redirect type is 'MOVED'
  $self->_get_slots('force') if $type eq 'MOVED';

  # Get node
  $redis = $self->_get_node($node);
  my $res;

  try {
    # Retry command on specified node
    $res = $redis->__std_cmd($cmd, @$args); ## no critic
    $self->{_redirects} = 0;
  }
  catch {
    $res = $self->_on_error($redis, $cmd, $args, $_);
  };

  return $res;
}

####
sub _get_slot_by_key {
  my $self = shift(@_);
  my ($key) = @_;

  # Hash tag (e.g. {tag}.key)
  my $tag = ($key =~ m/{([^}]+)}/ ? $1 : $key);

  # Redis-specific CRC16
  my $slot = crc($tag, 0x10, 0, 0, 0, 0x1021, 0, 0) & 0x3fff;
  warn("[debug] - slot: $slot\n") if $self->{debug};

  return $slot;
}

####
sub _get_master_by_slot {
  my $self = shift(@_);
  my ($slot) = @_;

  my $range = $self->_get_range_by_slot($slot);
  return $self->_get_node(join(':', @{$range->[2]}));
}

####
sub _get_slave_by_slot {
  my $self = shift(@_);
  my ($slot, $num) = @_;

  return $self->_get_node_by_slot($slot, $num, 1);
}

####
sub _get_node_by_slot {
  my $self = shift(@_);
  my ($slot, $num, $offset) = @_;

  ($num, $offset) = (int($num || 0), int($offset || 0));

  my $range = $self->_get_range_by_slot($slot);
  my $node_cnt = @$range - 2 - $offset;
  $num = 1 + int(rand($node_cnt)) if $num < 1 || $num > $node_cnt;

  return $self->_get_node(join(':', @{$range->[ 1 + $offset + $num ]}));
}

####
sub _get_range_by_slot {
  my $self = shift(@_);
  my ($slot) = @_;

  $slot = int($slot);

  my ($range) = bsearch { $slot < $_->[0] ? 1 :
    $slot > $_->[1] ? -1 : 0 } @{$self->_get_slots()};

  if ($range && @$range) { return $range; }
  else { croak("Cannot find slot: $slot"); }
}

####
sub _get_slots {
  my $self = shift(@_);
  my ($force) = @_;

  # No need to refresh cluster state
  return $self->{_slots} if @{$self->{_slots}} && !$force &&
    (!$self->{refresh} || time() - $self->{_utime} < $self->{refresh});

  # Get cluster slots
  my $slots;

  foreach my $node (@{$self->{server}}) {
    my $redis = $self->_get_node($node);
    $slots = $redis->cluster_slots();

    last if $slots && @$slots;
  }

  croak('Cannot get cluster state') unless $slots && @$slots;

  # Sort slots for binary search
  $self->{_slots} = [ sort { $a->[0] <=> $b->[0] } @$slots ];
  # Update refresh time
  $self->{_utime} = time();

  return $self->{_slots};
}

####
sub _get_node {
  my $self = shift(@_);
  my ($node) = @_;

  $node = join(':', @$node) if ref($node);

  unless (exists($NODES{$node})) {
    $NODES{$node} = Redis->new(%$self, server => $node);
  }

  return $NODES{$node};
}

####
sub _is_member {
  my $self = shift(@_);
  my ($node) = @_;

  $node = join(':', @$node) if ref($node);

  foreach my $range (@{$self->_get_slots()}) {
    return 1 if any { $node eq join(':', @$_) } @$range[ 2 .. $#$range ];
  }

  return;
}

1;

__END__

=head1 NAME

  Redis::Cluster - Redis Cluster client for Perl

=head1 SYNOPSYS

  use Redis::Cluster;

  my $cluster = Redis::Cluster->new(
    server         => [qw(
      127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002
      127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005
    )],
    refresh        => 0,
    max_redirects  => 5,
    max_queue_size => 10,
    allow_slave    => 0,
    ... # See Redis.pm for other arguments
  );

  $cluster->set('key', 1);
  my $res = $cluster->get('key');

  # See Redis.pm for API details

=head1 DESCRIPTION

Redis Cluster is HA solution for Redis. This module deals with:

=over

=item *

Cluster state

=item *

Connection pool

=item *

Node selection (hash tags are supported)

=item *

Key slot redirects

=item *

Execution of read-only commands on slave nodes (optional)

=back

Transactions (not recommended), Lua scripts (recommended) and 'wait' command
are supported with some limitations described in BUGS AND LIMITATIONS.

=head1 MIGRATION

This module provides the same API as Redis.pm. So, migration should be quite
simple. There are two main differences:

=over

=item *

'server' property should contain at least three nodes. It may be an ArrayRef
or comma separated string.

=item *

You should use hash tags in your keys to avoid issues.

=back

=head1 PUBLIC METHODS

=head2 new

  my $cluster = Redis::Cluster->new(
    server         => [qw(
      127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002
      127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005
    )],
    # Default values below
    refresh        => 0,
    max_redirects  => 5,
    max_queue_size => 10,
    allow_slave    => 0,
    ...
  );

Constructor.
Returns Redis::Cluster object.

=head3 server

Cluster nodes (mandatory). Should be an ArrayRef or comma separated string.
Every node should be described as ip:port. You should specify at least
three (prefferably master) nodes. This nodes will be used to get cluster
state, other nodes will be found automatically.

You can also specify nodes in REDIS_CLUSTER envitronment variable.

=head3 refresh

Cluster state refresh interval (in seconds).
If set to zero, cluster state will be updated only on MOVED redirect.

=head3 max_redirects

Maximum number of key slot redirects (to avoid infinite redirects)

=head3 max_queue_size

Maximum internal queue size (used in 'multi' mode)

=head3 allow_slave

Allow execution of read-only commands on slave nodes

=head3 default_slot

This key slot is used for execution of commands without keys in arguments.
If not specified, random key slot will be used, and command will be executed
on a random master node.

=head3 Other arguments are identical to Redis.pm

=head2 get_master_by_key

  my $redis = $cluster->get_master_by_key($key);

Get master node by key. Returns Redis object.

=head2 get_slave_by_key

  $redis = $cluster->get_slave_by_key($key, $num);

Get slave node by key. Returns Redis object.

$num is a slave number (1 - first slave, ...).
If not specified, random slave node will be returned.

=head2 get_node_by_key

  $redis = $cluster->get_node_by_key($key, $num);

Get any node (master or slave) by key. Returns Redis object.

$num is a node number (1 - master, 2 - first slave, ...).
If not specified, random node will be returned.

=head2 get_node

  $redis = $cluster->get_node($node);

Get node by ip:port. Returns Redis object.
Node should be a member of cluster.

=head2 get_random_master

  my $redis = $cluster->get_random_master();

Get random master node.

=head2 get_random_slave

  my $redis = $cluster->get_random_slave();

Get random slave node.

=head1 PRIVATE METHODS

=head2 _exec_cmd

  my $res = $cluster->_exec_cmd($cmd, @args);

Execute Redis command. Returns command execution result.

=head2 _enqueue

  $cluster->_enqueue($cmd, @args);

Enqueue command into internal queue (used in 'multi' mode).

=head2 _set_mode_by_cmd

  $cluster->_set_mode_by_cmd($cmd);

Set mode by command (multi, exec, discard, watch, unwatch).

=head2 _on_error

  my $res = $cluster->_on_error($redis, $cmd, \@args, $err_msg);

Error handler. Retries command on another node on redirect.
Returns command execution result.

=head2 _get_slot_by_key

  my $slot = $cluster->_get_slot_by_key($key);

Get slot by key. Returns slot number.

=head2 _get_master_by_slot

  $redis = $cluster->_get_master_by_slot($slot);

Get master node by slot number. Returns Redis object.

=head2 _get_slave_by_slot

  $redis = $cluster->_get_slave_by_slot($slot, $num);

Get slave node by slot number. Returns Redis object.

$num is a slave number (1 - first slave, ...).
If not specified, random slave node will be returned.

=head2 _get_node_by_slot

  $redis = $cluster->_get_node_by_slot($slot, $num, $offset);

Get any node (master or slave) by slot number. Return Redis object.

$num is a node number (1 - master, 2 - first slave, ...).
If not specified, random node will be returned.

$offset is a node offset (0 - any node, 1 - any slave, ...).

=head2 _get_range_by_slot

  my $range = $cluster->_get_range_by_slot($slot);

Get slot range by slot number.
Returns an item of 'cluster slots' command excution result (ArrayRef).

=head2 _get_slots

  my $slots = $cluster->_get_slots($force);

Get slots (cluster state).
Returns 'cluster slots' command execution result (ArrayRef).

If $force flag is set, cluster state will be obtained immediately,
ignoring 'refresh' property.

=head2 _get_node

  $redis = $cluster->_get_node($node);

Get node by ip:port. Returns Redis object.

=head2 _is_member

  my $is_member = $cluster->_is_member($node);

Check if node is a member of cluster by ip:port. Returns boolean.

=head1 BUGS AND LIMITATIONS

=over

=item *

Commands with keys in arguments will be executed on node, selected by
first key.  In 'watch' and/or 'multi' mode node will be selected by
first key of first command with key. All commands prior to first command
with key will be enqueued into internal queue. It means that the same
master node will be selected from 'watch' or 'multi' command till 'exec',
'discard' or 'unwatch'.

All multi-key commands should be in a single key slot. It is a Redis
Cluster limitation. You should use hash tags to avoid issues.

=item *

'Wait' command will be executed on node, selected by last known key.

=item *

Redirects are not allowed inside 'multi' and/or 'watch'.
Using Lua scripts instead of transactions is highly recommended.

=item *

Unlike Redis.pm, there is a fixed list of supported commands with keys
in arguments. It means there may be some issues with new commands until
they are supported by authors of this module.

=back

=head1 SEE ALSO

=over

=item *

Redis

=item *

L<http://redis.io/topics/cluster-tutorial>

=item *

L<http://redis.io/topics/cluster-spec>

=back

=head1 AUTHORS

=over

=item *

SMS Online <dev.opensource@sms-online.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 SMS Online

This is free software, licensed under:
  The Artistic License 2.0 (GPL Compatible)

=cut
