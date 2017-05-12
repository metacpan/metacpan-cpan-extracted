use v5.14;
use warnings;

package Pantry::Model::Node;
# ABSTRACT: Pantry data model for nodes
our $VERSION = '0.012'; # VERSION

use Moose 2;
use MooseX::Types::Path::Class::MoreCoercions qw/File/;
use List::AllUtils qw/uniq first/;
use Pantry::Model::Util qw/hash_to_dot dot_to_hash/;
use namespace::autoclean;

# new_from_file, save_as
with 'Pantry::Role::Serializable' => {
  freezer => '_freeze',
  thawer => '_thaw',
};


has name => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);


has env => (
  is => 'ro',
  isa => 'Str',
  default => '_default',
);


# in_run_list, append_to_runlist
with 'Pantry::Role::Runlist';

has _path => (
  is => 'ro',
  reader => 'path',
  isa => File,
  coerce => 1,
  predicate => 'has_path',
);


has attributes => (
  is => 'bare',
  isa => 'HashRef',
  traits => ['Hash'],
  default => sub { +{} },
  handles => {
    set_attribute => 'set',
    get_attribute => 'get',
    delete_attribute => 'delete',
  },
);


has pantry_host => (
  is => 'ro',
  isa => 'Str',
);


has pantry_port => (
  is => 'ro',
  isa => 'Int',
);



has pantry_user => (
  is => 'ro',
  isa => 'Str',
);


sub save {
  my ($self) = @_;
  die "No _path attribute set" unless $self->has_path;
  return $self->save_as( $self->path );
}

my @top_level_keys = qw/name run_list pantry_host pantry_port pantry_user chef_environment/;

sub _freeze {
  my ($self, $data) = @_;
  $data->{chef_environment} = delete $data->{env};
  my $attr = delete $data->{attributes};
  for my $k ( keys %$attr ) {
    next if grep { $k eq $_ } @top_level_keys;
    dot_to_hash($data, $k, $attr->{$k});
  }
  return $data;
}

sub _thaw {
  my ($self, $data) = @_;
  my $attr = {};
  for my $k ( keys %$data ) {
    next if grep { $k eq $_ } @top_level_keys;
    my $v = delete $data->{$k};
    $k =~ s{\.}{\\.}g; # escape existing dots in key
    for my $pair ( hash_to_dot($k, $v) ) {
      my ($key, $value) = @$pair;
      $attr->{$key} = $value;
    }
  }
  $data->{attributes} = $attr;
  $data->{env} = delete( $data->{chef_environment} ) || "_default";
  return $data;
}

1;

__END__

=pod

=head1 NAME

Pantry::Model::Node - Pantry data model for nodes

=head1 VERSION

version 0.012

=head1 SYNOPSIS

  my $pantry = Pantry::Model::Pantry->new;
  my $node = $pantry->node("foo.example.com");

  $node->append_to_run_list('recipe[nginx]');
  $node->set_attribute('nginx.port' => 80);
  $node->save;

=head1 DESCRIPTION

Models the configuration data for a specific server.

=head1 ATTRIBUTES

=head2 name

This attribute is the canonical name of the node, generally a fully-qualified domain name

=head2 name

This attribute is the name of the environment to which the node belongs.  This defaults
to C<_default>.

=head2 run_list

This attribute is provided by the L<Pantry::Role::Runlist> role and holds a list
of recipes (or roles) to be configured by C<chef-solo>.

=head2 attributes

This attribute holds node attribute data as key-value pairs.  Keys may
be separated by a period to indicate nesting (literal periods must be
escaped by a backslash).  Values should be scalars or array references,
except for boolean values which should be set as L<JSON::Boolean>
values like C<JSON::true> and C<JSON::false>.

=head2 pantry_host

This optional attribute holds an alternate hostname or IP address to use for
the SSH connection within C<pantry sync>.  In all other respects, the node will
still be referenced by the C<name> attribute.

=head2 pantry_port

This optional attribute holds an alternate port number to use for the SSH
connection within C<pantry sync>.

=head2 pantry_user

This optional attribute holds an alternate user for the SSH
connection within C<pantry sync>.  (The default is C<root>.)
This user B<must> have password-less sudo permissions.

=head1 METHODS

=head2 set_attribute

  $node->set_attribute("nginx.port", 80);

Sets the node attribute for the given key to the given value.

=head2 get_attribute

  my $port = $node->get_attribute("nginx.port");

Returns the node attribute for the given key.

=head2 delete_attribute

  $node->delete_attribute("nginx.port");

Deletes the node attribute for the given key.

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
