#!perl
use strict;
use warnings;

use Test::More tests => 3;

use Carp::Heavy; # Preload since we mangle @INC

my $PC = 'Pod::Coverage::TrustPod';

require_ok($PC);

my $ok = eval { 
  use lib 't/eg';
  {
      my $obj = $PC->new( package  => 'ChildWithPod',);
      if (! defined $obj->coverage) {
        diag "no coverage: " . $obj->why_unrated;
        die;
      }
  }

  return 1;
};

is($@, '', "expected to live (no error)");
ok($ok, 'expecting to live');
