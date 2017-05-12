package Rose::DB::Object::Metadata::Auto::Oracle;

use strict;

use Carp();

use Rose::DB::Object::Metadata::UniqueKey;

use Rose::DB::Object::Metadata::Auto;
our @ISA = qw(Rose::DB::Object::Metadata::Auto);

our $VERSION = '0.786';

sub auto_init_primary_key_columns
{
  my($self) = shift;

  $self->SUPER::auto_init_primary_key_columns(@_);

  my $cm = $self->convention_manager;

  return  if($cm->no_auto_sequences);

  my($db, @sequences);
  my $table = $self->table;

  # Check for sequence(s) for what look like non-null "serial" columns.
  foreach my $name ($self->primary_key_columns)
  {
    my $column = $self->column($name) or next;
    next unless ($column->not_null);
    my $sequence_name = uc $cm->auto_primary_key_column_sequence_name($table, $name);
    $db ||= $self->init_db;
    push(@sequences, $db->sequence_exists($sequence_name) ? $sequence_name : undef);
  }

  $self->primary_key_sequence_names($db, @sequences)  if(@sequences);

  return;
}

use constant UNIQUE_INDEX_SQL => <<'EOF';
SELECT AI.INDEX_NAME FROM ALL_INDEXES AI, ALL_CONSTRAINTS AC 
WHERE AI.INDEX_NAME = AC.CONSTRAINT_NAME AND 
      AC.CONSTRAINT_TYPE <> 'P' AND 
      AI.UNIQUENESS = 'UNIQUE' AND AI.TABLE_NAME = ? AND 
      AI.TABLE_OWNER = ?
EOF

use constant UNIQUE_INDEX_COLUMNS_SQL_STUB => <<'EOF';
SELECT COLUMN_NAME FROM ALL_IND_COLUMNS WHERE INDEX_NAME = ? ORDER BY COLUMN_POSITION
EOF

sub auto_generate_unique_keys
{
  my($self) = shift;

  unless(defined wantarray)
  {
    Carp::croak "Useless call to auto_generate_unique_keys() in void context";
  }

  my($class, @unique_keys, $error);

  TRY:
  {
    local $@;

    eval
    {
      $class = $self->class or die "Missing class!";

      my $db  = $self->db;
      my $dbh = $db->dbh or die $db->error;

      local $dbh->{'FetchHashKeyName'} = 'NAME';

      my $schema = $self->select_schema($db);
      $schema = $db->default_implicit_schema  unless(defined $schema);
      $schema = uc $schema  if(defined $schema);

      my $table = uc $self->table;

      my $key_name;

      my $sth = $dbh->prepare(UNIQUE_INDEX_SQL);

      $sth->execute($table, $schema);
      $sth->bind_columns(\$key_name);

      while($sth->fetch)
      {
        my $uk = Rose::DB::Object::Metadata::UniqueKey->new(name   => $key_name,
                                                            parent => $self);

        my $col_sth = $dbh->prepare(UNIQUE_INDEX_COLUMNS_SQL_STUB);

        my($column, @columns);

        $col_sth->execute($key_name);
        $col_sth->bind_columns(\$column);

        while($col_sth->fetch)
        {
          push(@columns, $column);
        }

        unless(@columns)
        {
          die "No columns found for key $key_name";
        }

        $uk->columns(\@columns);

        push(@unique_keys, $uk);
      }
    };

    $error = $@;
  }

  if($error)
  {
    Carp::croak "Could not auto-retrieve unique keys for class $class - $error";
  }

  # This sort order is part of the API, and is essential to make the
  # test suite work.
  @unique_keys = sort { lc $a->name cmp lc $b->name } @unique_keys;

  return wantarray ? @unique_keys : \@unique_keys;
}

1;
