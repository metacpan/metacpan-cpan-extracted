#$Id$
package REST::Neo4p::Constraint::RelationshipType;
use base 'REST::Neo4p::Constraint';
use strict;
use warnings;

BEGIN {
  $REST::Neo4p::Constraint::RelationshipType::VERSION = '0.3030';
}

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->{_type} = 'relationship_type';
  return $self;
}

sub new_from_constraint_hash {
  my $self = shift;
  my ($constraints) = @_;
  die "tag not defined" unless $self->tag;
  die "constraint hash not defined or not a hashref" unless defined $constraints && (ref $constraints eq 'HASH');
  if (my $cond = $constraints->{_condition}) {
    unless (grep(/^$cond$/,qw( only none ))) {
      die "Relationship type constraint condition must be one of (only|none)";
    }
  }
  else {
    $constraints->{_condition} = 'only'; # default
  }
  $constraints->{_priority} ||= 0;
  unless ( defined $constraints->{_type_list} &&
	   ref $constraints->{_type_list} eq 'ARRAY' ) {
    die "Relationship type constraint must contain an arrayref of types"
  }

  $self->{_constraints} = $constraints;
  return $self;
}

sub add_constraint {
  my $self = shift;
  my ($key, $value) = @_;
  return $self->add_types(@_);
}

sub add_types {
  my $self = shift;
  my @types = @_;
  $self->constraints->{_type_list} ||= [];
  for (@types) {
    if (ref) {
      REST::Neo4p::LocalException->throw("Relationship types must be strings\n");
    }
    push @{$self->constraints->{_type_list}}, $_;
  }
  return 1;
}

sub type_list {
  my $self = shift;
  my $constraints = $self->constraints;
  return @{$constraints->{_type_list}} if (defined $constraints->{_type_list});
  return;
}

sub remove_constraint { shift->remove_type(@_) }

sub remove_type {
  my $self = shift;
  my ($tag) = @_;
  my $ret;
  return unless $self->type_list;
  my $constraints = $self->constraints;
  for my $i (0..$#{$constraints->{_type_list}}) {
    if ($tag eq $constraints->{_type_list}->{$i}) {
      $ret = delete $constraints->{_type_list}->{$i};
      last;
    }
  }
  return $ret;
}

sub set_condition {
  my $self = shift;
  my ($condition) = @_;
  unless ($condition =~ /^(only|none)$/) {
    REST::Neo4p::LocalException->throw("Relationship type condition must be one of (only|none)\n");
  }
  return $self->{_constraints}{_condition} = $condition;
}

sub validate {
  my $self = shift;
  my ($type) = (@_);
  return unless defined $type;
  $type = $type->type if (ref($type) =~ /Neo4p::Relationship$/);
  return grep(/^$type$/,$self->type_list) ? 1 : 0;
}

=head1 NAME

REST::Neo4p::Constraint::RelationshipType - Neo4j Relationship Type Constraints

=head1 SYNOPSIS

 # use REST::Neo4p::Constrain, it's nicer

 $rtc = REST::Neo4p::Constraint::RelationshipType->new(
  'allowed_reln_types' =>
    { _condition => 'only', 
      _type_list => [qw(contains has)] }
  );

=head1 DESCRIPTION

C<REST::Neo4p::Constraint::RelationshipType> is a class that represent
the set of relationship types that Relationships must (or must not)
use.

Constraint hash specification:

 { 
   _condition => <'only'|'none'>,
   _priority => <integer priority>,
   _type_list => [ 'type_name_1', 'type_name_2', ...]  }
 }

=head1 METHODS

=over

=item new()

 $rt = REST::Neo4p::Constraint::RelationshipType->new(
         $tag => $constraint_hash
       );

=item add_constraint()

=item add_types()

 $rc->add_constraint('new_type');
 $rc->add_type('new_type');

=item remove_constraint()

=item remove_type()

 $rc->remove_constraint('old_type');
 $rc->remove_type('old_type');

=item tag()

Returns the constraint tag.

=item type()

Returns the constraint type ('relationship_type').

=item condition()

=item set_condition()

Get/set 'only' or 'none' for a given relationship constraint. See
L<REST::Neo4p::Constrain>.

=item priority()

=item set_priority()

Constraints with higher priority will be checked before constraints
with lower priority by
L<C<validate_relationship_type()>|REST::Neo4p::Constraint/Functional
interface for validation>.

=item constraints()

Returns the internal constraint spec hashref.

=item validate()

 $c->validate( 'avoids' );

Returns true if the item meets the constraint, false if not.

=back

=head1 SEE ALSO

L<REST::Neo4p>, L<REST::Neo4p::Node>, L<REST::Neo4p::Relationship>,
L<REST::Neo4p::Constraint>, L<REST::Neo4p::Constraint::Relationship>,
L<REST::Neo4p::Constraint::RelationshipType>.

=head1 AUTHOR

    Mark A. Jensen
    CPAN ID: MAJENSEN
    majensen -at- cpan -dot- org

=head1 LICENSE

Copyright (c) 2012-2017 Mark A. Jensen. This program is free software; you
can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

1;
