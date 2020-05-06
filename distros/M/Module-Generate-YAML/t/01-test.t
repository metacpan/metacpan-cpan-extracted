use Test::More;

use lib '.';

use Module::Generate::YAML qw/generate/;

generate('t/testing.yml');

ok(1);

done_testing;
