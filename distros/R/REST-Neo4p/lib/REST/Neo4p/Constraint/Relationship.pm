#$Id$
package REST::Neo4p::Constraint::Relationship;
use base 'REST::Neo4p::Constraint';
use strict;
use warnings;

BEGIN {
  $REST::Neo4p::Constraint::Relationship::VERSION = '0.3030';
}

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->{_type} = 'relationship';
  return $self;

}

sub new_from_constraint_hash {
  my $self = shift;
  my ($constraints) = @_;
  die "tag not defined" unless $self->tag;
  die "constraint hash not defined or not a hashref" unless defined $constraints && (ref $constraints eq 'HASH');
  if (my $cond = $constraints->{_condition}) {
    unless (grep(/^$cond$/,qw( only none ))) {
      die "Relationship constraint condition must be only|none";
    }
  }
  $constraints->{_condition} ||= 'only'; 
  $constraints->{_priority} ||= 0;
  unless (ref $constraints->{_descriptors} eq 'ARRAY') {
    die "relationship constraint descriptors must be array of hashrefs";
  }
  foreach (@{$constraints->{_descriptors}}) {
    unless (ref eq 'HASH') {
      die "relationship constraint descriptor must by a hashref";
    }
  }
  $self->{_constraints} = $constraints;
  return $self;
}

sub rtype { shift->constraints->{_relationship_type} }

sub add_constraint {
  my $self = shift;
  my ($value) = @_;
  return unless defined $value;
  unless (ref($value) eq 'HASH') {
    REST::Neo4p::LocalException->throw("Relationship descriptor must be a hashref { node_property_constraint_tag => node_property_constraint_tag }\n");
  }
  my $constraints = $self->constraints;
  $constraints->{_descriptors} ||= [];
  while ( my ($tag1, $tag2) = each %$value ) {
    unless ( grep(/^$tag1$/, keys %$REST::Neo4p::Constraint::CONSTRAINT_TABLE) ) {
      REST::Neo4p::LocalException->throw("Constraint '$tag1' is not defined\n");
    }
    unless ( grep(/^$tag2$/, keys %$REST::Neo4p::Constraint::CONSTRAINT_TABLE) ) {
      REST::Neo4p::LocalException->throw("Constraint '$tag2' is not defined\n");
    }
    push @{$constraints->{_descriptors}}, $value;
  }
  return 1;
}

sub remove_constraint {
  my $self = shift;
  my ($from, $to) = @_;
  my $ret;
  my $descr = $self->constraints->{_descriptors};
  for my $i (0..$#{$descr}) {
    my ($k, $v) = each %{$descr->[$i]};
    if ( ($k eq $from) && ( $v eq $to ) ) {
      $ret = delete $descr->[$i];
      last;
    }
  }
  return $ret;
}

sub set_condition {
  my $self = shift;
  my ($condition) = @_;
  unless ($condition =~ /^(only|none)$/) {
    REST::Neo4p::LocalException->throw("Relationship condition must be one of (only|none)\n");
  }
  return $self->{_constraints}{_condition} = $condition; 
}

sub validate {

  my $self = shift;
  my ($from, $to, $reln_type, $reln_props) = @_;
  my ($reln) = @_;
  return unless defined $from;
  if (ref($reln) =~ /Neo4p::Relationship$/) {
    $from = $reln->start_node->get_properties;
    $to = $reln->end_node->get_properties;
    $reln_type = $reln->type;
  }
  REST::Neo4p::LocalException->throw("Relationship type (arg3) must be provided to validate\n") unless defined $reln_type;
  REST::Neo4p::LocalException->throw("Relationship properties (arg4) must be a hashref of properties\n") unless (!$reln_props) || (ref $reln_props eq 'HASH');

  unless ((ref($from) =~ /Neo4p::Node|HASH$/) &&
	  (ref($to) =~ /Neo4p::Node|HASH$/)) {
    REST::Neo4p::LocalException->throw("validate() requires a pair of Node objects, a pair of hashrefs, or a single Relationship object\n");
  }
  # first check if relationship type is defined and
  # is represented in this constraint (or the constraint has 
  # wildcard type)
  return 0 unless (($self->rtype eq '*') || ($reln_type eq $self->rtype));
  # if rtype validation is strict, fail if type undefined or not found
  # if validation is lax, continue
  if ($REST::Neo4p::Constraint::STRICT_RELN_TYPES) {
    return 0 unless REST::Neo4p::Constraint::validate_relationship_type($reln_type);
  }

  return 1 if ( ($self->condition eq 'none') && !defined $self->constraints->{$reln_type} ); 

  my @descriptors = @{$self->constraints->{_descriptors}};
  $from = $from->get_properties if ref($from) =~ /Neo4p::Node$/;
  $to = $to->get_properties if ref($to) =~ /Neo4p::Node$/;
  # $to, $from now normalized to property hashrefs

  my $from_constraint = REST::Neo4p::Constraint::validate_properties($from);
  my $to_constraint = REST::Neo4p::Constraint::validate_properties($to);

  $from_constraint = $from_constraint && $from_constraint->tag;
  $to_constraint = $to_constraint && $to_constraint->tag;
  # $to_constraint, $from_constraint contain undef or the matching 
  # constraint tag

  # filter @descriptors based on $from_constraint tag
  $to_constraint ||= '*';
  $from_constraint ||= '*';
  @descriptors = grep { defined $_->{ $from_constraint } } @descriptors;

  if (@descriptors) {
    my $found = grep /^\Q$to_constraint\E$/, map {$_->{$from_constraint}} @descriptors;
    return 0 if (($self->condition eq 'only') && !$found);
    return 0 if (($self->condition eq 'none') && $found);
  }
  else {
    return 0 if ($self->condition eq 'only');
  }


  # TODO: validate relationship properties here
  if ($REST::Neo4p::Constraint::STRICT_RELN_PROPS) {
    $reln_props ||= {};
    $reln_props->{__type} = 'relationship';
    $reln_props->{_relationship_type} = $reln_type;
    return 0 unless REST::Neo4p::Constraint::validate_properties($reln_props);
  }

  return 1;
}

=head1 NAME

REST::Neo4p::Constraint::Relationship - Neo4j Relationship Constraints

=head1 SYNOPSIS

 # use REST::Neo4p::Constrain, it's nicer

 $rc = REST::Neo4p::Constraint::Relationship->new(
   'allowed_contains_relns' => 
     { _condition => 'only',
       _relationship_type => 'contains',
       _priority => 0,
       _descriptors  => [ {'module' => 'method'},
                          {'module' => 'variable'},
                          {'method' => 'variable'} ] }
   );

=head1 DESCRIPTION

C<REST::Neo4p::Constraint::Relationship> is a class that represents
constraints on the type and direction of relationships between nodes
that satisfy given sets of property constraints.

Constraint hash specification:

   { 
     _condition => <'only'|'none'>,
     _relationship_type => <relationship_typename>,
     _priority => <integer priority>,
     _descriptors => [{ property_constraint_tag => 
                        property_constraint_tag },...] }
   }

=head1 METHODS

=over

=item new()

 $rc = $REST::Neo4p::Constraint::Relationship->new(
        $tag => $constraint_hash
      );

=item add_constraint()

 $rc->add_constraint( { 'star' => 'planet' });

=item remove_constraint()

 $rc->remove_constraint( { 'developer' => 'parole_officer' } );

=item tag()

Returns the constraint tag.

=item type()

Returns the constraint type ('relationship').

=item rtype()

The relationship type to which this constraint applies.

=item constraints()

Returns the internal constraint spec hashref.

=item priority()

=item set_priority()

Constraints with higher priority will be checked before constraints
with lower priority by
L<C<validate_relationship()>|REST::Neo4p::Constraint/Functional
interface for validation>.

=item condition()

=item set_condition()

 $r->set_condition('only');

Get/set 'only' or 'none' for a given relationship constraint. See
L<REST::Neo4p::Constrain>.

=item validate()

 $c->validate( $relationship_object );
 $c->validate( $node_object1 => $node_object2, 
                         $reln_type );
 $c->validate( { name => 'Steve', instrument => 'banjo' } =>
               { name => 'Marcia', instrument => 'blunt' },
                 'avoids' );

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
