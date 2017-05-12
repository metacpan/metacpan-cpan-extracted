#!perl -T

use strict;
use Test::More tests => 3;
use Number::UN 'get_un';

subtest 'UN 73' => sub {
  plan tests => 2;
  ok (my %un = get_un(73), 'get un');
  is ($un{description}, 'Detonators for ammunition', 'description');
};

subtest 'UN 1993' => sub {
  plan tests => 2;
  ok (my %un = get_un(1993), 'get un');
  is ($un{description}, 'Combustible liquids, n.o.s.', 'description');
};

subtest 'undefined UN number' => sub {
  plan tests => 1;
  ok (!get_un(8), 'get un');
};
