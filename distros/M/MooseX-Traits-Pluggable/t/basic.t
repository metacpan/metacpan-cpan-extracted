use strict;
use warnings;
use Test::More tests => 43*2;
use Test::Exception;

{ package t::Trait;
  use Moose::Role;
  has 'foo' => (
      is       => 'ro',
      isa      => 'Str',
      required => 1,
  );
  sub test_method {
      return 't::Trait::test_method';
  }

  package t::Class;
  use Moose;
  with 'MooseX::Traits::Pluggable';
  has '+_traits_behave_like_roles' => (default => 1);

  sub test_method {
      return 't::Class::test_method';
  }

  package t::Another::t::Trait;
  use Moose::Role;
  has 'bar' => (
      is       => 'ro',
      isa      => 'Str',
      required => 1,
  );

  package t::Another::Class;
  use Moose;
  with 'MooseX::Traits::Pluggable';
  has '+_trait_namespace' => ( default => 't::Another' );

  package t::NS1;
  use Moose;

  package t::NS1::Trait::t::Foo;
  use Moose::Role;
  has 'bar' => (is => 'ro', required => 1);

  package t::NS2;
  use Moose;
  use base 't::NS1';
  with 'MooseX::Traits::Pluggable';
  has '+_trait_namespace' => (
      default => sub { [qw/+Trait t::ExtraNS::Trait/] }
  );

  package t::NS2::Trait::t::Bar;
  use Moose::Role;
  has 'baz' => (is => 'ro', required => 1);

  package t::ExtraNS::Trait::t::Extra;
  use Moose::Role;
  has 'extra' => (is => 'ro', required => 1);
}

my @method = (
    sub {
        my $class = shift;
        return $class->new_with_traits(@_)
    },
    sub {
        my $class = shift;
        my %args = ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;
        my @traits = @{ delete $args{traits} || [] };
        my $self = $class->new(%args);
        $self->apply_traits(\@traits => \%args);
        return $self
    },
);

for my $new_with_traits (@method) {
{
    my $instance = t::Class->$new_with_traits( traits => ['t::Trait'], foo => 'hello' );
    isa_ok $instance, 't::Class';
    can_ok $instance, 'foo';
    is $instance->foo, 'hello';
    isnt ref($instance), 't::Class';
    is $instance->_original_class_name, 't::Class';
    is_deeply $instance->_traits, ['t::Trait'];
    is_deeply $instance->_resolved_traits, ['t::Trait'];
    is $instance->test_method, 't::Class::test_method',
        "sub in consuming class doesn't get overriden by sub from role";
}

{
# Carp chokes here
    local $SIG{__WARN__} = sub {};
    local *Carp::caller_info = sub {};

    throws_ok {
        t::Class->$new_with_traits( traits => ['t::Trait'] );
    } qr/required/, 'foo is required';
}

{
    my $instance = t::Class->$new_with_traits;
    isa_ok $instance, 't::Class';
    ok !$instance->can('foo'), 'this one cannot foo';
}
{
    my $instance = t::Class->$new_with_traits( traits => [] );
    isa_ok $instance, 't::Class';
    ok !$instance->can('foo'), 'this one cannot foo either';
}
{
    my $instance = t::Another::Class->$new_with_traits( traits => ['t::Trait'], bar => 'bar' );
    isa_ok $instance, 't::Another::Class';
    can_ok $instance, 'bar';
    is $instance->bar, 'bar';
}
# try hashref form
{
    my $instance = t::Another::Class->$new_with_traits({ traits => ['t::Trait'], bar => 'bar' });
    isa_ok $instance, 't::Another::Class';
    can_ok $instance, 'bar';
    is $instance->bar, 'bar';
}

{
    my $instance = t::Another::Class->$new_with_traits(
        traits   => ['t::Trait', '+t::Trait'],
        foo      => 'foo',
        bar      => 'bar',
    );
    isa_ok $instance, 't::Another::Class';
    can_ok $instance, 'foo';
    can_ok $instance, 'bar';
    is $instance->foo, 'foo';
    is $instance->bar, 'bar';
    is_deeply $instance->_traits, ['t::Trait', '+t::Trait'];
    is_deeply $instance->_resolved_traits, ['t::Another::t::Trait', 't::Trait'];
}
{
# Carp chokes here too
    local $SIG{__WARN__} = sub {};
    local *Carp::caller_info = sub {};

    throws_ok {
        t::NS2->$new_with_traits(traits => ['NonExistant']);
    } qr/Could not find a class/, 'unfindable trait throws exception';
}
{
    my $instance = t::NS2->$new_with_traits(
        traits   => ['+t::Trait', 't::Foo', 't::Bar', 't::Extra'],
        foo      => 'foo',
        bar      => 'bar',
        baz      => 'baz',
        extra    => 'extra',
    );
    isa_ok $instance, 't::NS2';
    isa_ok $instance, 't::NS1';
    ok $instance->meta->does_role('t::Trait');
    ok $instance->meta->does_role('t::NS1::Trait::t::Foo');
    ok $instance->meta->does_role('t::NS2::Trait::t::Bar');
    ok $instance->meta->does_role('t::ExtraNS::Trait::t::Extra');
    can_ok $instance, 'foo';
    can_ok $instance, 'bar';
    can_ok $instance, 'baz';
    can_ok $instance, 'extra';
    is $instance->foo, 'foo';
    is $instance->bar, 'bar';
    is $instance->baz, 'baz';
    is $instance->extra, 'extra';
    is_deeply $instance->_traits, ['+t::Trait', 't::Foo', 't::Bar', 't::Extra'];
    is_deeply $instance->_resolved_traits,
        ['t::Trait', 't::NS1::Trait::t::Foo', 't::NS2::Trait::t::Bar', 't::ExtraNS::Trait::t::Extra'];
}
}
