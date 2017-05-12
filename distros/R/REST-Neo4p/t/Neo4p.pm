package t::Neo4p;
use Module::Build;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw(test_server);

sub test_server {
  my $yes;
  eval {
    $yes = Module::Build->current;
  };
  return $yes ? $build->notes('test_server') : 'http://127.0.0.1:7474';
}

1;
