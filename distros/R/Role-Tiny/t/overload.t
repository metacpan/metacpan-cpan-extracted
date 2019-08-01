use strict;
use warnings;
use Test::More;

BEGIN {
  package MyRole;
  use Role::Tiny;

  sub as_string { "welp" }
  sub as_num { 219 }
  use overload
    '""' => \&as_string,
    '0+' => 'as_num',
    bool => sub(){0},
    fallback => 1;
}

BEGIN {
  package MyClass;
  use Role::Tiny::With;
  with 'MyRole';
  sub new { bless {}, shift }
}

BEGIN {
  package MyClass2;
  use overload
    fallback => 0,
    '""' => 'class_string',
    '0+' => sub { 42 },
    ;
  use Role::Tiny::With;
  with 'MyRole';
  sub new { bless {}, shift }
  sub class_string { 'yarp' }
}

BEGIN {
  package MyClass3;
  sub new { bless {}, shift }
}

{
  my $o = MyClass->new;
  is "$o", 'welp', 'subref overload';
  is sprintf('%d', $o), 219, 'method name overload';
  ok !$o, 'anon subref overload';
}

{
  my $o = MyClass2->new;
  eval { my $f = 0+$o };
  like $@, qr/no method found/, 'fallback value not overwritten';
  is "$o", 'yarp', 'method name overload not overwritten';
  is sprintf('%d', $o), 42, 'subref overload not overwritten';
}

{
  my $orig = MyClass3->new;
  my $copy = $orig;
  Role::Tiny->apply_roles_to_object($orig, 'MyRole');
  for my $o ($orig, $copy) {
    my $copied = \$o == \$copy ? ' copy' : '';
    local $TODO = 'magic not applied to all ref copies on perl < 5.8.9'
      if $copied && "$]" < 5.008009;
    is "$o", 'welp', 'subref overload applied to instance'.$copied;
    is sprintf('%d', $o), 219, 'method name overload applied to instance'.$copied;
    ok !$o, 'anon subref overload applied to instance'.$copied;
  }
}

{
  my $o = MyClass3->new;
  Role::Tiny->apply_roles_to_package('MyClass3', 'MyRole');
  local $TODO = 'magic not applied to existing objects on perl < 5.18'
    if "$]" < 5.018;
  is "$o", 'welp', 'subref overload applied to class with instance';
  is sprintf('%d', $o), 219, 'method name overload applied to class with instance';
  ok !$o, 'anon subref overload applied to class with instance';
}

done_testing;
