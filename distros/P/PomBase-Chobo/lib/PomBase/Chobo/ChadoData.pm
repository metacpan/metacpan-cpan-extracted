package PomBase::Chobo::ChadoData;

=head1 NAME

PomBase::Chobo::ChadoData - Read and store cv/db data from Chado

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomBase::Chobo::ChadoData

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

our $VERSION = '0.022'; # VERSION

use Mouse;

use Carp qw(confess);

has dbh => (is => 'ro');

has cv_data => (is => 'ro', init_arg => undef, lazy_build => 1);
has cvprop_data => (is => 'ro', init_arg => undef, lazy_build => 1);
has db_data => (is => 'ro', init_arg => undef, lazy_build => 1);

has cvterm_data => (is => 'ro', init_arg => undef, lazy_build => 1);
has dbxref_data => (is => 'ro', init_arg => undef, lazy_build => 1);

has cvtermsynonyms_by_cvterm_id => (is => 'rw', init_arg => undef, lazy_build => 1);

our @cvterm_column_names = qw(cvterm_id name cv_id dbxref_id is_obsolete is_relationshiptype);
our @dbxref_column_names = qw(dbxref_id db_id accession);

sub _execute
{
  my $self = shift;
  my $sql = shift;
  my $proc = shift;

  my $dbh = $self->dbh();

  my $sth = $dbh->prepare($sql);
  my $rv = $sth->execute();
  if (!$rv) {
    die "couldn't execute() $sql: ", $dbh->errstr(), "\n";
  }

  while (my $ref = $sth->fetchrow_hashref() ) {
    $proc->($ref);
  }

  $sth->finish();
}

sub _get_cv_or_db
{
  my $self = shift;
  my $table_name = shift;

  my $table_id_column = "${table_name}_id";

  my %by_id = ();
  my %by_name = ();

  my $proc = sub {
    my $row_ref = shift;

    my $id = $row_ref->{$table_id_column};
    my $name = $row_ref->{name};

    my %data = (
      $table_id_column, $id,
      name => $name,
    );

    $by_id{$id} = \%data;
    $by_name{$name} = \%data;

  };

  $self->_execute("select $table_id_column, name from $table_name", $proc);

  return \%by_id, \%by_name;
}

sub _build_cv_data
{
  my $self = shift;

  my ($cvs_by_cv_id, $cvs_by_cv_name) = $self->_get_cv_or_db('cv');
  return { by_id => $cvs_by_cv_id, by_name => $cvs_by_cv_name };
}

sub _build_cvprop_data
{
  my $self = shift;

  my %by_cv_id = ();

  my $proc = sub {
    my $row_ref = shift;

    my $cv_id = $row_ref->{cv_id};

    my %data = (
      cv_id => $cv_id,
      type_id => $row_ref->{type_id},
      value => $row_ref->{value}
    );

    push @{$by_cv_id{$cv_id}}, \%data;
  };

  $self->_execute("select cv_id, type_id, value from cvprop", $proc);

  return \%by_cv_id;
}

sub get_cv_by_name
{
  my $self = shift;
  my $cv_name = shift;

  return $self->cv_data()->{by_name}->{$cv_name};
}

sub get_cv_names
{
  my $self = shift;

  return keys %{$self->cv_data()->{by_name}};
}

sub _build_db_data
{
  my $self = shift;

  my ($dbs_by_db_id, $dbs_by_db_name) = $self->_get_cv_or_db('db');
  return { by_id => $dbs_by_db_id, by_name => $dbs_by_db_name, };
}

sub get_db_by_name
{
  my $self = shift;
  my $db_name = shift;

  return $self->db_data()->{by_name}->{$db_name};
}

sub get_db_names
{
  my $self = shift;

  return keys %{$self->db_data()->{by_name}};
}

sub _get_by_copy
{
  my $self = shift;
  my $table_name = shift;
  my $column_names_ref = shift;
  my @column_names = @$column_names_ref;
  my $proc = shift;

  my $dbh = $self->dbh();

  my $column_names = join ',', @column_names;

  $dbh->do("COPY $table_name($column_names) TO STDOUT CSV")
    or die "failed to COPY $table_name: ", $dbh->errstr, "\n";

  my $tsv = Text::CSV->new({sep_char => ","});

  my $line = undef;

  while ($dbh->pg_getcopydata(\$line) > 0) {
    chomp $line;
    if ($tsv->parse($line)) {
      my @fields = $tsv->fields();
      $proc->(\@fields);
    } else {
      die "couldn't parse this line: $line\n";
    }
  }
}

sub _get_cvtermsynonyms
{
  my $self = shift;

  my $dbh = $self->dbh();

  my @column_names = qw(cvtermsynonym_id cvterm_id synonym type_id);

  my %by_cvterm_id = ();

  my $proc = sub {
    my $fields_ref = shift;
    my @fields = @$fields_ref;
    my ($cvtermsynonym_id, $cvterm_id, $synonym, $type_id) = @fields;
    $by_cvterm_id{$cvterm_id} = \@fields;
  };

  $self->_get_by_copy('cvtermsynonym', \@column_names, $proc);

  return \%by_cvterm_id
}

sub _make_term
{
  my $self = shift;
  my $cvterm_data = shift;
  my $dbxref_data = shift;

  my $dbxref_id = $cvterm_data->[3];

  my $by_dbxref_id = $dbxref_data->{by_dbxref_id};
  my $termid = $by_dbxref_id->{$dbxref_id}->{termid};

  return bless {
    id => $termid,
    cvterm_id => $cvterm_data->[0],
    name => $cvterm_data->[1],
    cv_id => $cvterm_data->[2],
    dbxref_id => $dbxref_id,
    is_obsolete => $cvterm_data->[4],
    is_relationshiptype => $cvterm_data->[5],
  }, 'PomBase::Chobo::OntologyTerm';
}

sub _build_cvterm_data
{
  my $self = shift;

  my %by_cvterm_id = ();
  my %by_cv_id = ();
  my %by_termid = ();

  my $dbxref_data = $self->dbxref_data();

  my $proc = sub {
    my $fields_ref = shift;

    my $term = $self->_make_term($fields_ref, $dbxref_data);

    $by_cvterm_id{$term->cvterm_id()} = $term;
    $by_cv_id{$term->cv_id()}->{$term->name()} = $term;
    $by_termid{$term->id()} = $term;
  };

  $self->_get_by_copy('cvterm', \@cvterm_column_names, $proc);

  return {
    by_cvterm_id => \%by_cvterm_id,
    by_cv_id => \%by_cv_id,
    by_termid => \%by_termid,
  };
}

sub get_cvterm_by_cvterm_id
{
  my $self = shift;

  return $self->cvterm_data()->{by_cvterm_id};
}

sub get_cvterms_by_cv_id
{
  my $self = shift;
  my $cv_id = shift;

  if (!defined $cv_id) {
    confess "undefined cv_id passed to get_cvterms_by_cv_id()";
  }

  return $self->cvterm_data()->{by_cv_id}->{$cv_id};
}

sub get_cvterm_by_termid
{
  my $self = shift;
  my $termid = shift;

  return $self->cvterm_data()->{by_termid}->{$termid};
}

sub get_all_cvterms
{
  my $self = shift;

  return values %{$self->cvterm_data()->{by_termid}};
}

sub get_cvterm_by_name
{
  my $self = shift;
  my $cv_name = shift;
  my $cvterm_name = shift;

  my $cv = $self->get_cv_by_name($cv_name);

  return $self->get_cvterms_by_cv_id($cv->{cv_id})->{$cvterm_name};
}

sub get_cvprop_values
{
  my $self = shift;
  my $cv_name = shift;
  my $prop_type_name = shift;

  my $cv = $self->get_cv_by_name($cv_name);
  my $cvprops = $self->cvprop_data()->{$cv->{cv_id}};
  my $prop_type = $self->get_cvterm_by_name($cv_name, $prop_type_name);

  return map {
    $_->{value}
  }
  grep {
    $_->{type_id} == $prop_type->{cvterm_id}
  } @{$cvprops // []};
}

sub get_all_termids
{
  my $self = shift;

  return keys %{$self->dbxref_data()->{by_termid}};
}

sub get_dbxref_by_termid
{
  my $self = shift;
  my $termid = shift;

  return $self->dbxref_data()->{by_termid}->{$termid};
}

sub _build_dbxref_data
{
  my $self = shift;

  my $dbh = $self->dbh();

  my $db_data = $self->db_data();

  my %by_dbxref_id = ();
  my %by_termid = ();
  my %by_db_name = ();

  my $proc = sub {
    my $fields_ref = shift;
    my @fields = @$fields_ref;
    my ($dbxref_id, $db_id, $accession, $version) = @fields;

    my %data = (dbxref_id => $dbxref_id,
                db_id => $db_id,
                accession => $accession,
                version => $version);

    my $db_name = $db_data->{by_id}->{$db_id}->{name};
    if (!defined $db_name) {
      die "no db name for db $db_id";
    }

    my $termid;

    if ($db_name eq '_global') {
      $termid = $accession;
    } else {
      $termid = "$db_name:$accession";
    }

    $data{termid} = $termid;

    $by_dbxref_id{$dbxref_id} = \%data;
    $by_termid{$termid} = \%data;
    $by_db_name{$db_name}->{$termid} = \%data;
  };

  $self->_get_by_copy('dbxref', \@dbxref_column_names, $proc);

  return {
    by_dbxref_id => \%by_dbxref_id,
    by_termid => \%by_termid,
    by_db_name => \%by_db_name,
  };
}

sub _build_cvtermsynonyms_by_cvterm_id
{
  my $self = shift;

  return $self->_get_cvtermsynonyms();
}

sub get_cvtermsynonyms_by_cvterm_id
{
  my $self = shift;
  my $cvterm_id = shift;

  return $self->cvtermsynonyms_by_cvterm_id()->{$cvterm_id};
}

1;
