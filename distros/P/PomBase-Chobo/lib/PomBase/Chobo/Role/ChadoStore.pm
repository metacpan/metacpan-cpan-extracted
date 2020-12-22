package PomBase::Chobo::Role::ChadoStore;

=head1 NAME

PomBase::Chobo::Role::ChadoStore - Code for storing terms in Chado

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomBase::Chobo::Role::ChadoStore

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

our $VERSION = '0.029'; # VERSION

use Mouse::Role;
use Text::CSV::Encoded;
use Carp;

requires 'dbh';
requires 'ontology_data';

use PomBase::Chobo::ChadoData;
use PomBase::Chobo::OntologyConf;

our @relationship_cv_names;

BEGIN {
  @relationship_cv_names = @PomBase::Chobo::OntologyConf::relationship_cv_names;
}

sub _copy_to_table
{
  my $self = shift;
  my $table_name = shift;
  my $column_names_ref = shift;
  my @column_names = @$column_names_ref;
  my $data_ref = shift;
  my @data = @$data_ref;

  my $dbh = $self->dbh();

  my $column_names = join ',', @column_names;

  $dbh->do("COPY $table_name($column_names) FROM STDIN CSV")
    or die "failed to COPY into $table_name: ", $dbh->errstr, "\n";

  my $csv = Text::CSV::Encoded->new({ encoding  => "utf8" });

  for my $row (@data) {
    $csv->combine(@$row);

    if (!$dbh->pg_putcopydata($csv->string() . "\n")) {
      die $dbh->errstr();
    }
  }

  if (!$dbh->pg_putcopyend()) {
    die $dbh->errstr();
  }
}

sub _get_relationship_terms
{
  my $chado_data = shift;

  my @cvterm_data = $chado_data->get_all_cvterms();

  my @rel_terms = grep {
    $_->is_relationshiptype();
  } @cvterm_data;

  my %terms_by_name = ();
  my %terms_by_termid = ();

  map {
    if (exists $terms_by_name{$_->name()}) {
      warn 'two relationship terms with the same name ("' .
        $_->id() . '" and "' . $terms_by_name{$_->name()}->id() . '") - ' .
        'using: ' . $terms_by_name{$_->name()}->id(), "\n";
    } else {
      $terms_by_name{$_->name()} = $_;
      $terms_by_name{$_->name() =~ s/\s+/_/gr} = $_;
      $terms_by_termid{$_->id()} = $_;
    }
  } @rel_terms;

  return (\%terms_by_name, \%terms_by_termid);
}


my %row_makers = (
  db => sub {
    my $ontology_data = shift;
    my $chado_data = shift;

    my %chado_db_names = ();

    map {
      $chado_db_names{$_} = 1;
    } $chado_data->get_db_names();

    return map {
      [$_];
    } grep {
      !$chado_db_names{$_};
    } $ontology_data->get_db_names();
  },
  dbxref => sub {
    my $ontology_data = shift;
    my $chado_data = shift;

    map {
      my $db_name = $_;
      my $db_id = $chado_data->get_db_by_name($db_name)->{db_id};

      my %chado_termids = ();

      map {
        $chado_termids{$_} = 1;
      } $chado_data->get_all_termids();

      my @ont_db_termids = grep {
        !$chado_termids{"$db_name:$_"};
      } $ontology_data->accessions_by_db_name($db_name);

      map {
        my $accession = $_;
        if (!defined $accession) {
          die "accession is null for accession in db: $db_name\n";
        }
        $accession =~ s|\\(.)|$1|g;
        [$db_id, $accession];
      } @ont_db_termids;
    } $ontology_data->get_db_names();
  },
  cv => sub {
    my $ontology_data = shift;
    my $chado_data = shift;

    my %chado_cv_names = ();

    map {
      $chado_cv_names{$_} = 1;
    } $chado_data->get_cv_names();

    return map {
      [$_];
    } grep {
      !$chado_cv_names{$_};
    } $ontology_data->get_cv_names();
  },
  cvterm => sub {
    my $ontology_data = shift;
    my $chado_data = shift;

    map {
      my $term = $_;

      my $cv = $chado_data->get_cv_by_name($term->{namespace});
      my $cv_id = $cv->{cv_id};

      my $dbxref = $chado_data->get_dbxref_by_termid($term->id());

      if (!$dbxref) {
        die "dbxref not found for:\n", $term->to_string(), "\n";
      }

      my $name = $term->name();

      if ($term->is_obsolete()) {
        $name .= ' (obsolete ' . $term->id() . ')';
      }

      my $definition = undef;
      if (defined $term->def()) {
        $definition = $term->def()->{definition};
      }
      my $dbxref_id = $dbxref->{dbxref_id};
      my $is_relationshiptype = $term->{is_relationshiptype};
      my $is_obsolete = $term->{is_obsolete} ? 1 : 0;

      [$name, $definition, $cv_id, $dbxref_id, $is_relationshiptype, $is_obsolete];
    } $ontology_data->get_terms();
  },
  cvtermsynonym => sub {
    my $ontology_data = shift;
    my $chado_data = shift;

    my $synonym_type_cv =
      $chado_data->get_cv_by_name('synonym_type');
    my %synonym_types =
      %{$chado_data->get_cvterms_by_cv_id($synonym_type_cv->{cv_id})};

    map {
      my $term = $_;

      map {
        my $synonym_type_name = $_->{scope};
        my $synonym_type_term =
          $synonym_types{lc $synonym_type_name} //
          $synonym_types{uc $synonym_type_name};

        if (!defined $synonym_type_term) {
          die "unknown synonym scope: $synonym_type_name";
        }

        my $cvterm_id = $chado_data->get_cvterm_by_termid($term->id())->cvterm_id();

        [$cvterm_id, $_->{synonym}, $synonym_type_term->{cvterm_id}];
      } $term->synonyms();
    } $ontology_data->get_terms();
  },
  cvterm_dbxref => sub {
    my $ontology_data = shift;
    my $chado_data = shift;

    my %seen_cvterm_dbxrefs = ();

    map {
      my $term = $_;

      my $helper = sub {
        my $id = shift;
        my $is_for_definition = shift;

        my $cvterm_id = $chado_data->get_cvterm_by_termid($term->id())->cvterm_id();
        my $dbxref_details = $chado_data->get_dbxref_by_termid($id);

        if (!defined $dbxref_details) {
          die "no dbxref details for $id";
        }

        my $dbxref_id = $dbxref_details->{dbxref_id};

        my $key = "$cvterm_id - $dbxref_id";
        if (exists $seen_cvterm_dbxrefs{$key}) {
          warn "not storing duplicate cvterm_dbxref for ", $dbxref_details->{termid};
          ()
        } else {
          if ($is_for_definition) {
            $seen_cvterm_dbxrefs{$key} = 1;
          }
          [$cvterm_id, $dbxref_id, $is_for_definition]
        }
      };

      my @ret = map { $helper->($_->{id}, 0) } $term->alt_ids();

      if ($term->def()) {
        push @ret, map { $helper->($_, 1) } @{$term->def()->{dbxrefs}}
      }

      @ret;
    } $ontology_data->get_terms();
  },
  cvterm_relationship => sub {
    my $ontology_data = shift;
    my $chado_data = shift;

    my ($terms_by_name, $terms_by_termid) = _get_relationship_terms($chado_data);

    map {
      my ($subject_termid, $rel_name_or_id, $object_termid) = @$_;

      my $subject_term = $chado_data->get_cvterm_by_termid($subject_termid);
      if (defined $subject_term) {
        my $subject_id = $subject_term->{cvterm_id};
        my $rel_term = $terms_by_name->{$rel_name_or_id} ||
          $terms_by_termid->{$rel_name_or_id};
        if (!defined $rel_term) {
          die "can't find relation term $rel_name_or_id for relation:\n" .
            "  $subject_termid <-$rel_name_or_id-> $object_termid\n";
        }

        my $rel_id = $rel_term->cvterm_id();

        my $object_term = $chado_data->get_cvterm_by_termid($object_termid);
        if (defined $object_term) {
          my $object_id = $object_term->{cvterm_id};

          [$subject_id, $rel_id, $object_id]
        } else {
          warn "no Chado cvterm for $object_termid - ignoring relation:\n" .
            "  $subject_termid <-$rel_name_or_id-> $object_termid\n";
          ();
        }
      } else {
        warn "no Chado cvterm for $subject_termid - ignoring relation:\n" .
            "  $subject_termid <-$rel_name_or_id-> $object_termid\n";
        ();
      }
    } $ontology_data->relationships();
  },
  cvprop => sub {
    my $ontology_data = shift;
    my $chado_data = shift;

    my @namespaces = $ontology_data->get_namespaces();

    my $cv_version_term = $chado_data->get_cvterm_by_name('cv_property_type', 'cv_version');

    map {
      my $namespace = $_;

      my $metadata = $ontology_data->get_metadata_by_namespace($namespace);
      my $cv_version = $metadata->{'data-version'} || $metadata->{'date'};;

      if ($cv_version) {
        my $cv = $chado_data->get_cv_by_name($namespace);
        my $cv_id = $cv->{cv_id};

        [$cv_id, $cv_version_term->{cvterm_id}, $cv_version];
      } else {
        ();
      }
    } @namespaces
  },

);

my %table_column_names = (
  db => [qw(name)],
  dbxref => [qw(db_id accession)],
  cv => [qw(name)],
  cvterm => [qw(name definition cv_id dbxref_id is_relationshiptype is_obsolete)],
  cvtermsynonym => [qw(cvterm_id synonym type_id)],
  cvterm_dbxref => [qw(cvterm_id dbxref_id is_for_definition)],
  cvterm_relationship => [qw(subject_id type_id object_id)],
  cvprop => [qw(cv_id type_id value)],
);

sub chado_store
{
  my $self = shift;

  $self->ontology_data()->finish();

  my @cvterm_column_names =
    @PomBase::Chobo::ChadoData::cvterm_column_names;

  my @tables_to_store = qw(db dbxref cv cvterm cvtermsynonym cvterm_dbxref cvterm_relationship cvprop);

  for my $table_to_store (@tables_to_store) {
    my $chado_data = PomBase::Chobo::ChadoData->new(dbh => $self->dbh());

    my @rows = $row_makers{$table_to_store}->($self->ontology_data(),
                                              $chado_data);

    $self->_copy_to_table($table_to_store, $table_column_names{$table_to_store},
                          \@rows);
  }

}

1;
