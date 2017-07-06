#$Id$
package REST::Neo4p::Constraint::Property;
use base 'REST::Neo4p::Constraint';
use strict;
use warnings;

BEGIN {
  $REST::Neo4p::Constraint::Property::VERSION = '0.3020';
}

sub new_from_constraint_hash {
  my $self = shift;
  my ($constraints) = @_;
  die "tag not defined" unless $self->tag;
  die "constraint hash not defined or not a hashref" unless defined $constraints && (ref $constraints eq 'HASH');
  if (my $cond = $constraints->{_condition}) {
    unless (grep(/^$cond$/,qw( all only none ))) {
      die "Property constraint condition must be all|only|none";
    }
  }
  else {
    $constraints->{_condition} = 'only'; 
  }
  $constraints->{_priority} ||= 0;
  $self->{_constraints} = $constraints;
  return $self;
};
  
sub add_constraint {
  my $self = shift;
  my ($key, $value) = @_;
  unless (!ref($key) && ($key=~/^[a-z0-9_]+$/i)) {
    REST::Neo4p::LocalException->throw("Property name (arg 1) contains disallowed characters in add_constraint\n");
  }
  unless (!ref($value) || ref($value) eq 'ARRAY') {
    REST::Neo4p::LocalException->throw("Constraint value for '$key' must be string, regex, or arrayref of strings and regexes\n");
  }
  $self->constraints->{$key} = $value;
  return 1;
}

sub remove_constraint {
  my $self = shift;
  my ($tag) = @_;
  delete $self->constraints->{$tag};
}

sub set_condition {
  my $self = shift;
  my ($condition) = @_;
  unless ($condition =~ /^(all|only|none)$/) {
    REST::Neo4p::LocalException->throw("Property constraint condition must be all|only|none\n");
  }
  return $self->{_constraints}{_condition} = $condition;
}

# validate the input property hash or Entity with respect to the 
# constraint represented by this object

sub validate {
  my $self = shift;
  my ($prop_hash) = @_;
  if (ref($prop_hash) eq 'REST::Neo4p::Node') {
    $prop_hash = $prop_hash->get_properties();
  }
  if (ref($prop_hash) eq 'REST::Neo4p::Relationship') {
    my $ph = $prop_hash->get_properties();
    $ph->{_relationship_type} = $prop_hash->type; # psuedo property that must match exactly
    $prop_hash = $ph;
  }
  # otherwise, $prop_hash is hashref as validated in the calling subclass
  my $is_valid = 1;
  my $condition = $self->condition;
 FORWARDCHECK:
  while (my ($prop,$val) = each %$prop_hash ) {
    next if ($prop =~ /^_(condition|priority)$/);
    my $value_spec = $self->constraints->{$prop};
    if (defined $value_spec) {
      unless (_validate_value($prop,$val,$value_spec,$condition)) {
	$is_valid = 0;
	last FORWARDCHECK;
      }
    }
    else {
      if ($condition eq 'only') {
	$is_valid = 0;
	last FORWARDCHECK;
      }
    }
  }
  keys %$prop_hash;
 BACKWARDCHECK:
  while ( $is_valid && (my ($prop, $value_spec) = each %{$self->constraints}) ) {
    next if ($prop =~ /^_(condition|priority)$/); ##
    my $val = $prop_hash->{$prop};
    unless (_validate_value($prop,$val,$value_spec,$condition)) {
      $is_valid = 0;
      last BACKWARDCHECK;
      }
  }
  keys %{$self->constraints};
  return $is_valid;
}

sub _validate_value {
  my ($prop,$value,$value_spec,$condition) = @_;

  die "arg1(prop), arg3(value_spec), and arg4(condition) must all be defined" unless defined $prop && defined $value_spec && defined $condition;
  my $is_valid = 1;
  for ($value_spec) {
    ref eq 'ARRAY' && do {
      if (!@$value_spec) { #empty array
	1; # don't care
      }
      else {
	die "single value in arrayref must be scalar" unless ref($value_spec->[0]) =~ /^|Regexp$/;
	die "single value in arrayref cannot be empty string" unless length $value_spec->[0];
	if (defined $value) {
	  $is_valid = _validate_value($prop,$value,$value_spec->[0],$condition);
	} # otherwise don't care
      }
      last;
    };
    ref eq 'Regexp' && do {
      if ($condition =~ /all|only/) {
	if (!defined $value) {
	  $is_valid = 0;
	}
	else {
	  $is_valid = 0 unless ($value =~ /$value_spec/);
	}
      }
      else { # $condition eq 'none'
	if (defined $value) {
	  $is_valid = 0 unless ($value !~ /$value_spec/);
	}
      }
      last;
    };
    (ref eq '') && do { # simple string
      if (length) {
	if ($condition =~ /all|only/) {
	  if (!defined $value) {
	    $is_valid = 0;
	  }
	  else {
	    $is_valid = 0 unless (($value eq $value_spec) ||
				    $value_spec eq '*');
	  }
	}
	elsif ($condition eq 'none') {
	  if (defined $value) {
	    $is_valid = 0 unless ($value ne $value_spec);
	  }
	}
	else { #fallthru
	  die "I shouldn't be here in _validate_value";
	}
      }
      else { # empty string means this property is required to be present
	if ($condition =~ /all|only/) {
	  if (!defined $value) {
	    $is_valid = 0;
	  }
	}
	elsif ($condition eq 'none') {
	  if (defined $value) {
	    $is_valid = 0
	  }
	}
	else { #fallthru
	  die "I shouldn't be here in _validate_value";
	}
      }
      last;
    };
    # fallthru
    do {
      REST::Neo4p::LocalException->throw("Invalid constraint value spec for property '$prop'\n");
    };
  }
  return $is_valid;
}

1;

package REST::Neo4p::Constraint::NodeProperty;
use base 'REST::Neo4p::Constraint::Property';
use strict;
use warnings;
BEGIN {
  $REST::Neo4p::Constraint::NodeProperty::VERSION='0.3020';
}

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->{_type} = 'node_property';
  return $self;
}

sub validate {
  my $self = shift;
  my ($item) = (@_);
  return unless defined $item;
  unless ( ref($item) =~ /Node|HASH$/ ) {
    REST::Neo4p::LocalException->throw("validate() requires a single hashref or Node object\n");
  }
  $self->SUPER::validate(@_);
}
1;

package REST::Neo4p::Constraint::RelationshipProperty;
use base 'REST::Neo4p::Constraint::Property';
use strict;
use warnings;

BEGIN {
  $REST::Neo4p::Constraint::RelationshipProperty::VERSION='0.3020';
}
# relationship_type is added as a pseudoproperty

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->{_type} = 'relationship_property';
  return $self;
}

sub new_from_constraint_hash {
  my $self = shift;
  $self->SUPER::new_from_constraint_hash(@_);
  $self->constraints->{_relationship_type} ||= [];
  return $self;
}

sub rtype { shift->constraints->{_relationship_type} }
sub validate {
  my $self = shift;
  my ($item) = (@_);
  return unless defined $item;
  unless ( ref($item) =~ /Neo4p::Relationship|HASH$/ ) {
    REST::Neo4p::LocalException->throw("validate() requires a single hashref or Relationship object\n");
  }
  $self->SUPER::validate(@_);
}

1;

=head1 NAME

REST::Neo4p::Constraint::Property - Neo4j Property Constraints

=head1 SYNOPSIS

 # use REST::Neo4p::Constrain, it's nicer

 $npc = REST::Neo4p::Constraint::NodeProperty->new(
   'soldier' => { _condition => 'all',
                  _priority => 1,
                  name => '',
                  rank => [],
                  serial_number => qr/^[0-9]+$/,
                  army_of => 'one' }
  );

 $rpc = REST::Neo4p::Constraint::RelationshipProperty->new(
  'position' => { _condition => 'only',
                  position => qr/[0-9]+/ }
  );

=head1 DESCRIPTION

C<REST::Neo4p::Constraint::NodeProperty> and
C<REST::Neo4p::Constraint::RelationshipProperty> are classes that
represent constraints on the presence and values of Node and
Relationship entities.

Constraint hash specification:

   { 
     _condition => constraint_conditions, # ('all'|'only'|'none')
     _relationship_type => <relationship type>,
     _priority => <integer priority>,
     prop_0 => [], # may have, no constraint
     prop_1 => [<string|regexp>], # may have, if present must meet 
     prop_2 => '', # must have, no constraint
     prop_3 => 'value', # must have, value must eq 'value'
     prop_4 => qr/.alue/, # must have, value must match qr/.alue/,
     prop_5 => qr/^value1|value2|value3$/ # regexp for enumerations
  }

=head1 METHODS

=over

=item new()

 $np = REST::Neo4p::Constraint::NodeProperty->new(
         $tag => $constraint_hash
       );

 $rp = REST::Neo4p::Constraint::RelationshipProperty->new(
         $tag => $constraint_hash
       );

=item add_constraint()

 $np->add_constraint( optional_accessory => [qw(tie ascot boutonniere)] );

=item remove_constraint()

 $np->remove_constraint( 'unneeded_property' );

=item tag()

Returns the constraint tag.

=item type()

Returns the constraint type ('node_property' or 'relationship_property').

=item condition()

=item set_condition()

Set/get 'all', 'only', 'none' for a given property constraint. See
L<REST::Neo4p::Constrain>.

=item priority()

=item set_priority()

Constraints with higher priority will be checked before constraints
with lower priority by
L<C<validate_properties()>|REST::Neo4p::Constraint/Functional
interface for validation>.

=item constraints()

Returns the internal constraint spec hashref.

=item validate()

 $c->validate( $node_object )
 $c->validate( $relationship_object )
 $c->validate( { name => 'Steve', instrument => 'banjo } );

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
