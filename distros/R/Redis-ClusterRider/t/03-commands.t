use 5.008000;
use strict;
use warnings;

use Test::More tests => 14;
use Test::Fatal;
BEGIN {
  require 't/test_helper.pl';
}

our @mock_keys;
my $cluster = new_cluster(
  allow_slaves     => 1,
  refresh_interval => 5,
  cnx_timeout      => 5,
  read_timeout     => 5,
);

t_nodes($cluster);
t_set($cluster);
t_get($cluster);
t_run_command($cluster);
t_error_reply($cluster);
t_multiword_command($cluster);
t_keys($cluster);

# try different combinations of options
my $other_cluster = new_cluster(
  refresh_interval => 0,
  lazy => 1,
);
t_get($other_cluster);

my $other_cluster_2 = new_cluster(
  refresh_interval => 5,
  cnx_timeout      => 5,
  read_timeout     => 5,
);
t_failover($other_cluster_2, 1);

my $other_cluster_3 = new_cluster(
  allow_slaves     => 1,
  refresh_interval => 5,
  cnx_timeout      => 5,
  read_timeout     => 5,
);
t_failover($other_cluster_3, 0);

sub t_nodes {
  my $cluster = shift;

  my @master_nodes = nodes($cluster);

  is_deeply( \@master_nodes,
    [ '127.0.0.1:7000',
      '127.0.0.1:7001',
      '127.0.0.1:7002',
    ],
    'nodes; master nodes'
  );

  my @nodes = nodes( $cluster, undef, 1 );

  is_deeply( \@nodes,
    [ '127.0.0.1:7000',
      '127.0.0.1:7001',
      '127.0.0.1:7002',
      '127.0.0.1:7003',
      '127.0.0.1:7004',
      '127.0.0.1:7005',
      '127.0.0.1:7006',
    ],
    'nodes; all nodes'
  );

  @master_nodes = nodes( $cluster, 'foo' );

  is_deeply( \@master_nodes,
    [ '127.0.0.1:7002' ],
    'nodes; master nodes by key'
  );

  @nodes = nodes( $cluster, 'foo', 1 );

  is_deeply( \@nodes,
    [ '127.0.0.1:7002',
      '127.0.0.1:7006',
    ],
    'nodes; nodes by key'
  );

  return;
}

sub t_set {
  my $cluster = shift;

  my $t_reply = $cluster->set( 'foo', "some\r\nstring" );

  is( $t_reply, 'OK', 'write; SET' );

  return;
}

sub t_get {
  my $cluster = shift;

  my $t_reply = $cluster->get('foo');

  is( $t_reply, "some\r\nstring", 'reading; GET' );

  return;
}

sub t_run_command {
  my $cluster = shift;

  my $t_reply = $cluster->run_command('get', 'foo');

  is( $t_reply, "some\r\nstring", 'reading; GET (run_command)' );

  return;
}

sub t_error_reply {
  my $cluster = shift;

  like(
    exception {
      my $reply = $cluster->hget( 'foo', 'test' );
    },
    qr/\[hget\] LOADING Redis is loading the dataset in memory/,
    'error reply'
  );

  return;
}

sub t_multiword_command {
  my $cluster = shift;

  my $t_reply = $cluster->client_getname;

  is( $t_reply, 'test', 'multiword command; CLIENT GETNAME' );

  return;
}

sub t_keys {
  my $cluster = shift;

  my $t_reply = $cluster->keys( '*' );

  is( $t_reply, scalar(@mock_keys), 'scalar; KEYS' );

  my @t_reply = $cluster->keys( '*' );

  is_deeply( \@t_reply, \@mock_keys, 'list; KEYS' );

  return;
}

sub t_failover {
  my ( $cluster, $num_init ) = @_;

  my $counter = 0;
  my $orig_init = *{$Redis::ClusterRider::{_init}}{CODE};
  local *Redis::ClusterRider::_init = sub {
    $counter++;
    goto &$orig_init;
  };

  update_command_replies(
    cluster_slots => [
      [ '0',
        '5961',
        [ '127.0.0.1', '7003', '14550b7425c44231090719acd5a5d42ad5424b4f' ],
        [ '127.0.0.1', '7000', '4b2fa9c315cddbc1c1c729b60ade711fe141d61b' ],
        [ '127.0.0.1', '7005', '050ece77147551db844467770883cf5cd2c8bc2b' ],
      ],
      [ '5962',
        '10922',
        [ '127.0.0.1', '7004', 'a859a49ad96f8312f91fc8c6b402484eda913c83' ],
        [ '127.0.0.1', '7001', 'f7fc4a7c3f340ea44dc8f92a6fda041dc640de90' ],
      ],
      [ '10923',
        '11421',
        [ '127.0.0.1', '7003', '14550b7425c44231090719acd5a5d42ad5424b4f' ],
        [ '127.0.0.1', '7000', '4b2fa9c315cddbc1c1c729b60ade711fe141d61b' ],
        [ '127.0.0.1', '7005', '050ece77147551db844467770883cf5cd2c8bc2b' ],
      ],
      [ '11422',
        '16383',
        [ '127.0.0.1', '7006', '08c40bd2b18d9c2a20e6d8a27b8da283566a665d' ],
        [ '127.0.0.1', '7002', '001dadcde7704079c3c6ea679323215c0930af57' ],
      ],
    ],
  );

  $cluster->get('foo');
  is $counter, $num_init, 'GET; number of times _init() was called';
}
