use v5.14;
use warnings;

package Pantry::Model::Pantry;
# ABSTRACT: Pantry data model for a pantry directory
our $VERSION = '0.012'; # VERSION

use Moose 2;
use MooseX::Types::Path::Class::MoreCoercions 0.002 qw/AbsDir/;
use namespace::autoclean;

use Path::Class;
use Path::Class::Rule;


has path => (
  is => 'ro',
  isa => AbsDir,
  coerce => 1,
  default => sub { dir(".")->absolute }
);

# where environment JSON files and node subdirectories are stored
sub _environment_dir {
  my ($self) = @_;
  my $path = $self->path->subdir("environments");
  $path->mkpath;
  return $path;
}

# directory where nodes are stored in an environment
sub _node_dir {
  my ($self, $env) = @_;
  $env //= '_default';
  my $path = $self->_environment_dir->subdir($env);
  $path->mkpath;
  return $path;
}

sub _role_dir {
  my ($self) = @_;
  my $path = $self->path->subdir("roles");
  $path->mkpath;
  return $path;
}

sub _cookbook_dir {
  my ($self) = @_;
  my $path = $self->path->subdir("cookbooks");
  $path->mkpath;
  return $path;
}

sub _bag_dir {
  my ($self) = @_;
  my $path = $self->path->subdir("data_bags");
  $path->mkpath;
  return $path;
}

# file path where environment JSON file is located
sub _environment_path {
  my ($self, $env) = @_;
  return $self->_environment_dir->file("${env}.json");
}

sub _node_path {
  my ($self, $node_name, $env) = @_;
  return $self->_node_dir($env)->file("${node_name}.json");
}

sub _role_path {
  my ($self, $role_name) = @_;
  return $self->_role_dir->file("${role_name}.json");
}

sub _cookbook_path {
  my ($self, $cookbook_name) = @_;
  return $self->_cookbook_dir->subdir("${cookbook_name}");
}

sub _bag_path {
  my ($self, $bag_name) = @_;
  return $self->_bag_dir->file("${bag_name}.json");
}


sub all_nodes {
  my ($self, $options) = @_;
  return map { $_->[0] } $self->_all_node_path_map($options);
}

sub _all_node_path_map {
  my ($self, $options) = @_;
  my @env = $options->{env} ? ($options->{env}) : (map {$_->basename} grep {-d $_} $self->_environment_dir->children);
  my @nodes;
  for my $e ( @env ) {
    push @nodes,  map { [ $_, $e ] } map { s/\.json$//r } map { $_->basename } $self->_node_dir($e)->children;
  }
  return @nodes;

}


sub node {
  my ($self, $node_name, $options ) = @_;
  $options //= {};
  $options->{env} //= "_default";
  $node_name = lc $node_name;
  require Pantry::Model::Node;
  my $path = $self->_node_path( $node_name, $options->{env} );
  if ( -e $path ) {
    return Pantry::Model::Node->new_from_file( $path );
  }
  else {
    return Pantry::Model::Node->new( name => $node_name, _path => $path, %$options );
  }
}


sub find_node {
  my ($self, $pattern, $options) = @_;
  my @found = grep { $_->[0] =~ /^\Q$pattern\E/ } $self->_all_node_path_map($options);
  return map { $self->node($_->[0], {env => $_->[1]}) } @found;
}


sub all_roles {
  my ($self, $env) = @_;
  my @roles = sort map { s/\.json$//r } map { $_->basename }
              $self->_role_dir->children;
  return @roles;
}


sub role {
  my ($self, $role_name, $options) = @_;
  $role_name = lc $role_name;
  require Pantry::Model::Role;
  my $path = $self->_role_path( $role_name );
  if ( -e $path ) {
    return Pantry::Model::Role->new_from_file( $path );
  }
  else {
    return Pantry::Model::Role->new( name => $role_name, _path => $path );
  }
}


sub find_role {
  my ($self, $pattern, $options) = @_;
  return map { $self->role($_) } grep { $_ =~ /^\Q$pattern\E/ } $self->all_roles;
}


sub all_environments {
  my ($self, $env) = @_;
  my @environments =
    sort map { s/\.json$//r } map { $_->basename } grep { -f }
    $self->_environment_dir->children;
  return @environments;
}


sub environment {
  my ($self, $environment_name, $options) = @_;
  $environment_name = lc $environment_name;
  require Pantry::Model::Environment;
  my $path = $self->_environment_path( $environment_name );
  if ( -e $path ) {
    return Pantry::Model::Environment->new_from_file( $path );
  }
  else {
    return Pantry::Model::Environment->new( name => $environment_name, _path => $path );
  }
}


sub find_environment{
  my ($self, $pattern, $options) = @_;
  return map { $self->environment($_) } grep { $_ =~ /^\Q$pattern\E/ } $self->all_environments;
}


sub cookbook {
  my ($self, $cookbook_name, $env) = @_;
  $cookbook_name = lc $cookbook_name;
  require Pantry::Model::Cookbook;
  my $path = $self->_cookbook_path( $cookbook_name );
  return Pantry::Model::Cookbook->new( name => $cookbook_name, _path => $path );
}


sub all_bags {
  my ($self, $env) = @_;
  my $pcr = Path::Class::Rule->new->file;
  my @bags =
    sort map { s/\.json$//r }
    map { $_->relative($self->_bag_dir) }
    $pcr->all( $self->_bag_dir );
  return @bags;
}


sub bag {
  my ($self, $bag_name, $options) = @_;
  my ($dir_name, $item_name) = split "/", lc $bag_name;
  $item_name //= $bag_name;
  require Pantry::Model::DataBag;
  my $path = $self->_bag_path( $bag_name );
  if ( -e $path ) {
    return Pantry::Model::DataBag->new_from_file( $path );
  }
  else {
    return Pantry::Model::DataBag->new( name => $item_name, _path => $path );
  }
}


sub find_bag {
  my ($self, $pattern, $options) = @_;
  return map { $self->bag($_) } grep { $_ =~ /^\Q$pattern\E/ } $self->all_bags;
}

1;

__END__

=pod

=head1 NAME

Pantry::Model::Pantry - Pantry data model for a pantry directory

=head1 VERSION

version 0.012

=head1 SYNOPSIS

  my $pantry = Pantry::Model::Pantry->new;
  my $node = $pantry->node("foo.example.com");

=head1 DESCRIPTION

Models a 'pantry' -- a directory containing files used to manage servers with
Chef Solo by Opscode.

=head1 ATTRIBUTES

=head2 C<path>

Path to the pantry directory. Defaults to the current directory.

=head1 METHODS

=head2 all_nodes

  my @nodes = $pantry->all_nodes;

In list context, returns a list of nodes.  In scalar context, returns
a count of nodes.

=head2 C<node>

  my $node = $pantry->node("foo.example.com");

Returns a L<Pantry::Model::Node> object corresponding to the given node.
If the node exists in the pantry, it will be loaded from the saved node file.
Otherwise, it will be created in memory (but will not be persisted to disk).

=head2 find_node

  my @nodes = $pantry->find_node( $leading_part );

Finds one or more node matching a leading part.  For example, given
nodes 'foo.example.com' and 'bar.example.com' in a pantry, use
C<<$pantry->find_node("foo")>> to get 'foo.example.com'.

Returns a list of node objects if any are found.

=head2 all_roles

  my @roles = $pantry->all_roles;

In list context, returns a list of roles.  In scalar context, returns
a count of roles.

=head2 C<role>

  my $node = $pantry->role("web");

Returns a L<Pantry::Model::Role> object corresponding to the given role.
If the role exists in the pantry, it will be loaded from the saved role file.
Otherwise, it will be created in memory (but will not be persisted to disk).

=head2 find_role

  my @roles = $pantry->find_role( $leading_part );

Finds one or more role matching a leading part.  For example, given roles 'web'
and 'mysql' in a pantry, use C<<$pantry->find_role("my")>> to get 'mysql'.

Returns a list of role objects if any are found.

=head2 all_environments

  my @environments = $pantry->all_environments;

In list context, returns a list of environments.  In scalar context, returns
a count of environments.

=head2 C<environment>

  my $node = $pantry->environment("staging");

Returns a L<Pantry::Model::Environment> object corresponding to the given environment.

=head2 find_environment

  my @environments = $pantry->find_environment( $leading_part );

Finds one or more environment matching a leading part.  For example, given environments 'test'
and 'staging' in a pantry, use C<<$pantry->find_environment('sta')>> to get 'staging'.

Returns a list of environment objects if any are found.

=head2 C<cookbook>

  my $node = $pantry->cookbook("myapp");

Returns a L<Pantry::Model::Cookbook> object corresponding to the given cookbook.

=head2 all_bags

  my @bags = $pantry->all_bags;

In list context, returns a list of bags.  In scalar context, returns
a count of bags.

=head2 C<bag>

  my $node = $pantry->bag("xdg");

Returns a L<Pantry::Model::DataBag> object corresponding to the given bag.
If the bag exists in the pantry, it will be loaded from the saved bag file.
Otherwise, it will be created in memory (but will not be persisted to disk).

=head2 find_bag

  my @bags = $pantry->find_bag( $leading_part );

Finds one or more bag matching a leading part.  For example, given bags 'web'
and 'mysql' in a pantry, use C<<$pantry->find_bag("my")>> to get 'mysql'.

Returns a list of bag objects if any are found.

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
