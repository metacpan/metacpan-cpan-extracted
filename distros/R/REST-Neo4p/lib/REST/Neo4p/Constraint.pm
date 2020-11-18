#$Id$
package REST::Neo4p::Constraint;
use base 'Exporter';
use REST::Neo4p;
use REST::Neo4p::Exceptions;
use JSON;
use Data::Dumper;

use Scalar::Util qw(looks_like_number);
use strict;
use warnings;

our @EXPORT = qw(serialize_constraints load_constraints);
our @VALIDATE = qw(validate_properties validate_relationship validate_relationship_type);
our @EXPORT_OK = (@VALIDATE);
our %EXPORT_TAGS = (
  validate => \@VALIDATE,
  auto => [@EXPORT],
  all => [@EXPORT,@EXPORT_OK]
);

our $jobj = JSON->new->utf8;
$jobj->allow_blessed(1);
$jobj->convert_blessed(1);
my $regex_to_json = sub {
  my $qr = shift;
  local $Data::Dumper::Terse=1;
  $qr = Dumper $qr;
  chomp $qr;
  return $qr;
};

BEGIN {
  $REST::Neo4p::Constraint::VERSION = '0.4000';
}

# valid constraint types
our @CONSTRAINT_TYPES = qw( node_property relationship_property
			   relationship_type relationship );
our $CONSTRAINT_TABLE = {};


# flag - when set, disallow relationships that are not allowed by current 
# relationship types
# default strict
$REST::Neo4p::Constraint::STRICT_RELN_TYPES = 1;

# flag - when set, require strict checking of relationship properties when
# validating relationships -- i.e., a relationship with no properties is
# disallowed unless there is a specific relationship_property constraint
# allow this
# default relaxed

$REST::Neo4p::Constraint::STRICT_RELN_PROPS = 0;

# flag - when set, use the database to store constraints
$REST::Neo4p::Constraint::USE_NEO4J = 0;


sub new {
  my $class = shift;
  my ($tag, $constraints) = @_;
  my $self = bless {}, $class;
  unless (defined $tag) {
    REST::Neo4p::LocalException->throw("New constraint requires tag as arg 1\n");
  }
  unless ($tag =~ /^[a-z0-9_.]+$/i) {
    REST::Neo4p::LocalException->throw("Constraint tag may contain only alphanumerics chars, underscore and period\n");
  }
  if ( !grep /^$tag$/,keys %$CONSTRAINT_TABLE ) {
    $self->{_tag} = $tag;
  }
  else {
    REST::Neo4p::LocalException->throw("Constraint with tag '$tag' is already defined\n");
  }
  $self->new_from_constraint_hash($constraints);
  $CONSTRAINT_TABLE->{$tag} = $self;
}

sub new_from_constraint_hash {
  REST::Neo4p::AbstractMethodException->throw("new_from_constraint_hash() is an abstract method of ".__PACKAGE__."\n");
}

sub TO_JSON {
  no warnings qw(redefine);
  my $self = shift;
  my $store; 
  my $old = *Regexp::TO_JSON{CODE};
  *Regexp::TO_JSON = $regex_to_json;
  $store = $self->constraints;
  $store->{_condition} = $self->condition;
  $store->{_priority} = $self->priority;
  $store->{_relationship_type} = $self->rtype if $self->can('rtype');
  my $ret  = $jobj->encode({tag => $self->tag, type => $self->type,
		 _constraint_hash => $store });
  *Regexp::TO_JSON = $old if $old;
  return $ret;
}

sub new_from_json {
  my $class = shift;
  my ($json) = @_;
  unless (ref($json)) {
    $json = decode_json($json);
  }
  unless ( $json->{tag} && $json->{type} ) {
    REST::Neo4p::LocalException->throw("json does not correctly specify a constraint object\n");
  }
  my $subclass = $json->{type};
  _fix_constraints($json->{_constraint_hash});
  $subclass =~ s/^(.)/\U$1\E/;
  $subclass =~ s/_(.)/\U$1\E/;
  $subclass = 'REST::Neo4p::Constraint::'.$subclass;
  $subclass->new($json->{tag}, $json->{_constraint_hash});
}

sub _fix_constraints {
  # make qr// strings into Regexp objects
  local $_ = shift;
  if (ref eq 'HASH') {
    while (my ($k, $v) = each %$_) {
      if ($v && ($v =~ /^qr\//)) {
	 if ($v =~ /\(\?(\^|-[a-z]+):.*\)/) {
	   $v =~ s{/\(\?(\^|-[a-z]+):}{/}; # kludge - eval wants to wrap (?:^...) around a qr string
	   $v =~ s{\)/}{/}; # kludge -      even if one is there already
	 }
	$_->{$k} = eval $v; # replace with Regexp
      }
      else {
	_fix_constraints($v);
      }
    }
  }
  elsif (ref eq 'ARRAY') {
    foreach my $v (@$_) {
      _fix_constraints($v);
    }
  }
}

sub tag { shift->{_tag} }
sub type { shift->{_type} }
sub condition { shift->{_constraints}{_condition} } ##
sub priority { shift->{_constraints}{_priority} } ##
sub constraints { shift->{_constraints} }

sub set_priority {
  my $self = shift;
  my ($priority_value) = @_;
  unless (looks_like_number($priority_value)) {
    REST::Neo4p::LocalException->throw("Priority value must be numeric\n");
  }
  return $self->{_constraints}{_priority} = $priority_value;
}

sub get_constraint {
  my $class = shift;
  if (ref $class) {
    REST::Neo4p::ClassOnlyException->throw("get_constraint is a class method only\n");
  }
  my ($tag) = @_;
  return $CONSTRAINT_TABLE->{$tag};
}

sub get_all_constraints {
  my $class = shift;
  if (ref $class) {
    REST::Neo4p::ClassOnlyException->throw("get_constraint is a class method only\n");
  }
  return %{$CONSTRAINT_TABLE};
}

sub drop {
  my $self = shift;
  delete $CONSTRAINT_TABLE->{$self->tag};
}

sub drop_constraint {
  my $class = shift;
  if (ref $class) {
    REST::Neo4p::ClassOnlyException->throw("get_constraint is a class method only\n");
  }
  my ($tag) = @_;
  delete $CONSTRAINT_TABLE->{$tag};
}

sub add_constraint {
  REST::Neo4p::AbstractMethodException->throw("Cannot call add_constraint() from the Constraint parent class\n");
}

sub remove_constraint {
  REST::Neo4p::AbstractMethodException->throw("Cannot call remove_constraint() from the Constraint parent class\n");
}

sub set_condition {
  REST::Neo4p::AbstractMethodException->throw("Cannot call set_condition() from the Constraint parent class\n");
}

# return the first property constraint according to priority
# that the property hash arg satisfies, or false if no match

sub validate_properties {
#  my $class = shift;
  # Exported
  my ($properties) = @_;
  return unless defined $properties;
  # if (ref $class) {
  #   REST::Neo4p::ClassOnlyException->throw("validate_properties() is a class-only method\n");
  # }

  unless ( (ref($properties) =~ /Neo4p::(Node|Relationship)$/) ||
	     (ref($properties) eq 'HASH') ) {
    REST::Neo4p::LocalException->throw("Arg to validate_properties() must be a hashref, a Node object, or a Relationship object");
  }
  my $type = (ref($properties) =~ /Neo4p/) ? $properties->entity_type : 
    (delete $properties->{__type} || '');
  my @prop_constraints = grep { $_->type =~ /${type}_property$/ } values %$CONSTRAINT_TABLE;
  @prop_constraints = sort {$b->priority <=> $a->priority} @prop_constraints;
  my $ret;
  foreach (@prop_constraints) {
    if ($_->validate($properties)) {
      $ret = $_;
      last;
    }
  }
  return $ret;
}

sub validate_relationship {
#  my $class = shift;
  # Exported
  my ($from, $to, $reln_type, $reln_props) = @_;
  my ($reln) = @_;
  # if (ref $class) {
  #   REST::Neo4p::ClassOnlyException->throw("validate_relationship() is a class-only method\n");
  # }
  return unless defined $from;
  unless ( (ref($reln) =~ /Neo4p::Relationship$/) || 
	   ( (ref($from) =~ /Neo4p::Node|HASH$/) && (ref($to) =~ /Neo4p::Node|HASH$/) &&
	       defined $reln_type ) ) {
    REST::Neo4p::LocalException->throw("validate_relationship() requires a Relationship object, or two property hashrefs or nodes followed by a relationship type\n");
  }
  my @reln_constraints = grep {$_->type eq 'relationship'} values %$CONSTRAINT_TABLE;
  @reln_constraints = sort {$a->priority <=> $b->priority} @reln_constraints;
  my $ret;
  foreach (@reln_constraints) {
    if ($_->validate($from => $to, $reln_type, $reln_props)) {
      $ret = $_;
      last;
    }
  }
  return $ret;
}

sub validate_relationship_type {
#  my $class = shift;
  # Exported
  my ($reln_type) = @_;
  # if (ref $class) {
  #   REST::Neo4p::ClassOnlyException->throw("validate_relationhip_type() is a class-only method\n");
  # }
  return unless defined $reln_type;
  my @type_constraints = grep {$_->type eq 'relationship_type'} values %$CONSTRAINT_TABLE;
  @type_constraints = sort {$a->priority <=> $b->priority} @type_constraints;
  my $ret;
  foreach (@type_constraints) {
    if ($_->validate($reln_type)) {
      $ret = $_;
      last;
    }
  }
  return $ret;
}

sub serialize_constraints {
  my $json = sprintf "%s", join(", ", map { $jobj->encode($_) } values %$CONSTRAINT_TABLE);
  return "[$json]";
}

sub load_constraints {
  my ($json) = @_;
  eval {
    $json = decode_json($json);
  };
  if (my $e = Exception::Class->caught()) {
    REST::Neo4p::LocalException->throw("JSON error: $e");
  }
  for (@$json) {
    REST::Neo4p::Constraint->new_from_json($_);
  }
  return 1;
}

=head1 NAME

REST::Neo4p::Constraint - Application-level Neo4j Constraints

=head1 SYNOPSIS

See L<REST::Neo4p::Constraint::Property>,
L<REST::Neo4p::Constraint::Relationship>,
L<REST::Neo4p::Constraint::RelationshipType> for examples.

=head1 DESCRIPTION

Objects of class REST::Neo4p::Constraint are used to capture and
organize L<REST::Neo4p> application level constraints on Neo4j Node
and Relationship content.

The L<REST::Neo4p::Constrain> module provides a more convenient
factory for REST::Neo4p::Constraint subclasses that specify L<node
property|REST::Neo4p::Constraint::Property>, L<relationship
property|REST::Neo4p::Property>,
L<relationship|REST::Neo4p::Constraint::Relationship>, and
L<relationship type|REST::Neo4p::Constraint::RelationshipType>
constraints.

=head1 FLAGS

=over

=item C<$REST::Neo4p::Constraint::STRICT_RELN_TYPES>

When true, relationships are disallowed if the relationship type does
not meet any current relationship type constraint. Default is true.

=item C<$REST::Neo4p::Constraint::STRICT_RELN_PROPS>

When true, relationships are disallowed if their relationship
properties do not meet any current relationship property constraint.

Default is false. This is so relationships without properties can be
made freely. When relationship property checking is strict, you can
allow relationships without properties by setting the following
constraint:

  create_constraint(
   tag => 'free_reln_prop',
   type => 'relationship_property',
   rtype => '*',
   condition => 'all',
   constraints => {}
  );

=back

=head1 METHODS

=head2 Class Methods

=over

=item new()

 $reln_pc = REST::Neo4p::Constraint::RelationshipProperty->new($constraints);

Constructor.  Construction also registers the constraint for
validation. See subclass pod for details.

=item get_constraint()
 
 $c = REST::Neo4p::Constraint->get_constraint('spiffy_node');

Get a registered constraint by constraint tag. Returns false if none found.

=item get_all_constraints()

 %constraints = REST::Neo4p::Constraint->get_all_constraints();

Get a hash of all registered constraint objects, keyed by constraint tag.

=back 

=head2 Instance Methods

=over

=item tag()

=item type()

=item condition()

=item set_condition()

 $reln_c->set_condition('only');

Set the group condition for the constraint. See subclass pod for details.

=item priority()

=item set_priority()

 $node_pc->set_priority(10);

Constraints with larger priority values are checked before those with
smaller values by the L<C<validate_*()>|/Functional interface for
validation> functions.

=item constraints()

Returns the hashref of constraints. Format depends on the subclass.

=item add_constraint()

 $node_pc->add_constraint( 'warning_level' => qr/^[0-9]$/ );
 $reln_c->add_constraint( { 'species' => 'genus' } );

Add an individual constraint specification to an existing constraint
object. See subclass pod for details.

=item remove_constraint()

 $node_pc->remove_constraint( 'warning_level' );
 $reln_c->remove_constraint( { 'genus' => 'species' } );

Remove an individual constraint specification from an existing
constraint object. See subclass pod for details.

=back

=head2 Functional interface for validation

=over

=item validate_properties()

 validate_properties( $node_object )
 validate_properties( $relationship_object );
 validate_properties( { name => 'Steve', instrument => 'banjo' } );

=item validate_relationship()

 validate_relationship ( $relationship_object );
 validate_relationship ( $node_object1 => $node_object2, 
                         $reln_type );
 validate_relationship ( { name => 'Steve', instrument => 'banjo' } =>
                         { name => 'Marcia', instrument => 'blunt' },
                         'avoids' );

=item validate_relationship_type()

 validate_relationship_type( 'avoids' )

=back

Functional interface. Returns the registered constraint object with
the highest priority that the argument satisfies, or false if none is
satisfied.

These methods can be exported as follows:

 use REST::Neo4p::Constraint qw(:validate)

They can also be exported from L<REST::Neo4p::Constrain>:

 use REST::Neo4p::Constrain qw(:validate)

=head2 Serializing and loading constraints

=over

=item serialize_constraints()

 open $f, ">constraints.json";
 print $f serialize_constraints();

Returns a JSON-formatted representation of all currently registered
constraints.

=item load_constraints()

 open $f, "constraints.json";
 {
   local $/ = undef;
   load_constraints(<$f>);
 }

Creates and registers a list of constraints specified by a JSON string
as produced by L</serialize_constraints()>.

=back

=head1 SEE ALSO

L<REST::Neo4p>,L<REST::Neo4p::Constrain>,
L<REST::Neo4p::Constraint::Property>, L<REST::Neo4p::Constraint::Relationship>,
L<REST::Neo4p::Constraint::RelationshipType>. L<REST::Neo4p::Node>, L<REST::Neo4p::Relationship>,

=head1 AUTHOR

    Mark A. Jensen
    CPAN ID: MAJENSEN
    majensen -at- cpan -dot- org

=head1 LICENSE

Copyright (c) 2012-2020 Mark A. Jensen. This program is free software; you
can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

1;
