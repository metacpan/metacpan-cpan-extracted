#!perl -T

use Test::More tests => 3;

BEGIN {
  use_ok('Test::Chimps::Smoker');
}

my $s = Test::Chimps::Smoker->new(server => 'bogus',
                                  config_file => 't-data/smoker-config.yml');

ok($s, "the server object is defined");
isa_ok($s, 'Test::Chimps::Smoker', "and it's of the correct type");
