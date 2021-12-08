package ChoboTest::FakeHandle;

use Mouse;

use ChoboTest::FakeStatement;

has current_sth => (is => 'rw', isa => 'Maybe[ChoboTest::FakeStatement]', required => 0);
has storage => (is => 'rw', isa => 'HashRef',
                default => sub {
                  {
                    db => {
                      id_counter => 102,
                      column_names => [
                        'db_id', 'name',
                      ],
                      rows => [
                        [ 100, 'OBO_REL' ],
                        [ 101, 'internal' ],
                      ],
                      unique_columns => ['name'],
                    },
                    dbxref =>{
                      id_counter => 206,
                      column_names => [
                        'dbxref_id', 'accession', 'db_id',
                      ],
                      rows => [
                        [ 200, 'is_a', 100 ],
                        [ 201, 'exact', 101 ],
                        [ 202, 'narrow', 101 ],
                        [ 203, 'cv_version', 101 ],
                        [ 204, 'replaced_by', 101 ],
                        [ 205, 'consider', 101 ],
                      ],
                      unique_columns => ['accession', 'db_id'],
                    },
                    cv => {
                      id_counter => 304,
                      column_names => [
                        'cv_id', 'name',
                      ],
                      rows => [
                        [ 300, 'relationship' ],
                        [ 301, 'synonym_type' ],
                        [ 302, 'cv_property_type' ],
                        [ 303, 'cvterm_property_type' ],
                      ],
                      unique_columns => ['name'],
                    },
                    cvterm => {
                      id_counter => 406,
                      column_names => [
                        'cvterm_id', 'name', 'definition', 'cv_id',
                        'dbxref_id', 'is_relationshiptype', 'is_obsolete',
                      ],
                      rows => [
                        [ 400, 'is_a', 'is_a', 300, 200, 1, 0],
                        [ 401, 'exact', 'exact', 301, 201, 0, 0],
                        [ 402, 'narrow', 'narrow', 301, 202, 0, 0],
                        [ 403, 'cv_version', 'cv_version', 302, 203, 0, 0],
                        [ 404, 'replaced_by', 'replaced_by', 303, 204, 0, 0],
                        [ 405, 'consider', 'consider', 303, 205, 0, 0],
                      ],
                      unique_columns => ['name', 'cv_id'],
                    },
                    cvtermsynonym => {
                      id_counter => 501,
                      column_names => [
                        'cvtermsynonym_id', 'cvterm_id', 'synonym', 'type_id',
                      ],
                      rows => [
                      ],
                    },
                    cvterm_relationship => {
                      id_counter => 601,
                      column_names => [
                        'cvterm_relationship_id', 'subject_id', 'type_id', 'object_id',
                      ],
                      rows => [
                      ],
                    },
                    cvterm_dbxref => {
                      id_counter => 701,
                      column_names => [
                        'cvterm_dbxref_id', 'cvterm_id', 'dbxref_id', 'is_for_definition',
                      ],
                      rows => [
                      ],
                    },
                    cvprop => {
                      id_counter => 801,
                      column_names => [
                        'cvprop_id', 'cv_id', 'type_id', 'value',
                      ],
                      rows => [
                      ],
                    },
                    cvtermprop => {
                      id_counter => 901,
                      column_names => [
                        'cvtermprop_id', 'cvterm_id', 'type_id', 'value',
                      ],
                      rows => [
                      ],
                    },
                  }
                });

sub BUILD
{
  my $self = shift;

  for my $key (keys %{$self->storage()}) {
    my @column_names = @{$self->storage()->{$key}->{column_names}};
    for (my $i = 0; $i < @column_names; $i++) {
      my $col_name = $column_names[$i];
      $self->storage()->{$key}->{column_info}->{$col_name} = {
        index => $i,
      }
    }
  }
}

sub do
{
  my $self = shift;

  $self->current_sth(ChoboTest::FakeStatement->new(statement => $_[0],
                                                   storage => $self->storage()));
}

sub pg_putcopydata
{
  my $self = shift;

  return $self->current_sth()->pg_putcopydata(@_);
}

sub pg_getcopydata
{
  my $self = shift;

  return $self->current_sth()->pg_getcopydata(@_);
}

sub pg_putcopyend
{
  my $self = shift;

  $self->current_sth(undef);

  return 1;
}

sub errstr
{
  return '';
}

sub prepare
{
  my $self = shift;

  return ChoboTest::FakeStatement->new(storage => $self->storage(), statement => $_[0]);
}

1;
