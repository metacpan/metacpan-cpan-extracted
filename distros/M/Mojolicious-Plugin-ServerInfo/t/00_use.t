use strict;
use warnings;
use Test::More;

use lib qw( ../lib );

my @modules = qw(
  Mojolicious::Plugin::ServerInfo
);

for my $module (@modules) {
  use_ok($module);
}

done_testing;
