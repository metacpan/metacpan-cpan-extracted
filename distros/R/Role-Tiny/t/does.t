use strict;
use warnings;
use Test::More;

BEGIN {
  package Local::Role1;
  use Role::Tiny;
}

BEGIN {
  package Local::Role2;
  use Role::Tiny;
}

BEGIN {
  package Local::Class1;
  use Role::Tiny::With;
  with qw(
    Local::Role1
    Local::Role2
  );
}

BEGIN {
  package Local::Class2;
  use Role::Tiny::With;
  with qw( Local::Role1 );
  with qw( Local::Role2 );
}

BEGIN {
  package Local::Class3;
  use Role::Tiny::With;
  with qw( Local::Role1 );
  with qw( Local::Role2 );
  sub DOES {
    my ($proto, $role) = @_;
    return 1 if $role eq 'Local::Role3';
    return $proto->Role::Tiny::does_role($role);
  }
}

for my $c (1 .. 3) {
  my $class = "Local::Class$c";
  for my $r (1 .. 2) {
    my $role = "Local::Role$r";
    ok($class->does($role), "$class\->does($role)");
    ok($class->DOES($role), "$class\->DOES($role)");
  }
}

{
  my $class = "Local::Class3";
  my $role = "Local::Role3";
  ok( ! $class->does($role), "$class\->does($role)");
  ok(   $class->DOES($role), "$class\->DOES($role)");
}

done_testing;
