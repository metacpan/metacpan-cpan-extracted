use strict;
use warnings;
no warnings 'once';
use Test::More;

BEGIN {
  package MyRole1;

  our $before_scalar = 1;
  sub before_sub {}
  sub before_sub_blessed {}
  sub before_stub;
  sub before_stub_proto ($);
  use constant before_constant => 1;
  use constant before_constant_list => (4, 5);
  use constant before_constant_glob => 1;
  our $before_constant_glob = 1;
  use constant before_constant_inflate => 1;
  use constant before_constant_list_inflate => (4, 5);
  use constant before_constant_deflate => 1;

  # subs stored directly in the stash are meant to be supported in perl 5.22+,
  # but until 5.26.1 they have a risk of segfaulting.  perl itself won't ever
  # install subs in exactly this form, so we're safe to just dodge the issue
  # in the test and not account for it in Role::Tiny itself.
  BEGIN {
    if ("$]" >= 5.026001) {
      $MyRole1::{'blorf'} = sub { 'blorf' };
    }
  }

  use Role::Tiny;
  no warnings 'once';

  our $after_scalar = 1;
  sub after_sub {}
  sub after_sub_blessed {}
  sub after_stub;
  sub after_stub_proto ($);
  use constant after_constant => 1;
  use constant after_constant_list => (4, 5);
  use constant after_constant_glob => 1;
  our $after_constant_glob = 1;
  use constant after_constant_inflate => (my $f = 1);
  use constant after_constant_list_inflate => (4, 5);

  for (
    \&before_constant_inflate,
    \&before_constant_list_inflate,
    \&after_constant_inflate,
    \&after_constant_list_inflate,
  ) {}

  my $deflated = before_constant_deflate;

  bless \&before_sub_blessed;
  bless \&after_sub_blessed;
}

{
  package MyClass1;
  no warnings 'once';

  our $GLOBAL1 = 1;
  sub method {}
}

my @methods = qw(
  after_sub
  after_sub_blessed
  after_stub
  after_stub_proto
  after_constant
  after_constant_list
  after_constant_glob
  after_constant_inflate
  after_constant_list_inflate
);

my $type = ref $MyRole1::{'blorf'};

my $role_methods = Role::Tiny->_concrete_methods_of('MyRole1');
is_deeply([sort keys %$role_methods], [sort @methods],
  'only subs after Role::Tiny import are methods' );

# only created on 5.26, but types will still match
is ref $MyRole1::{'blorf'}, $type,
  '_concrete_methods_of does not inflate subrefs in stash';

my @role_method_list = Role::Tiny->methods_provided_by('MyRole1');
is_deeply([sort @role_method_list], [sort @methods],
  'methods_provided_by gives method list' );

my $class_methods = Role::Tiny->_concrete_methods_of('MyClass1');
is_deeply([sort keys %$class_methods], ['method'],
  'only subs from non-Role::Tiny packages are methods' );

eval { Role::Tiny->methods_provided_by('MyClass1') };
like $@,
  qr/is not a Role::Tiny/,
  'methods_provided_by refuses to work on classes';

{
  package Look::Out::Here::Comes::A::Role;
  use Role::Tiny;
  sub its_a_method { 1 }
}

{
  package And::Another::One;
  sub its_a_method { 2 }
  use Role::Tiny;

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  with 'Look::Out::Here::Comes::A::Role';
  ::is join('', @warnings), '',
    'non-methods not overwritten by role composition';
}

{
  package RoleLikeOldMoo;
  use Role::Tiny;
  sub not_a_method { 1 }

  # simulate what older versions of Moo do to mark non-methods
  $Role::Tiny::INFO{+__PACKAGE__}{not_methods}{$_} = $_
    for \&not_a_method;
}

is_deeply [Role::Tiny->methods_provided_by('RoleLikeOldMoo')], [],
  'subs marked in not_methods (like old Moo) are excluded from method list';

done_testing;
