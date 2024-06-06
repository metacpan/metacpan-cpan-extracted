package PomBase::Chobo::OntologyData;

=head1 NAME

PomBase::Chobo::OntologyData - An in memory representation of an Ontology

=head1 SYNOPSIS

Objects of this class represent the part of an ontology that can be stored in
a Chado database.

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomBase::Chobo::OntologyData

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

our $VERSION = '0.040'; # VERSION

use Mouse;

use Clone qw(clone);
use Try::Tiny;
use Carp;

use PomBase::Chobo::OntologyTerm;


has terms_by_id => (is => 'rw', init_arg => undef, isa => 'HashRef',
                    default => sub { {} });
has terms_by_name => (is => 'rw', init_arg => undef, isa => 'HashRef',
                      default => sub { {} });
has terms_by_cv_name => (is => 'rw', init_arg => undef, isa => 'HashRef',
                         default => sub { {} });
has relationship_terms_by_cv_name => (is => 'rw', init_arg => undef, isa => 'HashRef',
                                 default => sub { {} });
has terms_by_db_name => (is => 'rw', init_arg => undef, isa => 'HashRef',
                         default => sub { {} });
has metadata_by_namespace => (is => 'rw', init_arg => undef, isa => 'HashRef',
                              default => sub { {} });
has _term_relationships => (is => 'rw', init_arg => undef, isa => 'HashRef',
                           default => sub { {} });

=head2 add

 Usage   : $ontology_data->add(metadata => {..}, terms => [...]);
 Function: Add some terms, often all terms from one OBO file
 Args    : metadata - the metadata for the terms
           terms - an array of OntologyTerm objects
 Return  : Nothing, dies on error

=cut

sub add
{
  my $self = shift;

  my %args = @_;

  my $metadata = $args{metadata};
  my $terms = $args{terms};

  my $terms_by_id = $self->terms_by_id();
  my $terms_by_name = $self->terms_by_name();
  my $terms_by_cv_name = $self->terms_by_cv_name();
  my $relationship_terms_by_cv_name = $self->relationship_terms_by_cv_name();

  my $metadata_by_namespace = $self->metadata_by_namespace();

  for my $term (@$terms) {
    my @new_term_ids = ($term->{id});

    push @new_term_ids, map { $_->{id}; } $term->alt_ids();

    my @found_existing_terms = ();

    for my $id (@new_term_ids) {
      my $existing_term = $terms_by_id->{$id};

      if (defined $existing_term && !$existing_term->{is_obsolete}) {
        if (!grep { $_ == $existing_term } @found_existing_terms) {
          push @found_existing_terms, $existing_term;
        }
      }
    }

    if (@found_existing_terms > 1) {
      die "two previously read terms match an alt_id field from:\n" .
        $term->to_string() . "\n\nmatching term 1:\n" .
        $found_existing_terms[0]->to_string() . "\n\nmatching term 2:\n" .
        $found_existing_terms[1]->to_string() . "\n";
    } else {
      if (@found_existing_terms == 1) {
        my $existing_term = $found_existing_terms[0];

        if (!$term->is_obsolete() && !$existing_term->is_obsolete()) {
          my $old_namespace = $existing_term->namespace();

          $existing_term->merge($term);

          if ($old_namespace ne $existing_term->namespace()) {
            delete $self->terms_by_cv_name()->{$old_namespace}->{$existing_term->name()};
          }

          $term = $existing_term;
        }
      }
    }

    for my $id_details ($term->alt_ids(),
                        { id => $term->{id},
                          db_name => $term->{db_name},
                          accession => $term->{accession},
                         } ) {
      $terms_by_id->{$id_details->{id}} = $term;

      $self->terms_by_db_name()->{$id_details->{db_name}}->{$id_details->{accession}} = $term;
    }

    my $def = $term->def();

    map {
      my $def_dbxref = $_;
      if ($def_dbxref =~ /^(.+?):(.*)/) {
        my ($def_db_name, $def_accession) = ($1, $2);
        $self->terms_by_db_name()->{$def_db_name}->{$def_accession} = $term;
      } else {
        die qq(can't parse dbxref from "def:" line: $def_dbxref);
      }
    } @{$def->{dbxrefs}};

    map {
      my $xref = $_;

      if ($xref =~ /^(.+?):(.*)/) {
        my ($def_db_name, $def_accession) = ($1, $2);
        $self->terms_by_db_name()->{$def_db_name}->{$def_accession} = $term;
      } else {
        die qq(can't parse "xref:" line: $xref);
      }
    } $term->xrefs();

    my $name = $term->{name};

    if (defined $name) {
      if (!exists $terms_by_name->{$name} ||
          !grep { $_ == $term } @{$terms_by_name->{$name}}) {
        push @{$terms_by_name->{$name}}, $term;
      }
    } else {
      warn "term without a name tag ignored:\n", $term->to_string(), "\n\n";
      next;
    }

    my $term_namespace = $term->namespace();

    if (defined $term_namespace) {
      my $existing_term_by_name = $terms_by_cv_name->{$term_namespace}->{$name};
      if ($existing_term_by_name && $existing_term_by_name != $term) {
        warn qq(more than one Term with the name "$name" in namespace "$term_namespace" -\n) .
          "existing:\n" . $term->to_string() . "\n\nand:\n" .
          $terms_by_cv_name->{$term_namespace}->{$name}->to_string() . "\n\n";
      } else {
        $terms_by_cv_name->{$term_namespace}->{$name} = $term;
      }

      if ($term->{is_relationshiptype}) {
        $relationship_terms_by_cv_name->{$term_namespace}->{$name} = $term;
      }

      if (!exists $metadata_by_namespace->{$term_namespace}) {
        $metadata_by_namespace->{$term_namespace} = clone $metadata;
      }
    }

    if ($term->{relationship}) {
      for my $rel (@{$term->{relationship}}) {
        my $key = $term->{id} . '<' . $rel->{relationship_name} .
          '>' . $rel->{other_term};
        $self->_term_relationships()->{$key} = 1;
      }
    }
  }
}

sub get_terms_by_name
{
  my $self = shift;
  my $name = shift;

  return @{$self->terms_by_name()->{$name} // []};
}

sub get_term_by_id
{
  my $self = shift;
  my $id = shift;

  return $self->terms_by_id()->{$id};
}

sub get_cv_names
{
  my $self = shift;

  return keys %{$self->terms_by_cv_name()};
}

sub get_terms_by_cv_name
{
  my $self = shift;
  my $cv_name = shift;

  return values %{$self->terms_by_cv_name()->{$cv_name}};
}

sub get_db_names
{
  my $self = shift;

  return keys %{$self->terms_by_db_name()};
}

sub accessions_by_db_name
{
  my $self = shift;
  my $db_name = shift;

  return sort keys %{$self->terms_by_db_name()->{$db_name}};
}

sub get_terms
{
  my $self = shift;

  return map { $self->get_terms_by_cv_name($_); } $self->get_cv_names();
}

sub get_namespaces
{
  my $self = shift;

  return keys %{$self->metadata_by_namespace()};
}

sub get_metadata_by_namespace
{
  my $self = shift;
  my $namespace = shift;

  return $self->metadata_by_namespace()->{$namespace};
}

sub relationships
{
  my $self = shift;

  if ($self->{_relationships}) {
    return @{$self->{_relationships}}
  }

  $self->{_relationships} = [map {
    my ($subject_id, $rel_name, $object_id) = /(.*)<(.*)>(.*)/;

    my $object_term = $self->get_term_by_id($object_id);

    if (!$object_term) {
      my $subject_term = $self->get_term_by_id($subject_id);
      warn qq(ignoring relation where object isn't defined: "$object_id" line ) .
        $subject_term->{source_file_line_number} . ' of ' .
        $subject_term->{source_file} . "\n";
      ();
    } else {
      [$subject_id, $rel_name, $object_id];
    }
  } sort keys %{$self->_term_relationships()}];

  return @{$self->{_relationships}};
}

=head2 finish

 Usage   : $self->finish();
 Function: remove namespaces that are empty due to merging and check that
           objects and subjects of relationships exist

=cut

sub finish
{
  my $self = shift;

  my @relationships = $self->relationships();

  if (@relationships == 0) {
    warn "note: no relationships read\n";
  }

  # find and remove namespaces that are empty due to merging
  my @empty_namespaces =
    map {
      if (scalar(keys %{$self->terms_by_cv_name()->{$_}}) == 0) {
        $_;
      } else {
        ();
      }
    } keys %{$self->terms_by_cv_name()};

  map {
    delete $self->terms_by_cv_name()->{$_};
  } @empty_namespaces;
}

1;
