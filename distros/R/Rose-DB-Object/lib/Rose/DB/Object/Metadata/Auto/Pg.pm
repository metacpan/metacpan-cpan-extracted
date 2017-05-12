package Rose::DB::Object::Metadata::Auto::Pg;

use strict;

use Carp();

use Rose::DB::Object::Metadata::UniqueKey;

use Rose::DB::Object::Metadata::Auto;
our @ISA = qw(Rose::DB::Object::Metadata::Auto);

our $Debug;

our $VERSION = '0.812';

# Other useful columns, not selected for now
#   pg_get_indexdef(i.oid) AS indexdef
#   n.nspname AS schemaname, 
#   c.relname AS tablename,
#   i.relname AS indexname,
#   t.spcname AS "tablespace",
#   x.indisunique AS is_unique_index,
#
# Plus this join condition for table "t"
# LEFT JOIN pg_catalog.pg_tablespace t ON t.oid = i.reltablespace
use constant UNIQUE_INDEX_SQL => <<'EOF';
SELECT 
  x.indrelid,
  x.indkey,
  i.relname AS key_name,
  CASE WHEN x.indpred IS NULL THEN 0 ELSE 1 END AS has_predicate
FROM 
  pg_catalog.pg_index x
  JOIN pg_catalog.pg_class c ON c.oid = x.indrelid
  JOIN pg_catalog.pg_class i ON i.oid = x.indexrelid
  LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE
  x.indisunique = 't' AND
  c.relkind     = 'r' AND 
  i.relkind     = 'i' AND
  n.nspname     = ?   AND
  c.relname     = ?
EOF

use constant UNIQUE_INDEX_COLUMNS_SQL_STUB => <<'EOF';
SELECT
  attname
FROM
  pg_catalog.pg_attribute
WHERE
  attrelid = ? AND
  attnum 
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
      $schema = lc $schema  if(defined $schema);

      my $table = lc $self->table;

      my($relation_id, $column_nums, $key_name, $has_predicate);

      my $sth = $dbh->prepare(UNIQUE_INDEX_SQL);

      $sth->execute($schema, $table);
      $sth->bind_columns(\($relation_id, $column_nums, $key_name, $has_predicate));

      while($sth->fetch)
      {
        # See if we need to ignore predicated unique indices.  The semantics 
        # of predicated indexes, e.g.,
        #
        #    CREATE UNIQUE INDEX ... WHERE column = 'value'
        #
        # are different from RDBO's unique key semantics in that predicates
        # (may) cause the index to apply only partially to the table.
        if($has_predicate && !$self->include_predicated_unique_indexes)
        {
          $Debug && warn "$class - Skipping predicated unique index $key_name\n";
          next;
        }

        # Skip functional indexes (e.g., "... ON (LOWER(name))") which show up
        # as having a pg_index.indkey ($column_nums) value of 0.
        next  if($column_nums eq '0'); 

        my $uk = 
          Rose::DB::Object::Metadata::UniqueKey->new(
            name          => $key_name,
            parent        => $self,
            has_predicate => $has_predicate);

        # column_nums is a space-separated list of numbers.  It's really an
        # "in2vector" data type, which seems sketchy to me, but whatever. 
        # We can fall back to the pg_get_indexdef() function and try to
        # parse that mess if this ever stops working.
        my @column_nums = grep { /^\d+$/ } split(/\s+/, $column_nums);

        my $col_sth = $dbh->prepare(UNIQUE_INDEX_COLUMNS_SQL_STUB . 
                                   ' IN(' . join(', ', @column_nums) . ')');

        my($column, @columns);

        $col_sth->execute($relation_id);
        $col_sth->bind_columns(\$column);

        while($col_sth->fetch)
        {
          push(@columns, $column);
        }

        unless(@columns)
        {
          die "No columns found for relation id $relation_id, column numbers @column_nums";
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

sub auto_generate_column
{
  my($self, $name, $col_info) = @_;

  $col_info->{'NUMERIC_PRECISION'} = $col_info->{'DECIMAL_DIGITS'};
  $col_info->{'NUMERIC_SCALE'}     = $col_info->{'COLUMN_SIZE'};

  return $self->SUPER::auto_generate_column($name, $col_info);
}

1;
