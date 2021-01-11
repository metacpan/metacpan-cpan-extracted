#$Id$
use v5.10;
package REST::Neo4p::Schema;
use REST::Neo4p::Exceptions;
use Carp qw/carp/;
use strict;
use warnings;

BEGIN {
  $REST::Neo4p::Schema::VERSION = '0.4001';
}

#require 'REST::Neo4p';

sub new {
  REST::Neo4p::CommException->throw("Not connected\n") unless
      REST::Neo4p->connected;
  unless (REST::Neo4p->_check_version(2,0,1)) {
    REST::Neo4p::VersionMismatchException->throw("REST endpoint indexes and constraints are buggy in Neo4j server version < 2.0.1\n");
  }
  my $class = shift;
  my $self = {
    _handle => REST::Neo4p->handle,
    _agent => REST::Neo4p->agent
   };
  bless $self, $class;
}

sub _handle { shift->{_handle} }
sub _agent { shift->{_agent} }

sub create_index {
  my $self = shift;
  my ($label, @props) = @_;
  REST::Neo4p::LocalException->throw("Arg 1 must be a label and arg 2..n a property name\n") unless (defined $label && @props);
  foreach (@props) {
    my $content = { property_keys => [$_] };
    eval {
      $self->_agent->post_data([qw/schema index/,$label], $content);
    };
    if (my $e = REST::Neo4p::ConflictException->caught) {
      1; # ignore, already present
    }
    elsif ( $e = REST::Neo4p::IndexExistsException->caught ) {
      1;
    }
    elsif ($e = Exception::Class->caught()) {
      (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
    }
  }
  return 1;
}

# get_indexes returns false if label not found
sub get_indexes {
  my $self = shift;
  my ($label) = @_;
  REST::Neo4p::LocalException->throw("Arg 1 must be a label\n") unless defined $label;
  my $decoded_resp;
  eval {
    $decoded_resp = $self->_agent->get_data(qw/schema index/, $label);
  };
  if (my $e = REST::Neo4p::NotFoundException->caught) {
    return;
  }
  elsif ($e = Exception::Class->caught()) {
    (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
  }
  my @ret;
  # kludge for Neo4j::Driver
  foreach (@{$self->_agent->decoded_content // $decoded_resp}) {
    push @ret, $_->{property_keys}[0];
  }
  return @ret;
}

sub drop_index {
  my $self = shift;
  my ($label,@names) = @_;
  REST::Neo4p::LocalException->throw("Arg 1 must be a label and arg 2 a property name\n") unless (defined $label && @names);
  foreach (@names) {
    eval {
      $self->_agent->delete_data(qw/schema index/, $label, $_);
    };
    if (my $e = REST::Neo4p::NotFoundException->caught) {
      1; #ignore if not found
    }
    elsif ($e = Exception::Class->caught()) {
      (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
    }
  }
  return 1;
}

sub create_unique_constraint {
  my $self = shift;
  my ($label, @props) = @_;
  return $self->create_constraint($label, \@props, 'uniqueness');
}

sub create_constraint {
  my $self = shift;
  my ($label, $property, $c_type) = @_;
  $c_type ||= 'uniqueness';
  REST::Neo4p::LocalException->throw("Arg 1 must be a label and arg 2 a property name or arrayref\n") unless (defined $label && defined $property);
  my @props = ref $property ? @$property : ($property);
  foreach (@props) {
    my $content = { property_keys => [$_] };
    eval {
      $self->_agent->post_data([qw/schema constraint/,$label,$c_type], $content);
    };
    if (my $e = REST::Neo4p::ConflictException->caught) {
      if ($e->neo4j_message =~ qr/constraint cannot be created/) {
	carp $e->neo4j_message;
      }
      1; # ignore, already present
    }
    elsif ($e = Exception::Class->caught()) {
      (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
    }
  }
  return 1;
}

sub get_constraints {
  my $self = shift;
  my ($label, $c_type) = @_;
  $c_type ||= 'uniqueness';
  REST::Neo4p::LocalException->throw("Arg 1 must be a label\n") unless defined $label;
  my $decoded_resp;
  eval {
    $decoded_resp = $self->_agent->get_data(qw/schema constraint/, $label, $c_type);
  };
  if (my $e = REST::Neo4p::NotFoundException->caught) {
    return;
  }
  elsif ($e = Exception::Class->caught()) {
    (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
  }
  my @ret;
  # kludge for Neo4j::Driver
  foreach (@{$self->_agent->decoded_content // $decoded_resp}) {
    push @ret, $_->{property_keys}[0];
  }
  return @ret;
}

sub drop_unique_constraint {
  my $self = shift;
  my ($label, @props) = @_;
  return $self->drop_constraint($label, \@props, 'uniqueness');
}

sub drop_constraint {
  my $self = shift;
  my ($label, $property, $c_type) = @_;
  $c_type ||= 'uniqueness';
  REST::Neo4p::LocalException->throw("Arg 1 must be a label and arg 2 a property name or arrayref\n") unless (defined $label && defined $property);
  my @props = ref $property ? @$property : ($property);
  foreach (@props) {
    eval {
      $self->_agent->delete_data(qw/schema constraint/,$label,$c_type,$_);
    };
    if (my $e = REST::Neo4p::NotFoundException->caught) {
      1; # ignore, not initially present
    }
    elsif ($e = Exception::Class->caught()) {
      (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
    }
  }
  return 1;
}

=head1 NAME

REST::Neo4p::Schema - Label-based indexes and constraints

=head1 SYNOPSIS
 
 REST::Neo4p->connect($server);
 $schema = REST::Neo4p::Schema->new;
 $schema->create_index('Person','name');
 

=head1 DESCRIPTION

L<Neo4j|http://neo4j.org> v2.0+ provides a way to schematize the graph
on the basis of node labels, associated indexes, and property
uniqueness constraints. C<REST::Neo4p::Schema> allows access to this
system via the Neo4j REST API. Use a C<Schema> object to create, list,
and drop indexes and constraints.

=head1 METHODS

=over

=item create_index()

 $schema->create_index('Label', 'property');
 $schema->create_index('Label', @properties);

The second example is convenience for creating multiple single indexes
on each of a list of properties. It does not create a compound index
on the set of properties. Returns TRUE.

=item get_indexes()

 @properties = $schema->get_indexes('Label');

Get a list properties on which an index exists for a given label.

=item drop_index()

 $schema->drop_index('Label','property');
 $schema->drop_index('Label', @properties);

Remove indexes on given property or properties for a given label.

=item create_unique_constraint()

 $schema->create_unique_constraint('Label', 'property');
 $schema->create_unique_constraint('Label', @properties);

Create uniqueness constraints on a given property or properties for a
given label.

I<Note>: For some inexplicable reason, this one schema feature went behind
the paywall in Neo4j version 4.0. Unless you are using the Enterprise
Edition, this method will throw the dreaded
L<REST::Neo4p::Neo4jTightwadException>.

=item get_constraints()

 @properties = $schema->get_constraints('Label');

Get a list of properties for which (uniqueness) constraints exist for
a given label.

=item drop_unique_constraint()

 $schema->drop_unique_constraint('Label', 'property');
 $schema->drop_unique_constraint('Label', @properties);

Remove uniqueness constraints on given property or properties for a
given label.

=back

=head1 SEE ALSO

L<REST::Neo4p>, L<REST::Neo4p::Index>, L<REST::Neo4p::Query>

=head1 AUTHOR

    Mark A. Jensen
    CPAN ID: MAJENSEN
    majensen -at- cpan -dot- org

=head1 LICENSE

Copyright (c) 2012-2021 Mark A. Jensen. This program is free software; you
can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

1;
