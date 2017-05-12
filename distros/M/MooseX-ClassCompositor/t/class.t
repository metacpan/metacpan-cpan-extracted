use strict;
use warnings;

use Test::More;

use MooseX::ClassCompositor;
use MooseX::Role::Parameterized 0.23 ();

use t::lib::Parameterized;

my $comp = MooseX::ClassCompositor->new({
  class_basename  => 'MXCC::Test',
  class_metaroles => {
    class => [ 'MooseX::StrictConstructor::Trait::Class' ],
  },
  role_prefixes   => {
    '' => 't::lib::',
  },
});

sub class { $comp->class_for(@_); }

subtest "memoization" => sub {
  plan tests => 3;

  my @class = map { class('BasicFoo') } (1..4);
  my $first = shift @class;

  for my $this (@class) {
    is($this, $first, "our memoization (still?) works");
  }
};

my $canTransfer = t::lib::Parameterized->meta->generate_role(
  parameters => { option => 'xyzzy' },
);

my @tests = (
  {
    given     => [ 'BasicFoo' ],
    want_name => 'MXCC::Test::BasicFoo',
    want_can  => [ qw(foo) ],
  },

  {
    given     => [ qw(BasicFoo BasicBar) ],
    want_name => 'MXCC::Test::BasicFoo::BasicBar',
    want_can  => [ qw(foo bar) ],
  },

  {
    # Here, we assert that we get the thing from the previous test, because
    # they have equivalent givens, despite ordering differences.
    # -- rjbs, 2011-08-08
    given     => [ qw(BasicBar BasicFoo) ],
    want_name => 'MXCC::Test::BasicFoo::BasicBar',
    want_can  => [ qw(foo bar) ],
  },

  {
    given     => [
      [ Parameterized => XYZZY => { option => 'xyzzy' } ],
    ],
    want_name => 'MXCC::Test::XYZZY',
    want_can  => [ qw(method_xyzzy) ],
  },

  {
    given     => [
      'BasicFoo',
      [ Parameterized => Smitty => { option => 'smitty' } ],
    ],
    want_name => 'MXCC::Test::BasicFoo::Smitty',
    want_can  => [ qw(foo method_smitty) ],
  },

  {
    # Here, we assert that we get the thing from the previous test, because
    # they have equivalent givens, despite ordering differences -- this time,
    # with parameterization.
    # -- rjbs, 2011-08-08
    given     => [
      [ Parameterized => Smitty => { option => 'smitty' } ],
      'BasicFoo',
    ],
    want_name => 'MXCC::Test::BasicFoo::Smitty',
    want_can  => [ qw(foo method_smitty) ],
  },
);

for my $test (@tests) {
  my ($args, $x_name, $x_methods) = @$test{ qw(given want_name want_can) };

  my $test_name = $x_name;
  subtest $test_name => sub {
    plan tests => 1 + @$x_methods + 1;

    my $class = class(@$args);
    is($class, $x_name, "got the expected class name");
    for my $method (@$x_methods) {
      ok($class->can($method), "the class can ->$method");
    }
    is($class, class(@$args), "memoization okay");
  }
}

{
  my $comp_2 = MooseX::ClassCompositor->new({
    class_basename  => 'MXCC::Test',
    class_metaroles => {
      class => [ 'MooseX::StrictConstructor::Trait::Class' ],
    },
    fixed_roles => [ 'BasicFoo' ],
    role_prefixes   => {
      '' => 't::lib::',
    },
  });

  my $class = $comp_2->class_for(qw(BasicBar));

  ok($class->does('t::lib::BasicFoo'));
  ok($class->does('t::lib::BasicBar'));
}

done_testing;
