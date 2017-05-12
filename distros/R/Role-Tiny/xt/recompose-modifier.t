use strict;
use warnings;
use Test::More;
{
  package ModifierRole;
  use Role::Tiny;

  sub method { 0 }
  around method => sub {
    my $orig = shift;
    my $self = shift;
    $self->$orig(@_) + 1;
  };
}

{
  package Role1;
  use Role::Tiny;

  with 'ModifierRole';
}

{
  package Role2;
  use Role::Tiny;

  with 'ModifierRole';
}

{
  package ComposingClass1;
  use Role::Tiny::With;

  with qw(Role1 Role2);
}

is +ComposingClass1->method, 1, 'recomposed modifier called once';

{
  package ComposingClass2;
  use Role::Tiny::With;

  with 'Role1';
  with 'Role2';
}

is +ComposingClass2->method, 1, 'recomposed modifier called once (separately composed)';

{
  package DoubleRole;

  use Role::Tiny;
  with qw(Role1 Role2);
}

{
  package ComposingClass3;
  use Role::Tiny::With;

  with 'DoubleRole';
}

is +ComposingClass3->method, 1, 'recomposed modifier called once (via composing role)';

{
  package DoubleRoleSeparate;

  use Role::Tiny;
  with 'Role1';
  with 'Role2';
}

{
  package ComposingClass4;
  use Role::Tiny::With;

  with qw(DoubleRoleSeparate);
}

is +ComposingClass4->method, 1, 'recomposed modifier called once (via separately composing role)';

done_testing;
