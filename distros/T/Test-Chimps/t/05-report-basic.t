#!perl -T

use Test::More tests => 3;

BEGIN {
  use_ok( 'Test::Chimps::Report' );
}

use Test::TAP::Model::Visual;

my $r = Test::Chimps::Report->new();
ok($r, "the report object is defined");
isa_ok($r, 'Test::Chimps::Report', "and it's of the correct type");
