use strict;
use warnings;
use Test::More;

{
  package R1;
  use Role::Tiny;

  sub foo {}

  $INC{"R1.pm"} = __FILE__;
}

{
  package R2;
  use Role::Tiny;

  sub foo {}

  $INC{"R2.pm"} = __FILE__;
}

{
  package X;
  sub new {
      bless {} => shift
  }
}

eval { Role::Tiny->apply_roles_to_object(X->new, "R1", "R2") };
like $@,
  qr/^Due to a method name conflict between roles 'R1' and 'R2', the method 'foo' must be implemented by 'X'/,
  'apply conflicting roles to object';

eval { Role::Tiny->apply_roles_to_object(X->new); 1 }
  or $@ ||= "false exception!";
like $@,
  qr/^No roles supplied!/,
  'apply no roles to object';


done_testing;
