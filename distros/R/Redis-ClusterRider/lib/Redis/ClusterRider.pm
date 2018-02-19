package Redis::ClusterRider;

use 5.008000;
use strict;
use warnings;
use base qw( Exporter );

our $VERSION = '0.18';

use Redis;
use List::MoreUtils qw( bsearch );
use Scalar::Util qw( looks_like_number weaken );
use Time::HiRes;
use Carp qw( croak );

BEGIN {
  our @EXPORT_OK = qw( crc16 hash_slot );
}

use constant {
  D_REFRESH_INTERVAL => 15,
  MAX_SLOTS          => 16384,
  EOL                => "\r\n",
};

my @CRC16_TAB = (
  0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50a5, 0x60c6, 0x70e7,
  0x8108, 0x9129, 0xa14a, 0xb16b, 0xc18c, 0xd1ad, 0xe1ce, 0xf1ef,
  0x1231, 0x0210, 0x3273, 0x2252, 0x52b5, 0x4294, 0x72f7, 0x62d6,
  0x9339, 0x8318, 0xb37b, 0xa35a, 0xd3bd, 0xc39c, 0xf3ff, 0xe3de,
  0x2462, 0x3443, 0x0420, 0x1401, 0x64e6, 0x74c7, 0x44a4, 0x5485,
  0xa56a, 0xb54b, 0x8528, 0x9509, 0xe5ee, 0xf5cf, 0xc5ac, 0xd58d,
  0x3653, 0x2672, 0x1611, 0x0630, 0x76d7, 0x66f6, 0x5695, 0x46b4,
  0xb75b, 0xa77a, 0x9719, 0x8738, 0xf7df, 0xe7fe, 0xd79d, 0xc7bc,
  0x48c4, 0x58e5, 0x6886, 0x78a7, 0x0840, 0x1861, 0x2802, 0x3823,
  0xc9cc, 0xd9ed, 0xe98e, 0xf9af, 0x8948, 0x9969, 0xa90a, 0xb92b,
  0x5af5, 0x4ad4, 0x7ab7, 0x6a96, 0x1a71, 0x0a50, 0x3a33, 0x2a12,
  0xdbfd, 0xcbdc, 0xfbbf, 0xeb9e, 0x9b79, 0x8b58, 0xbb3b, 0xab1a,
  0x6ca6, 0x7c87, 0x4ce4, 0x5cc5, 0x2c22, 0x3c03, 0x0c60, 0x1c41,
  0xedae, 0xfd8f, 0xcdec, 0xddcd, 0xad2a, 0xbd0b, 0x8d68, 0x9d49,
  0x7e97, 0x6eb6, 0x5ed5, 0x4ef4, 0x3e13, 0x2e32, 0x1e51, 0x0e70,
  0xff9f, 0xefbe, 0xdfdd, 0xcffc, 0xbf1b, 0xaf3a, 0x9f59, 0x8f78,
  0x9188, 0x81a9, 0xb1ca, 0xa1eb, 0xd10c, 0xc12d, 0xf14e, 0xe16f,
  0x1080, 0x00a1, 0x30c2, 0x20e3, 0x5004, 0x4025, 0x7046, 0x6067,
  0x83b9, 0x9398, 0xa3fb, 0xb3da, 0xc33d, 0xd31c, 0xe37f, 0xf35e,
  0x02b1, 0x1290, 0x22f3, 0x32d2, 0x4235, 0x5214, 0x6277, 0x7256,
  0xb5ea, 0xa5cb, 0x95a8, 0x8589, 0xf56e, 0xe54f, 0xd52c, 0xc50d,
  0x34e2, 0x24c3, 0x14a0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405,
  0xa7db, 0xb7fa, 0x8799, 0x97b8, 0xe75f, 0xf77e, 0xc71d, 0xd73c,
  0x26d3, 0x36f2, 0x0691, 0x16b0, 0x6657, 0x7676, 0x4615, 0x5634,
  0xd94c, 0xc96d, 0xf90e, 0xe92f, 0x99c8, 0x89e9, 0xb98a, 0xa9ab,
  0x5844, 0x4865, 0x7806, 0x6827, 0x18c0, 0x08e1, 0x3882, 0x28a3,
  0xcb7d, 0xdb5c, 0xeb3f, 0xfb1e, 0x8bf9, 0x9bd8, 0xabbb, 0xbb9a,
  0x4a75, 0x5a54, 0x6a37, 0x7a16, 0x0af1, 0x1ad0, 0x2ab3, 0x3a92,
  0xfd2e, 0xed0f, 0xdd6c, 0xcd4d, 0xbdaa, 0xad8b, 0x9de8, 0x8dc9,
  0x7c26, 0x6c07, 0x5c64, 0x4c45, 0x3ca2, 0x2c83, 0x1ce0, 0x0cc1,
  0xef1f, 0xff3e, 0xcf5d, 0xdf7c, 0xaf9b, 0xbfba, 0x8fd9, 0x9ff8,
  0x6e17, 0x7e36, 0x4e55, 0x5e74, 0x2e93, 0x3eb2, 0x0ed1, 0x1ef0,
);

my %PREDEFINED_CMDS = (
  sort        => { readonly => 0, key_pos => 1 },
  zunionstore => { readonly => 0, key_pos => 1 },
  zinterstore => { readonly => 0, key_pos => 1 },
  eval        => { readonly => 0, movablekeys => 1, key_pos => 0 },
  evalsha     => { readonly => 0, movablekeys => 1, key_pos => 0 },
);

$Carp::Internal{ (__PACKAGE__) }++;


sub new {
  my $class  = shift;
  my %params = @_;

  my $self = bless {}, $class;

  unless ( defined $params{startup_nodes} ) {
    croak 'Startup nodes not specified';
  }
  unless ( ref( $params{startup_nodes} ) eq 'ARRAY' ) {
    croak 'Startup nodes must be specified as array reference';
  }
  unless ( @{ $params{startup_nodes} } ) {
    croak 'Specified empty list of startup nodes';
  }

  $self->{startup_nodes} = $params{startup_nodes};
  $self->{allow_slaves}  = $params{allow_slaves};
  $self->{lazy}          = $params{lazy};
  $self->refresh_interval( $params{refresh_interval} );

  $self->{on_node_connect} = $params{on_node_connect};
  $self->{on_node_error}   = $params{on_node_error};

  my %node_params;
  foreach my $name ( qw( conservative_reconnect cnx_timeout read_timeout
    write_timeout password name debug ) )
  {
    next unless defined $params{$name};
    $node_params{$name} = $params{$name};
  }
  $self->{_node_params} = \%node_params;

  $self->{_nodes_pool}        = undef;
  $self->{_nodes}             = undef;
  $self->{_master_nodes}      = undef;
  $self->{_slots}             = undef;
  $self->{_commands}          = undef;
  $self->{_refresh_timestamp} = undef;

  unless ( $self->{lazy} ) {
    $self->_init;
  }

  return $self;
}

sub nodes {
  my $self         = shift;
  my $key          = shift;
  my $allow_slaves = shift;

  unless ( defined $self->{_slots} ) {
    $self->_init;
  }

  my $slot;
  if ( defined $key ) {
    $slot = hash_slot($key);
  }

  my $nodes = $self->_nodes( $slot, $allow_slaves );

  return wantarray
      ? @{ $self->{_nodes_pool} }{ @{$nodes} }
      : $self->{_nodes_pool}{ $nodes->[0] };
}

sub refresh_interval {
  my $self = shift;

  if (@_) {
    my $seconds = shift;

    if ( defined $seconds ) {
      if ( !looks_like_number($seconds) || $seconds < 0 ) {
        croak qq{"refresh_interval" must be a positive number};
      }
      $self->{refresh_interval} = $seconds;
    }
    else {
      $self->{refresh_interval} = D_REFRESH_INTERVAL;
    }
  }

  return $self->{refresh_interval};
}

sub crc16 {
  my $data = shift;

  unless ( utf8::downgrade( $data, 1 ) ) {
    utf8::encode($data);
  }

  my $crc = 0;
  foreach my $char ( split //, $data ) {
    $crc = ( $crc << 8 & 0xff00 )
        ^ $CRC16_TAB[ ( ( $crc >> 8 ) ^ ord($char) ) & 0x00ff ];
  }

  return $crc;
}

sub hash_slot {
  my $key = shift;

  my $hashtag = $key;

  if ( $key =~ m/\{([^}]*?)\}/ ) {
    if ( length $1 > 0 ) {
      $hashtag = $1;
    }
  }

  return crc16($hashtag) % MAX_SLOTS;
}

sub _init {
  my $self = shift;

  $self->_discover_cluster;

  if ( $self->{refresh_interval} > 0 ) {
    $self->{_refresh_timestamp} = [Time::HiRes::gettimeofday];
  }

  return;
}

sub _discover_cluster {
  my $self = shift;

  my $nodes;

  if ( defined $self->{_slots} ) {
    $nodes = $self->_nodes( undef, $self->{allow_slaves} );
  }
  else {
    my %nodes_pool;

    foreach my $hostport ( @{ $self->{startup_nodes} } ) {
      unless ( defined $nodes_pool{$hostport} ) {
        $nodes_pool{$hostport} = $self->_new_node($hostport);
      }
    }

    $self->{_nodes_pool} = \%nodes_pool;
    $nodes = [ keys %nodes_pool ];
  }

  $self->_execute( 'cluster_state', [], $nodes );
  my $slots = $self->_execute( 'cluster_slots', [], $nodes );

  unless ( @{$slots} ) {
    croak 'ERR Returned empty list of slots';
  }

  $self->_prepare_nodes($slots);

  unless ( defined $self->{_commands} ) {
    $self->_load_commands;
  }

  return;
}

sub _prepare_nodes {
  my $self      = shift;
  my $slots_raw = shift;

  my %nodes_pool;
  my @slots;
  my @masters_nodes;
  my @slave_nodes;

  my $nodes_pool_old = $self->{_nodes_pool};

  foreach my $range ( @{$slots_raw} ) {
    my $range_start = shift @{$range};
    my $range_end   = shift @{$range};

    my @nodes;
    my $is_master = 1;

    foreach my $node_info ( @{$range} ) {
      my $hostport = "$node_info->[0]:$node_info->[1]";

      unless ( defined $nodes_pool{$hostport} ) {
        if ( defined $nodes_pool_old->{$hostport} ) {
          $nodes_pool{$hostport} = delete $nodes_pool_old->{$hostport};
        }
        else {
          $nodes_pool{$hostport} = $self->_new_node($hostport);

          unless ($is_master) {
            push( @slave_nodes, $hostport );
          }
        }

        if ($is_master) {
          push( @masters_nodes, $hostport );
          $is_master = 0;
        }
      }

      push( @nodes, $hostport );
    }

    push( @slots, [ $range_start, $range_end, \@nodes ] );
  }

  @slots = sort { $a->[0] <=> $b->[0] } @slots;

  $self->{_nodes_pool}   = \%nodes_pool;
  $self->{_nodes}        = [ keys %nodes_pool ];
  $self->{_master_nodes} = \@masters_nodes;
  $self->{_slots}        = \@slots;

  if ( $self->{allow_slaves} && @slave_nodes ) {
    $self->_prepare_slaves( \@slave_nodes );
  }

  return;
}

sub _prepare_slaves {
  my $self        = shift;
  my $slave_nodes = shift;

  foreach my $hostport ( @{$slave_nodes} ) {
    local $@;

    eval { $self->_execute( 'readonly', [], [ $hostport ] ) };

    if ($@) {
      warn $@;
    }
  }

  return;
}

sub _load_commands {
  my $self = shift;

  my $nodes = $self->_nodes( undef, $self->{allow_slaves} );
  my $commands_raw = $self->_execute( 'command', [], $nodes );

  my %commands = %PREDEFINED_CMDS;

  foreach my $cmd_raw ( @{$commands_raw} ) {
    my $kwd = lc( $cmd_raw->[0] );

    next if exists $commands{$kwd};

    my $readonly = 0;
    foreach my $flag ( @{ $cmd_raw->[2] } ) {
      if ( $flag eq 'readonly' ) {
        $readonly = 1;
        last;
      }
    }

    $commands{$kwd} = {
      readonly => $readonly,
      key_pos  => $cmd_raw->[3],
    };
  }

  $self->{_commands} = \%commands;

  return;
}

sub _new_node {
  my $self     = shift;
  my $hostport = shift;

  return Redis->new(
    %{ $self->{_node_params} },
    server    => $hostport,
    reconnect => 0.001,       # reconnect only once
    every     => 1000,
    no_auto_connect_on_new => 1,

    on_connect => $self->_create_on_node_connect($hostport),
  );
}

sub _create_on_node_connect {
  my $self     = shift;
  my $hostport = shift;

  weaken($self);

  return sub {
    if ( defined $self->{on_node_connect} ) {
      $self->{on_node_connect}->($hostport);
    }
  };
}

sub _route {
  my $self     = shift;
  my $cmd_name = shift;
  my $args     = shift;

  if ( $self->{refresh_interval} > 0
    && Time::HiRes::tv_interval( $self->{_refresh_timestamp} )
        > $self->{refresh_interval} )
  {
    $self->_init;
  }

  my $key;
  my @kwds = split( m/_/, lc($cmd_name) );
  my $cmd_info = $self->{_commands}{ $kwds[0] };

  if ( defined $cmd_info ) {
    if ( $cmd_info->{key_pos} > 0 ) {
      $key = $args->[ $cmd_info->{key_pos} - scalar @kwds ];
    }
    # Exception for EVAL and EVALSHA commands
    elsif ( $cmd_info->{movablekeys}
      && $args->[1] > 0 )
    {
      $key = $args->[2];
    }
  }

  my $slot;
  my $allow_slaves = $self->{allow_slaves};

  if ( defined $key ) {
    $slot = hash_slot($key);
    $allow_slaves &&= $cmd_info->{readonly};
  }

  my $nodes = $self->_nodes( $slot, $allow_slaves );

  unless ( defined $nodes ) {
    croak 'ERR Target node not found. Maybe not all slots are served';
  }

  return $self->_execute( $cmd_name, $args, $nodes );
}

sub _execute {
  my $self     = shift;
  my $cmd_name = shift;
  my $args     = shift;
  my $nodes    = shift;

  my $nodes_pool = $self->{_nodes_pool};

  my $nodes_num  = scalar @{$nodes};
  my $node_index = int( rand($nodes_num) );
  my $fails_cnt  = 0;

  my $cmd_method
      = $cmd_name eq 'cluster_state'
      ? 'cluster_info'
      : $cmd_name;

  while (1) {
    my $hostport = $nodes->[$node_index];
    my $node     = $nodes_pool->{$hostport};

    my $reply;
    my $err_msg;

    {
      local $@;

      eval {
        $reply = $node->$cmd_method( @{$args} );

        if ( $cmd_name eq 'cluster_state' ) {
          $reply = _parse_info($reply);

          if ( $reply->{cluster_state} eq 'ok' ) {
            $reply = 1;
          }
          else {
            croak 'CLUSTERDOWN The cluster is down';
          }
        }
      };

      if ($@) {
        $err_msg = $@;
      }
    }

    if ($err_msg) {
      my $err_code = 'ERR';
      if ( $err_msg =~ m/^(?:\[\w+\]\s+)?([A-Z]{3,})/ ) {
        $err_code = $1;
      }

      if ( $err_code eq 'MOVED' || $err_code eq 'ASK' ) {
        if ( $err_code eq 'MOVED' ) {
          $self->_init;
        }

        my ($fwd_hostport) = ( split( m/\s+/, $err_msg ) )[3];
        $fwd_hostport =~ s/,$//;

        unless ( defined $nodes_pool->{$fwd_hostport} ) {
          $nodes_pool->{$fwd_hostport} = $self->_new_node( $fwd_hostport );
        }

        return $self->_execute( $cmd_name, $args, [ $fwd_hostport ] );
      }

      if ( defined $self->{on_node_error} ) {
        $self->{on_node_error}->( $err_msg, $hostport );
      }

      if ( ++$fails_cnt < $nodes_num ) {
        if ( ++$node_index == $nodes_num ) {
          $node_index = 0;
        }

        next;
      }

      die $err_msg;
    }

    return $reply;
  }
}

sub _nodes {
  my $self = shift;
  my $slot = shift;
  my $allow_slaves = shift;

  if ( defined $slot ) {
    my ($range) = bsearch {
      $slot > $_->[1] ? -1 : $slot < $_->[0] ? 1 : 0;
    }
    @{ $self->{_slots} };

    return unless defined $range;

    return $allow_slaves
        ? $range->[2]
        : [ $range->[2][0] ];
  }

  return $allow_slaves
      ? $self->{_nodes}
      : $self->{_master_nodes};
}

sub _parse_info {
  return { map { split( m/:/, $_, 2 ) }
      grep { m/^[^#]/ } split( EOL, $_[0] ) };
}

sub AUTOLOAD {
  our $AUTOLOAD;
  my $cmd_name = $AUTOLOAD;
  $cmd_name =~ s/^.+:://;

  my $sub = sub {
    my $self = shift;
    return $self->_route( $cmd_name, [@_] );
  };

  do {
    no strict 'refs';
    *{$cmd_name} = $sub;
  };

  goto &{$sub};
}

sub DESTROY { }

1;
__END__

=head1 NAME

Redis::ClusterRider - Daring Redis Cluster client

=head1 SYNOPSIS

  use Redis::ClusterRider;

  my $cluster = Redis::ClusterRider->new(
    startup_nodes => [
      'localhost:7000',
      'localhost:7001',
      'localhost:7002',
    ],
  );

  $cluster->set( 'foo', 'bar' );
  my $value = $cluster->get('foo');

  print "$value\n";

=head1 DESCRIPTION

Redis::ClusterRider is the Redis Cluster client built on top of the L<Redis>.

Requires Redis 3.0 or higher.

For more information about Redis Cluster see here:

=over

=item *

L<http://redis.io/topics/cluster-tutorial>

=item *

L<http://redis.io/topics/cluster-spec>

=back

=head1 CONSTRUCTOR

=head2 new( %params )

  my $cluster = Redis::ClusterRider->new(
    startup_nodes => [
      'localhost:7000',
      'localhost:7001',
      'localhost:7002',
    ],
    password         => 'yourpass',
    cnx_timeout      => 5,
    read_timeout     => 5,
    refresh_interval => 5,
    lazy             => 1,

    on_node_connect => sub {
      my $hostport = shift;

      # handling...
    },

    on_node_error => sub {
      my $err = shift;
      my $hostport = shift;

      # error handling...
    },
  );

=over

=item startup_nodes => \@nodes

Specifies the list of startup nodes. Parameter should contain the array of
addresses of some nodes in the cluster. The client will try to connect to
random node from the list to retrieve information about all cluster nodes and
slots mapping. If the client could not connect to first selected node, it will
try to connect to another random node from the list.

=item password => $password

If the password is specified, the C<AUTH> command is sent to all nodes
of the cluster after connection.

=item allow_slaves => $boolean

If enabled, the client will try to send read-only commands to slave nodes.

=item cnx_timeout => $fractional_seconds

The C<cnx_timeout> option enables connection timeout. The client will wait at
most that number of seconds (can be fractional) before giving up connecting to
a server.

  cnx_timeout => 10.5,

By default the client use kernel's connection timeout.

=item read_timeout => $fractional_seconds

The C<read_timeout> option enables read timeout. The client will wait at most
that number of seconds (can be fractional) before giving up when reading from
the server.

Not set by default.

=item lazy => $boolean

If enabled, the initial connection to the startup node establishes at time when
you will send the first command to the cluster. By default the initial
connection establishes after calling of the C<new> method.

Disabled by default.

=item refresh_interval => $fractional_seconds

Cluster state refresh interval. If set to zero, cluster state will be updated
only on MOVED redirect.

By default is 15 seconds.

=item on_node_connect => $cb->($hostport)

The C<on_node_connect> callback is called when the connection to particular
node is successfully established. To callback is passed address of the node to
which the client was connected.

Not set by default.

=item on_node_error => $cb->( $err, $hostport )

The C<on_node_error> callback is called when occurred an error on particular
node. To callback are passed two arguments: error message,
and address of the node on which an error occurred.

Not set by default.

=back

See documentation on L<Redis> for more options.

Attention, L<Redis> options C<reconnect> and C<every> are redefined inside the
L<Redis::ClusterRider> for own purproses. User defined values for this options
will be ignored.

=head1 COMMAND EXECUTION

=head2 <command>( [ @args ] )

To execute the command you must call particular method with corresponding name.
If any error occurred during the command execution, the client throw an
exception.

Before the command execution, the client determines the pool of nodes, on which
the command can be executed. The pool can contain the one or more nodes
depending on the cluster and the client configurations, and the command type.
The client will try to execute the command on random node from the pool and, if
the command failed on selected node, the client will try to execute it on
another random node.

If the connection to the some node was lost, the client will try to restore the
connection when you execute next command. The client will try to reconnect only
once and, if attempt fails, the client throw an exception. If you need several
attempts of the reconnection, you must catch the exception and retry a command
as many times, as you need. Such behavior allows to control reconnection
procedure.

The full list of the Redis commands can be found here: L<http://redis.io/commands>.

  my $value   = $cluster->get('foo');
  my $list    = $cluster->lrange( 'list', 0, -1 );
  my $counter = $cluster->incr('counter');

=head1 TRANSACTIONS

To perform the transaction you must get the master node by the key using
C<nodes> method. Then you need to execute C<ECHO> command or any other command
before C<MULTI> command to avoid the error "reconnect disabled inside
transaction or watch" because all connection in the cluster client are lazy.

  my $node = $cluster->nodes('foo');
  $node->echo('ping');

  $node->multi;
  $node->set( '{foo}bar', "some\r\nstring" );
  $node->set( '{foo}car', 42 );
  my $reply = $node->exec;

The detailed information about the Redis transactions can be found here:
L<http://redis.io/topics/transactions>.

=head1 OTHER METHODS

=head2 nodes( [ $key ] [, $allow_slaves ] )

Gets particular nodes of the cluster. In scalar context method returns the
first node from the list.

Getting all master nodes of the cluster:

  my @master_nodes = $cluster->nodes;

Getting all nodes of the cluster, including slave nodes:

  my @nodes = $cluster->nodes( undef, 1 );

Getting master node by the key:

  my $master_node = $cluster->nodes('foo');

Getting nodes by the key, including slave nodes:

  my @nodes = $cluster->nodes( 'foo', 1 );

=head2 refresh_interval( [ $fractional_seconds ] )

Gets or sets the C<refresh_interval> of the client. The C<undef> value resets
the C<refresh_interval> to default value.

=head1 SERVICE FUNCTIONS

Service functions provided by L<Redis::ClusterRider> can be imported.

  use Redis::ClusterRider qw( crc16 hash_slot );

=head2 crc16( $data )

Compute CRC16 for the specified data as defined in Redis Cluster specification.

=head2 hash_slot( $key );

Returns slot number by the key.

=head1 SEE ALSO

L<Redis>, L<AnyEvent::RipeRedis>, L<AnyEvent::RipeRedis::Cluster>

=head1 AUTHOR

Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>

Sponsored by SMS Online, E<lt>dev.opensource@sms-online.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2017-2018, Eugene Ponizovsky, SMS Online. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
