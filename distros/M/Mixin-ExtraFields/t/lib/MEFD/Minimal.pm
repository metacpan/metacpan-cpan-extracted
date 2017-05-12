
use strict;
use warnings;

# This is a stripped-down HashGuts, used to test the fallback behavior of
# methods in the driver base class.

package MEFD::Minimal;
use base qw(Mixin::ExtraFields::Driver);

sub from_args {
  bless {} => $_[0];
}

sub get_all_detailed_extra {
  my ($self, $object, $id) = @_;

  my $stash = $object->{_stash};
  my @all = map { $_ => { value => $stash->{$_} } } keys %$stash;
}

sub delete_extra {
  my ($self, $object, $id, $name) = @_;
  delete $object->{_stash}{$name};
}

sub set_extra {
  my ($self, $object, $id, $name, $value) = @_;
  $object->{_stash}{$name} = $value;
}

1;
