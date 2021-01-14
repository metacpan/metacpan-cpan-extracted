use strict;
use warnings;
use Test::More;

my %apply_steps;
BEGIN {
  package MyRoleTinyExtension;
  use Role::Tiny ();
  our @ISA = qw(Role::Tiny);

  sub role_application_steps {
    my $self = shift;
    return (
      'role_apply_before',
      $self->SUPER::role_application_steps(@_),
      'Fully::Qualified::role_apply_after',
    );
  };

  sub role_apply_before {
    my ($self, $to, $role) = @_;
    ::ok !Role::Tiny::does_role($to, $role),
      "$role not applied to $to yet";
    $apply_steps{$to}{$role}{before}++;
  }
  sub Fully::Qualified::role_apply_after {
    my ($self, $to, $role) = @_;
    ::ok +Role::Tiny::does_role($to, $role),
      "$role applied to $to";
    $apply_steps{$to}{$role}{after}++;
  }
}

{
  package ExtendedRole;
  MyRoleTinyExtension->import;

  sub added_sub {}
}

{
  package ApplyTo;
  MyRoleTinyExtension->apply_role_to_package(__PACKAGE__, 'ExtendedRole');
}

is $apply_steps{'ApplyTo'}{'ExtendedRole'}{before}, 1,
  'before step was run';

is $apply_steps{'ApplyTo'}{'ExtendedRole'}{after}, 1,
  'after step was run';

done_testing;
