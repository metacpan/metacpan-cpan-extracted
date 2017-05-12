use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util qw(refaddr);
use Moose::Util qw(does_role);

{ package Role;
  use Moose::Role;
  requires 'foo';
  requires 'bar';
}

{ package Object;
  use Moose;
  has [qw/foo bar baz/] => ( is => 'rw' );
  with 'Role';
  Object->meta->make_immutable;
}

{ package Set;
  use Moose;
  use MooseX::MultiObject;

  setup_multiobject (
      role => 'Role',
  );
}

for(1..2){
    my $a = Object->new;
    my $b = Object->new( foo => 42, bar => 123 );

    my $set = Set->new( objects => [$b] );
    is_deeply [$set->foo], [42], 'set->foo works';
    is_deeply [$set->bar], [123], 'set->bar works';
    ok !$set->can('baz'), 'set cannot baz';
    $set->add_managed_object($a);

    is_deeply [sort map { refaddr $_ } $set->get_managed_objects],
              [sort map { refaddr $_ } $a, $b],
        'got objects';

    { no warnings 'uninitialized';
      is_deeply [sort $set->foo], [sort 42, undef], 'set->foo works';
      is_deeply [sort $set->bar], [sort 123, undef], 'set->bar works';
    }
    $set->foo('yay');
    is_deeply [$set->foo], ['yay', 'yay'], 'setting works';
    is $a->foo, 'yay';
    is $b->foo, 'yay';

    diag "retrying tests after make_immutable" if $_ == 1;
    Set->meta->make_immutable;
}

ok does_role('Set', 'MooseX::MultiObject::Role'), 'does multiobject role';
ok does_role('Set', 'Role'), 'does { role => ... } role';

{ package Class;
  use Moose;
  use MooseX::APIRole;
  sub foo {}
  make_api_role 'Class::API';
}

{ package Class::Alike;
  use Moose;
  with 'Class::API';
  sub foo {}
}

{ package Multi::Class;
  use Moose;
  use MooseX::MultiObject;

  setup_multiobject (
      class => 'Class',
  );

  __PACKAGE__->meta->make_immutable;
}

ok does_role('Multi::Class', 'Class::API'), 'Multi::Class does the API role';
can_ok 'Multi::Class', 'foo';

my $multi = Multi::Class->new;
lives_ok {
    $multi->add_managed_object(Class->new);
} 'adding Class is ok';

throws_ok {
    $multi->add_managed_object(Class::Alike->new);
} qr/not an object that can be added/, 'a class-alike is not good enough';

lives_ok { $multi->foo }
    'you can still use the object even after touching it inappropriately';

done_testing;
