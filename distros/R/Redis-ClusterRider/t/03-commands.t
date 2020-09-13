use 5.008000;
use strict;
use warnings;

use Test::More tests => 11;
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
