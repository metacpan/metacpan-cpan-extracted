use Test::More;
use strict; use warnings FATAL => 'all';

BEGIN {
  unless (eval {; require Class::Method::Modifiers; 1 } && !$@) {
    require Test::More;
    Test::More::plan(skip_all =>
      'these tests require Class::Method::Modifiers'
    );
  }
}

{ package WithDefaults;
  use strict; use warnings FATAL => 'all';
  use Class::Method::Modifiers;
  use Object::ArrayType::New
    [ foo => undef, bar => undef ];
  sub foo { shift->[FOO] }
  sub bar { shift->[BAR] }
  around new => sub {
    my ($orig, $class) = splice @_, 0, 2;
    my $self = $class->$orig(@_);
    $self->[BAR] = 'weeble' unless defined $self->[BAR];
    $self
  };
}

my $obj = WithDefaults->new;
isa_ok $obj, 'WithDefaults';
ok !defined $obj->foo,    'foo not defined ok';
ok $obj->bar eq 'weeble', 'bar set default ok';

done_testing
