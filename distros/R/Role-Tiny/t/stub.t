use strict;
use warnings;
use Test::More;

use Role::Tiny ();

{
  eval q{
    package RoleWithMatchingSub;
    use Role::Tiny;
    sub stubsub { "stubsub" }
    1;
  } or die $@;

  my $e;
  if (!eval q{
    package ClassWithStub;
    use Role::Tiny::With;

    sub stubsub;

    with 'RoleWithMatchingSub';
    1;
  }) {
    $e = $@;
  }

  is $e, undef,
    'no error composing role in class with stub';

  ok exists &ClassWithStub::stubsub && !defined &ClassWithStub::stubsub,
    'stub sub prevents composing matching sub';
}

{
  eval q{
    package RoleWithStub;
    use Role::Tiny;
    sub stubsub;
    1;
  } or die $@;

  my $e;
  if (!eval q{
    package ComposeStub;
    use Role::Tiny::With;

    with 'RoleWithStub';
    1;
  }) {
    $e = $@;
  }

  is $e, undef,
    'no error composing role with stub';

  ok exists &ComposeStub::stubsub && !defined &ComposeStub::stubsub,
    'composing role includes stub subs';
}

done_testing;
