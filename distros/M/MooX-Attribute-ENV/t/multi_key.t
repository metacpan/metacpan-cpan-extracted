use Test::More;

package MyMod;
use Moo;
use MooX::Attribute::ENV;
# look for $ENV{attr_val} and $ENV{ATTR_VAL}
has attr => (
  is => 'ro',
  env_key => [ 'attr_val', 'next_val' ],
);
# looks for $ENV{otherattr} and $ENV{OTHERATTR}, then any default

package main;

sub test_with_env {
  my ($attr, $env, $expected) = @_;
  local %ENV = (%ENV, %$env);
  my $obj = MyMod->new;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is $obj->$attr, $expected, "$attr from ENV(@{[ keys %$env ]})";
}

test_with_env(attr => { ATTR_VAL => 1 }, 1);
test_with_env(attr => { attr_val => 2 }, 2);

test_with_env(attr => { ATTR_VAL => 1, NEXT_VAL => 3 }, 1);
test_with_env(attr => { attr_val => 2, next_val => 4 }, 2);

test_with_env(attr => { NEXT_VAL => 3 }, 3);
test_with_env(attr => { next_val => 4 }, 4);

done_testing;
