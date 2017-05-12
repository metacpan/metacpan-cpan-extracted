use Test::More;
use strict; use warnings;

{ package ArrayType::Basic;
  use strict; use warnings;
  use Object::ArrayType::New [ foo => 'FOO', bar => '', baz => '' ];
  sub foo { shift->[FOO] }
  sub bar { shift->[BAR] }
  sub baz { shift->[BAZ] }
}

my $obj = ArrayType::Basic->new(
  foo => 1,
  bar => 2
);

isa_ok $obj, 'ArrayType::Basic';
ok $obj->foo == 1, 'foo ok';
ok $obj->bar == 2, 'bar ok';
ok !defined $obj->baz, 'baz ok';

$obj = $obj->new(
  +{ foo => 1 }
);

isa_ok $obj, 'ArrayType::Basic';
ok $obj->foo == 1, 'hash passed to $obj->new ok';
ok !defined $obj->bar, 'bar undef ok';


{ package ArrayType::HashOpts;
  use strict; use warnings;
  use Object::ArrayType::New +{ foo => '_foo', bar => '_bar' };
  sub foo { shift->[_foo] }
  sub bar { shift->[_bar] }
}

$obj = ArrayType::HashOpts->new(
  foo => 123,
  bar => 456
);

isa_ok $obj, 'ArrayType::HashOpts';
ok $obj->foo == 123, 'hash-type params foo ok';
ok $obj->bar == 456, 'hash-type params bar ok';


{ package ArrayType::NullArgs;
  use strict; use warnings;
  use Object::ArrayType::New
    [ '' => '_FOO', bar => '', '' => '_BAZ' ];
  sub _private_foo { shift->[_FOO] ||= 1 }
  sub _private_baz { shift->[_BAZ] ||= 2 }
  sub bar { shift->[BAR] }
}

$obj = ArrayType::NullArgs->new(
  bar => 123,
);

isa_ok $obj, 'ArrayType::NullArgs';
ok $obj->_private_foo == 1, 'params with null args foo ok';
ok $obj->_private_baz == 2, 'params with null args baz ok';
ok $obj->bar == 123, 'params with null args bar ok';

{ package ArrayType::NoParams;
  use strict; use warnings;
  use Object::ArrayType::New;
}

$obj = ArrayType::NoParams->new;
isa_ok $obj, 'ArrayType::NoParams';

done_testing
