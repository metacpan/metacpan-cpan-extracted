use 5.008000;
use strict;
use warnings;

use Test::MockObject;
use Clone qw( clone );

my %command_replies;
sub prepare_mock {
  %command_replies = (
    cluster_info => 'cluster_state:ok',

    cluster_slots => [
      [ '0',
        '5961',
        [ '127.0.0.1', '7000', '4b2fa9c315cddbc1c1c729b60ade711fe141d61b' ],
        [ '127.0.0.1', '7003', '14550b7425c44231090719acd5a5d42ad5424b4f' ],
        [ '127.0.0.1', '7005', '050ece77147551db844467770883cf5cd2c8bc2b' ]
      ],
      [ '5962',
        '10922',
        [ '127.0.0.1', '7001', 'f7fc4a7c3f340ea44dc8f92a6fda041dc640de90' ],
        [ '127.0.0.1', '7004', 'a859a49ad96f8312f91fc8c6b402484eda913c83' ]
      ],
      [ '10923',
        '11421',
        [ '127.0.0.1', '7000', '4b2fa9c315cddbc1c1c729b60ade711fe141d61b' ],
        [ '127.0.0.1', '7003', '14550b7425c44231090719acd5a5d42ad5424b4f' ],
        [ '127.0.0.1', '7005', '050ece77147551db844467770883cf5cd2c8bc2b' ]
      ],
      [ '11422',
        '16383',
        [ '127.0.0.1', '7002', '001dadcde7704079c3c6ea679323215c0930af57' ],
        [ '127.0.0.1', '7006', '08c40bd2b18d9c2a20e6d8a27b8da283566a665d' ]
      ],
    ],

    command => [
      [ 'command', 0, [ qw( loading stale ) ], 0, 0, 0 ],
      [ 'set', -3, [ qw( write denyoom ) ], 1, 1, 1 ],
      [ 'get', '2', [ qw( readonly fast ) ], 1, 1, 1 ],
      [ 'client', -2, [ qw( admin noscript ) ], 0, 0, 0 ],
      [ 'hget', 3, [ qw( readonly fast ) ], 1, 1, 1 ],
    ],

    readonly        => 'OK',
    set             => 'OK',
    get             => "some\r\nstring",
    client_getname  => 'test',
  );

  our @mock_keys = qw( key1 key2 key3 key4 key5 );

  Test::MockObject->fake_module( 'Redis',
    new => sub {
      my $class  = shift;
      my %params = @_;

      my $mock = Test::MockObject->new({});
      $mock->{server} = $params{server};

      my ( $is_master, $is_readonly ) = ( 0, 0 );
      foreach my $cmd_name ( keys %command_replies ) {
        $mock->mock( $cmd_name,
          sub {
            my $self = shift;

            my ( $master_node, $range_start, $range_end );
            if ( $cmd_name ne 'cluster_slots' ) {
              $is_master = 0;
              my $slots_raw = $mock->cluster_slots;
              foreach my $range ( @{$slots_raw} ) {
                $range_start = shift @{$range};
                $range_end = shift @{$range};
                $master_node = $range->[0][0] . ':' . $range->[0][1];
                $is_master = 1 if $master_node eq $self->{server};
              }
            }

            if ( $cmd_name eq 'readonly' ) {
              $is_readonly = 1;
            }
            elsif ( $cmd_name eq 'get' && !( $is_master || $is_readonly ) ) {
              die "[error] MOVED $range_start $master_node\n";
            }

            return clone( $command_replies{$cmd_name} );
          }
        );
      }

      $mock->mock( 'hget',
        sub {
          die '[hget] LOADING Redis is loading the dataset in memory';
        }
      );

      $mock->mock( 'keys',
        sub {
          return @mock_keys;
        }
      );

      $mock->mock( 'on_connect', $params{on_connect} );
      $mock->on_connect;

      return $mock;
    },
  );
}

sub update_command_replies {
  %command_replies = ( %command_replies, @_ );
}

use Redis::ClusterRider;

sub new_cluster {
  prepare_mock();
  my %params = @_;

  return Redis::ClusterRider->new(
    startup_nodes => [
      '127.0.0.1:7000',
      '127.0.0.1:7001',
      '127.0.0.1:7002',
    ],
    %params,
  );
}

sub nodes {
  my $cluster = shift;
  my $key     = shift;
  my $allow_slaves = shift;

  return sort { $a cmp $b } map { $_->{server} }
      $cluster->nodes( $key, $allow_slaves );

  return;
}

1;
