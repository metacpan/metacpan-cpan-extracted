use strict;
use warnings;
use Test::More;

BEGIN {
  package My::Role::Tiny::Extension;
  $INC{'My/Role/Tiny/Extension.pm'} = __FILE__;
  use Role::Tiny ();
  our @ISA = qw(Role::Tiny);

  my %lie;

  sub _install_subs {
    my $me = shift;
    my ($role) = @_;
    local $lie{$role} = 1;
    $me->SUPER::_install_subs(@_);
  }

  sub is_role {
    my ($me, $role) = @_;
    return 0
      if $lie{$role};
    $me->SUPER::is_role($role);
  }
}

my @warnings;
BEGIN {
  package My::Thing::Using::Extended::Role;
  My::Role::Tiny::Extension->import;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  My::Role::Tiny::Extension->import;
}

my $methods = My::Role::Tiny::Extension->_concrete_methods_of('My::Thing::Using::Extended::Role');
is join(', ', sort keys %$methods), '',
  'subs installed when creating a role are not methods';

# there will be warnings but we don't care about them

done_testing;
