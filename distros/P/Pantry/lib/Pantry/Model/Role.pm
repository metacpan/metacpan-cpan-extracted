use v5.14;
use warnings;

package Pantry::Model::Role;
# ABSTRACT: Pantry data model for Chef roles
our $VERSION = '0.012'; # VERSION

use Moose 2;
use MooseX::Types::Path::Class::MoreCoercions qw/File/;
use Carp qw/croak/;
use List::AllUtils qw/uniq first/;
use Pantry::Model::EnvRunList;
use Pantry::Model::Util qw/hash_to_dot dot_to_hash/;
use namespace::autoclean;

# new_from_file, save_as
with 'Pantry::Role::Serializable' => {
  freezer => '_freeze',
  thawer => '_thaw',
};

# in_run_list, append_to_runliset
with 'Pantry::Role::Runlist';

#--------------------------------------------------------------------------#
# Chef role attributes
#--------------------------------------------------------------------------#

has _path => (
  is => 'ro',
  reader => 'path',
  isa => File,
  coerce => 1,
  predicate => 'has_path',
);

has name => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has description => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_description {
  my $self = shift;
  return "The " . $self->name . " role";
}


has default_attributes => (
  is => 'bare',
  isa => 'HashRef',
  traits => ['Hash'],
  default => sub { +{} },
  handles => {
    set_default_attribute => 'set',
    get_default_attribute => 'get',
    delete_default_attribute => 'delete',
  },
);


has override_attributes => (
  is => 'bare',
  isa => 'HashRef',
  traits => ['Hash'],
  default => sub { +{} },
  handles => {
    set_override_attribute => 'set',
    get_override_attribute => 'get',
    delete_override_attribute => 'delete',
  },
);

has env_run_lists => (
  is => 'bare',
  isa => 'HashRef[Pantry::Model::EnvRunList]',
  traits => ['Hash'],
  default => sub { +{} },
  handles => {
    set_env_run_list => 'set',
    get_env_run_list => 'get',
    delete_env_run_list => 'delete',
  },
);


sub append_to_env_run_list {
  my ($self, $env, $items) = @_;
  croak "append_to_env_runlist requires an environment name"
    unless $env;
  croak "append_to_env_runlist requires an array reference of items to append"
    unless ref($items) eq 'ARRAY';

  my $runlist;
  unless ( $runlist = $self->get_env_run_list($env) ) {
    $runlist = Pantry::Model::EnvRunList->new;
    $self->set_env_run_list( $env => $runlist );
  }

  $runlist->append_to_run_list( @$items );
  return;
}



sub remove_from_env_run_list {
  my ($self, $env, $items) = @_;
  croak "remove_from_env_runlist requires an environment name"
    unless $env;
  croak "remove_from_env_runlist requires an array reference of items to append"
    unless ref($items) eq 'ARRAY';

  if ( my $runlist = $self->get_env_run_list($env) ) {
    $runlist->remove_from_run_list( @$items );
  }

  return;
}


sub save {
  my ($self) = @_;
  die "No _path attribute set" unless $self->has_path;
  return $self->save_as( $self->path );
}

my @attribute_keys = qw/default_attributes override_attributes/;

sub _freeze {
  my ($self, $data) = @_;
  for my $attr ( qw/default_attributes override_attributes/ ) {
    my $old = delete $data->{$attr};
    my $new = {};
    for my $k ( keys %$old ) {
      dot_to_hash($new, $k, $old->{$k});
    }
    $data->{$attr} = $new;
  }
  for my $env ( keys %{$data->{env_run_lists}} ) {
    my $obj = delete $data->{env_run_lists}{$env};
    $data->{env_run_lists}{$env} = [ $obj->run_list ];
  }
  $data->{json_class} = "Chef::Role";
  $data->{chef_type} = "role";
  return $data;
}

sub _thaw {
  my ($self, $data) = @_;
  delete $data->{$_} for qw/json_class chef_type/;
  for my $attr ( qw/default_attributes override_attributes/ ) {
    my $old = delete $data->{$attr};
    my $new = {};
    for my $k ( keys %$old ) {
      my $v = $old->{$k};
      $k =~ s{\.}{\\.}g; # escape existing dots in key
      for my $pair ( hash_to_dot($k, $v) ) {
        my ($key, $value) = @$pair;
        $new->{$key} = $value;
      }
    }
    $data->{$attr} = $new;
  }
  for my $env ( keys %{$data->{env_run_lists}} ) {
    my $obj = Pantry::Model::EnvRunList->new;
    $obj->append_to_run_list(@{delete $data->{env_run_lists}{$env}});
    $data->{env_run_lists}{$env} = $obj;
  }
  return $data;
}

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=head1 NAME

Pantry::Model::Role - Pantry data model for Chef roles

=head1 VERSION

version 0.012

=head1 DESCRIPTION

Under development.

=head1 ATTRIBUTES

=head2 default_attributes

This attribute holds role default attribute data as key-value pairs.  Keys may
be separated by a period to indicate nesting (literal periods must be
escaped by a backslash).  Values should be scalars or array references.

=head2 override_attributes

This attribute holds role override attribute data as key-value pairs.  Keys may
be separated by a period to indicate nesting (literal periods must be
escaped by a backslash).  Values should be scalars or array references.

=head1 METHODS

=head2 set_default_attribute

  $role->set_default_attribute("nginx.port", 80);

Sets the role default attribute for the given key to the given value.

=head2 get_default_attribute

  my $port = $role->get_default_attribute("nginx.port");

Returns the role default attribute for the given key.

=head2 delete_default_attribute

  $role->delete_default_attribute("nginx.port");

Deletes the role default attribute for the given key.

=head2 set_override_attribute

  $role->set_override_attribute("nginx.port", 80);

Sets the role override attribute for the given key to the given value.

=head2 get_override_attribute

  my $port = $role->get_override_attribute("nginx.port");

Returns the role override attribute for the given key.

=head2 delete_override_attribute

  $role->delete_override_attribute("nginx.port");

Deletes the role override attribute for the given key.

=head2 append_to_env_run_list

  $role->append_to_env_run_list( $env, \@items );

Appends items to an environment-specific runlist.

=head2 remove_from_env_run_list

  $role->remove_from_env_run_list( $env, \@items );

Removes items from an environment-specific runlist.

=head2 save

Saves the node to a file in the pantry.  If the private C<_path>
attribute has not been set, an exception is thrown.

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
