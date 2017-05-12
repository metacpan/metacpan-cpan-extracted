
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strictures 1;
use Test::More 0.98;

do {
    package MyTest::ParamRole;
    use MooseX::Role::Parameterized;
    use syntax qw( simple/v2 );
    parameter name => (is => 'ro');
    fun foo ($x) { fun ($y) { $x + $y } };
    ::is(foo(23)->(17), 40, 'function definitions');
    role {
        my $name = $parameter->name;
        method "$name" ($x) { $x }
        my %modifier;
        before "$name" ($x) { $modifier{before} = $x }
        after  "$name" ($x) { $modifier{after}  = $x }
        around "$name" ($x) { $modifier{around} = $x; $self->$orig($x) }
        method modifiers { %modifier }
        method anonymous { method ($x) { $x * 2 } }
    };
    for (1) {
        ::ok $_, 'body is terminated';
    }
};

do {
    package MyTest::ParamRoleExplicitParam;
    use MooseX::Role::Parameterized;
    use syntax qw( simple/v2 );
    parameter foo => (is => 'ro');
    role ($p) {
        method getfoo { $p->foo }
    }
};

do {
    package MyTest::Consumer;
    use Moose;
    with 'MyTest::ParamRole' => { name => 'foo' };
    with 'MyTest::ParamRoleExplicitParam' => { foo => 23 };
    my $class = __PACKAGE__;
    ::is($class->foo(23), 23, 'method value passing');
    my %modifier = $class->modifiers;
    ::is($modifier{ $_ }, 23, "correct value in $_")
        for qw( before after around );
    ::is($class->${\($class->anonymous)}(23), 46, 'anonymous methods');
    ::is($class->getfoo, 23, 'parameterized with explicit argument');
};

done_testing;
