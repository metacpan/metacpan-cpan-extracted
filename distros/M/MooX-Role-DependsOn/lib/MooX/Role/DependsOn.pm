package MooX::Role::DependsOn;
$MooX::Role::DependsOn::VERSION = '1.001001';
use strictures 2;
no warnings 'recursion';

use Carp;
use Scalar::Util 'blessed', 'reftype';

use List::Objects::WithUtils;
use List::Objects::Types -all;

use Types::Standard -types;


use Moo::Role;

has dependency_tag => (
  is      => 'rw',
  default => sub { my ($self) = @_; "$self" },
);

has __depends_on => (
  init_arg => 'depends_on',
  lazy    => 1,
  is      => 'ro',
  isa     => TypedArray[ ConsumerOf['MooX::Role::DependsOn'] ],
  coerce  => 1,
  default => sub { array_of ConsumerOf['MooX::Role::DependsOn'] },
  handles => +{
    clear_dependencies => 'clear',
    has_dependencies   => 'has_any',
  },
);

sub depends_on {
  my ($self, @nodes) = @_;
  return @{ $self->__depends_on } unless @nodes;
  $self->__depends_on->push(@nodes)
}

sub __resolve_deps {
  my ($self, $params) = @_;

  my $node       = $params->{node};
  my $resolved   = $params->{resolved};
  my $skip       = $params->{skip}       ||= +{};
  my $unresolved = $params->{unresolved} ||= +{};

  my $item = $node->dependency_tag;

  $unresolved->{$item} = 1;

  DEP: for my $edge ($node->depends_on) {
    my $depitem = $edge->dependency_tag;
    next DEP if exists $skip->{$depitem};
    if (exists $unresolved->{$depitem}) {
      if (my $cb = $params->{circular_dep_callback}) {
        # Pass full state for scary munging:
        my $state = hash(
          node            => $node,
          edge            => $edge,
          resolved_array  => $resolved,
          unresolved_hash => $unresolved,
          skip_hash       => $skip
        )->inflate;
        next DEP if $self->$cb( $state )
      }
      die "Circular dependency detected: $item -> $depitem\n"
    }
    __resolve_deps( $self,
      +{ 
        node => $edge, 
        skip => $skip, 
        
        resolved   => $resolved,
        unresolved => $unresolved,

        resolved_callback     => $params->{resolved_callback},
        circular_dep_callback => $params->{circular_dep_callback},
      }
    )
  }

  push @$resolved, $node;
  $skip->{$item} = delete $unresolved->{$item};

  if (my $cb = $params->{resolved_callback}) {
    my $state = hash(
      node            => $node,
      resolved_array  => $resolved,
      unresolved_hash => $unresolved,
      skip_hash       => $skip
    )->inflate;
    $self->$cb( $state );
  }

  ()
}

sub dependency_schedule {
  my ($self, %params) = @_;

  confess 
    "'callback' is deprecated, see the documentation for 'resolved_callback'"
   if $params{callback};

  my $cb;
  if ($cb = $params{resolved_callback}) {
    confess "Expected 'resolved_callback' param to be a coderef"
      unless ref $cb and reftype $cb eq 'CODE';
  }

  my $circ_cb;
  if ($circ_cb = $params{circular_dep_callback}) {
    confess "Expected 'circular_dep_callback' param to be a coderef"
      unless ref $circ_cb and reftype $circ_cb eq 'CODE';
  }

  my $resolved = [];
  $self->__resolve_deps(
    +{
      node     => $self,
      resolved => $resolved,
      ( defined $cb ? (resolved_callback => $cb) : () ),
      ( defined $circ_cb ? (circular_dep_callback => $circ_cb) : () ),
    },
  );

  @$resolved
}


1;

=pod

=head1 NAME

MooX::Role::DependsOn - Add a dependency tree to your cows

=head1 SYNOPSIS

  package Task;
  use Moo;
  with 'MooX::Role::DependsOn';

  sub execute {
    my ($self) = @_;
    # ... do stuff ...
  }

  package main;
  # Create some objects that consume MooX::Role::DependsOn:
  my $job = {};
  for my $jobname (qw/ A B C D E /) {
    $job->{$jobname} = Task->new
  }

  # Add some dependencies:
  # A depends on B, D:
  $job->{A}->depends_on( $job->{B}, $job->{D} );
  # B depends on C, E:
  $job->{B}->depends_on( $job->{C}, $job->{E} );
  # C depends on D, E:
  $job->{C}->depends_on( $job->{D}, $job->{E} );

  # Resolve dependencies (recursively) for an object:
  my @ordered = $job->{A}->dependency_schedule;
  # Scheduled as ( D, E, C, B, A ):
  for my $obj (@ordered) {
    $obj->execute;
  }

=head1 DESCRIPTION

A L<Moo::Role> that adds a dependency graph builder to your class; objects
with this role applied can (recursively) depend on other objects (that also
consume this role) to produce an ordered list of dependencies.

This is useful for applications such as job ordering (see the SYNOPSIS) and resolving
software dependencies.

=head2 Attributes

=head3 dependency_tag

An object's B<dependency_tag> is used to perform the actual resolution; the
tag should be a stringifiable value that is unique within the tree.

Defaults to the stringified value of C<$self>.

=head2 Methods

=head3 depends_on

If passed no arguments, returns the current direct dependencies of the object
as an unordered list.

If passed objects that are L<MooX::Role::DependsOn> consumers (or used as an
attribute with an ARRAY-type value during object construction), the objects
are pushed to the current dependency list.

=head3 clear_dependencies

Clears the current dependency list for this object.

=head3 has_dependencies

Returns boolean true if the object has dependencies.

=head3 dependency_schedule

This method recursively resolves dependencies and returns an ordered
'schedule' (as a list of objects). See the L</SYNOPSIS> for an example.

=head4 Resolution callbacks

A callback can be passed in; for each successful resolution, the callback will
be invoked against the root object we started with:

  my @ordered = $startnode->dependency_schedule(
    resolved_callback => sub {
      my (undef, $state) = @_;
      # ...
    },
  );

The C<$state> object passed in is a simple struct-like object providing access
to the current resolution state. This consists primarily of a set of lists
(represented as hashes for performance reasons).

(These are references to the actual in-use state; it's possible to do scary
things to the tree from here -- in which case it is presumed that you have read
and understand the source code.)

The object provides the following accessors:

=over

=item node

The node we are currently processing.

=item resolved_array

The ordered list of successfully resolved nodes, as an ARRAY of the original
objects; this is the ARRAY used to produce the final list produced by
L</dependency_schedule>.

=item unresolved_hash

The list of 'seen but not yet resolved' nodes, as a HASH keyed on
L</dependency_tag>.

=item skip_hash

The list of nodes to skip (because they have already been seen), as a HASH
keyed on L</dependency_tag>.

=back

=head4 Circular dependency callbacks

An exception is thrown if circular dependencies are detected; it's possible to
override that behavior by providing a B<circular_dep_callback> that is invoked
against the root object:

  my @ordered = $startnode->dependency_schedule(
    circular_dep_callback => sub {
      my (undef, $state) = @_;
      # ...
    },
  );

If the callback returns true, resolution continues at the next node; otherwise
an exception is thrown after callback execution.

The C<$state> object has the same accessors as resolution callbacks (described
above), plus the following:

=over

=item edge

The dependency node we are attempting to examine.

=back

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Licensed under the same terms as Perl.

=cut

# vim: ts=2 sw=2 et sts=2 ft=perl
