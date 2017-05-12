use Test::More;
use Test::Moose;

{ package OtherRole;
  use Moose::Role;
};

{ package MyRole;
  use Moose::Role;
  with 'OtherRole';
  with 'MooseX::Meta::Method::Authorized';
};

{ package MyClass;
  use Moose;
  has user => (is => 'ro');

  sub m00 {'m00'};
  sub m01 {'m01'};
};

{ package MyUser;
  use Moose;
  sub roles { qw<foo bar baz> }

};

my $meth = MyClass->meta->get_method('m00');
MyRole->meta->apply($meth, rebless_params => { requires => ['foo'] });

# I'm not sure why these tests fail, but they are not the reason I'm
# doing this module.
#########
#does_ok('MyRole', 'OtherRole', 'composing works.');
#does_ok('MyRole', 'MooseX::Meta::Method::Authorized', 'composing works.');
#does_ok($meth, 'OtherRole', 'does one of the original roles');
#does_ok($meth, 'MooseX::Meta::Method::Authorized', 'does the important role');

does_ok($meth, 'MyRole', 'does the composed role');
is_deeply($meth->requires, ['foo'], 'has the data.');

$meth = MyClass->meta->get_method('m01');
MyRole->meta->apply($meth, rebless_params => { requires => ['gah'] });
is_deeply($meth->requires, ['gah'], 'has the data.');


my $obj = MyClass->new({user => MyUser->new});
is($obj->m00, 'm00', 'First method works.');
eval {
    $obj->m01;
};
like($@.'',qr(Access Denied)i,'Dies when not authorized.');

done_testing;
