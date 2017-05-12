use strict;
use warnings;
use Test::More;
use Test::Fatal;

{ package Trait;
  use Moose::Role;
  has 'foo' => (
      is       => 'ro',
      isa      => 'Str',
      required => 1,
  );
  sub bar {
      return 'Trait::bar';
  }

  package Class;
  use Moose;
  with 'MooseX::Traits';
  sub bar {
      return 'Class::bar';
  }

  package Another::Trait;
  use Moose::Role;
  has 'bar' => (
      is       => 'ro',
      isa      => 'Str',
      required => 1,
  );

  package Another::Class;
  use Moose;
  with 'MooseX::Traits';
  has '+_trait_namespace' => ( default => 'Another' );

}

foreach my $trait ( 'Trait', ['Trait' ] ) {
    my $instance = Class->new_with_traits( traits => $trait, foo => 'hello' );
    isa_ok $instance, 'Class';
    can_ok $instance, 'foo';
    is $instance->foo, 'hello';

    TODO: { local $TODO = 'oh noes! please fix me';
    is $instance->bar, 'Class::bar',
        "sub in consuming class doesn't get overridden by sub from role";
    }
}

like
    exception { Class->with_traits('Trait')->new; },
    qr/required/,
    'foo is required';

{
    my $instance = Class->with_traits->new;
    isa_ok $instance, 'Class';
    ok !$instance->can('foo'), 'this one cannot foo';
}
{
    my $instance = Class->with_traits()->new;
    isa_ok $instance, 'Class';
    ok !$instance->can('foo'), 'this one cannot foo either';
}
{
    my $instance = Another::Class->with_traits( 'Trait' )->new( bar => 'bar' );
    isa_ok $instance, 'Another::Class';
    can_ok $instance, 'bar';
    is $instance->bar, 'bar';
}
# try hashref form
{
    my $instance = Another::Class->with_traits('Trait')->new({ bar => 'bar' });
    isa_ok $instance, 'Another::Class';
    can_ok $instance, 'bar';
    is $instance->bar, 'bar';
}
{
    my $instance = Another::Class->with_traits('Trait', '+Trait')->new(
        foo => 'foo',
        bar => 'bar',
    );
    isa_ok $instance, 'Another::Class';
    can_ok $instance, 'foo';
    can_ok $instance, 'bar';
    is $instance->foo, 'foo';
    is $instance->bar, 'bar';
}

done_testing;
