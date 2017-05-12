package RWDE::DB::Cachable;

use strict;
use warnings;

use NEXT;

use Error qw(:try);
use RWDE::Exceptions;

use RWDE::DB::MemcachedRegistry;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 508 $ =~ /(\d+)/;

## @method protected object _fetch_by_id()
# Private routine to fetch a record by class_id
# @return the populated object
sub _fetch_by_id {
  my ($self, $params) = @_;

  my $id = $$params{ $self->{_id} };

  my $memh = RWDE::DB::MemcachedRegistry->get_memh({ host => $self->{_cache_host} });

  my $term = $memh->get({ key => $self->get_cache_key({ id => $id }) });

  if (not defined $term) {
    $term = $self->NEXT::_fetch_by_id($params);
    $memh->add({ term => $term });
  }

  return $term;
}

## @method void update_record()
# Update the record specified by the C<id> field with values
# specified in the data fields of this object.  Only updates the fields
# specified -- other fields are left alone.  Returns 1 on on success, or
# throws an exception on failure.
#
# Exceptions classes thrown are C<dberr> on database error or
# C<data.missing> for a missing ID.

sub update_record {
  my ($self, $params) = @_;

  $self->NEXT::update_record($params);

  $self->delete_cache();

  return ();
}

## @method void update_all()
# (Enter update_all info here)
sub update_all {
  my ($self, $params) = @_;

  $self->NEXT::update_all($params);

  $self->delete_cache();

  return ();
}

## @method void delete_cache()
# (Enter delete_cache info here)
sub delete_cache {
  my ($self, $params) = @_;

  my $memh = RWDE::DB::MemcachedRegistry->get_memh({ host => $self->{_cache_host} });

  $memh->delete({ term => $self });

  return ();
}

sub get_cache_key {
  my ($self, $params) = @_;

  if (defined $$params{id}) {
    return $self->get_id_name . '::' . $$params{id};
  }
  else {
    return $self->get_id_name . '::' . $self->get_id;
  }
}

1;

