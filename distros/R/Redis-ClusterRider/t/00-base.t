use 5.008000;
use strict;
use warnings;

use Test::More tests => 3;

my $t_class;

BEGIN {
  $t_class = 'Redis::ClusterRider';
  use_ok($t_class);
}

can_ok( $t_class, 'new' );

my $cluster = new_ok( $t_class,
  [ startup_nodes => [
      '127.0.0.1:7000',
      '127.0.0.1:7001',
      '127.0.0.1:7002',
    ],
    lazy => 1,
  ],
);
