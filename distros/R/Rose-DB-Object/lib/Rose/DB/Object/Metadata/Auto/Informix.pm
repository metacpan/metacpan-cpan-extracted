package Rose::DB::Object::Metadata::Auto::Informix;

use strict;

use Carp();

use Rose::DB::Object::Metadata::ForeignKey;
use Rose::DB::Object::Metadata::UniqueKey;

use Rose::DB::Object::Metadata::Auto;
our @ISA = qw(Rose::DB::Object::Metadata::Auto);

our $VERSION = '0.784';

# syscolumns.coltype constants taken from:
#
# http://www-306.ibm.com/software/data/informix/pubs/library/datablade/dbdk/sqlr/01.fm14.html
use constant CHAR       =>  0;
use constant SMALLINT   =>  1;
use constant INTEGER    =>  2;
use constant FLOAT      =>  3;
use constant SMALLFLOAT =>  4;
use constant DECIMAL    =>  5;
use constant SERIAL     =>  6;
use constant DATE       =>  7;
use constant MONEY      =>  8;
use constant NULL       =>  9;
use constant DATETIME   => 10;
use constant BYTE       => 11;
use constant TEXT       => 12;
use constant VARCHAR    => 13;
use constant INTERVAL   => 14;
use constant NCHAR      => 15;
use constant NVARCHAR   => 16;
use constant INT8       => 17;
use constant SERIAL8    => 18;
use constant SET        => 19;
use constant MULTISET   => 20;
use constant LIST       => 21;
use constant ROW        => 22;
use constant COLLECTION => 23;
use constant ROWREF     => 24;

use constant VARIABLE_LENGTH_OPAQUE =>   40; # Variable-length opaque type
use constant FIXED_LENGTH_OPAQUE    =>   41; # Fixed-length opaque type
use constant NAMED_ROW_TYPE         => 4118; # Named row type 

# Map the Informix column type constants to type names that we can
# handle--or that are at least in our format: lowercase text.
my %Column_Types =
(
  CHAR()       => 'char',
  SMALLINT()   => 'int',
  INTEGER()    => 'int',
  FLOAT()      => 'float',
  SMALLFLOAT() => 'float',
  DECIMAL()    => 'decimal',
  SERIAL()     => 'serial',
  DATE()       => 'date',
  MONEY()      => 'decimal',
  NULL()       => 'null',
  DATETIME()   => 'datetime',
  BYTE()       => 'byte',
  TEXT()       => 'text',
  VARCHAR()    => 'varchar',
  INTERVAL()   => 'interval',
  NCHAR()      => 'char',
  NVARCHAR()   => 'varchar',
  INT8()       => 'int',
  SERIAL8()    => 'bigserial',
  SET()        => 'set',
  MULTISET()   => 'multiset',
  LIST()       => 'list',
  ROW()        => 'row',
  COLLECTION() => 'collection',
  ROWREF()     => 'rowref',
);

# http://www-306.ibm.com/software/data/informix/pubs/library/datablade/dbdk/sqlr/01.fm14.html
my %Column_Length =
(
  # Data Type   Length (in bytes)
  SMALLINT() => 2,
  INTEGER()  => 4,
  INT8()     => 8,
);

# http://www-306.ibm.com/software/data/informix/pubs/library/datablade/dbdk/sqlr/01.fm14.html
my %Datetime_Qualifiers =
(
   0 => 'year',
   2 => 'month',
   4 => 'day',
   6 => 'hour',
   8 => 'minute',
  10 => 'second',
  11 => 'fraction(1)',
  12 => 'fraction(2)',
  13 => 'fraction(3)',
  14 => 'fraction(4)',
  15 => 'fraction(5)',
);

my %Datetime_Qualifiers_Reverse = (reverse %Datetime_Qualifiers);

# Value minus this delta = scale for fraction(n) types
use constant FRACTION_SCALE_DELTA  => 10;

use constant MIN_DATETIME_FRACTION => 11; # fraction(1)
use constant MAX_DATETIME_FRACTION => 15; # fraction(5)

# $INFORMIXDIR/etc/xpg4_is.sql
# http://www-306.ibm.com/software/data/informix/pubs/library/datablade/dbdk/sqlr/01.fm50.html
my %Numeric_Precision =
(
  SMALLINT()   =>  5,
  INTEGER()    => 10,
  FLOAT()      => 63,
  SMALLFLOAT() => 32,
);

# These constants are from the DBI documentation.  Is there somewhere 
# I can load these from?
use constant SQL_NO_NULLS => 0;
use constant SQL_NULLABLE => 1;

sub auto_generate_columns
{
  my($self) = shift;

  my($class, %columns, $table_id, $error);

  TRY:
  {
    local $@;

    eval
    {
      require DBD::Informix::Metadata;

      $class = $self->class or die "Missing class!";

      my $db  = $self->db;  
      my $dbh = $db->dbh or die $db->error;

      local $dbh->{'FetchHashKeyName'} = 'NAME';

      # Informix does not support DBI's column_info() method so we have
      # to get all that into "the hard way."
      #
      # Each item in @col_list is a reference to an array of values:
      #
      #   0     owner name
      #   1     table name
      #   2     column number
      #   3     column name
      #   4     data type (encoded)
      #   5     data length (encoded)
      #
      # Lowercase table because Rose::DB::Informix->likes_lowercase_table_names
      my @col_list = DBD::Informix::Metadata::ix_columns($dbh, lc $self->table);

      # We'll also need to query the syscolumns table directly to get the
      # table id, which we need to query the sysdefaults table.  But to get
      # the correct syscolumns record, we need to first query the systables
      # table.
      my $st_sth = $dbh->prepare(<<"EOF");
SELECT tabid FROM informix.systables WHERE tabname = ? AND owner = ?
EOF

      my %col_info;

      foreach my $item (@col_list)
      {
        # We're going to build a standard DBI column_info() data structure
        # to pass on to the rest of the code.
        my $col_info;

        # Add the "proprietary" values using the DBI convention of lowercase
        # names prefixed with DBD name.
        my @keys = map { "informix_$_" } 
          qw(owner table column_number column_name column_type column_length);

        @$col_info{@keys} = @$item;

        # Copy the "easy" values into the standard DBI locations
        $col_info->{'TABLE_NAME'}  = $col_info->{'informix_table'};
        $col_info->{'COLUMN_NAME'} = $col_info->{'informix_column_name'};

        # Query the systables table to get the table id based on the 
        # table name and owner name.
        $st_sth->execute(@$col_info{qw(informix_table informix_owner)});

        $table_id = $st_sth->fetchrow_array;

        unless(defined $table_id)
        {
          die "Could not find informix.systables record for table '",
               $col_info->{'informix_table'}, "' with owner '",
               $col_info->{'informix_owner'}, "'";
        }

        $col_info->{'informix_tabid'} = $table_id;

        # Store the column info by column name
        $col_info{$col_info->{'COLUMN_NAME'}} = $col_info;
      }

      # We need to query the syscolumns table directly to get the
      # table id, which we need to query the sysdefaults table. 
      my $sc_sth = $dbh->prepare(<<"EOF");
SELECT * FROM informix.syscolumns WHERE tabid = ?
EOF

      # We may need to query the sysxtdtypes table, so reserve a
      # variable for that statement handle.  We'll also cache the
      # results, so we'll set up that hash here too.  We'll also
      # need a mapping from "colno" to column name.
      my($sxt_sth, %extended_type, %colno_to_name);

      # Query the syscolumns table to get some more column information
      $sc_sth->execute($table_id);

      while(my $sc_row = $sc_sth->fetchrow_hashref)
      {
        my $col_info = $col_info{$sc_row->{'colname'}}
          or die "No column info found for column name '$sc_sth->{'colname'}'";

        # Copy all the row values into the DBI column info using the DBI 
        # convention of lowercase names prefixed with DBD name.
        @$col_info{map { "informix_$_" } keys %$sc_row} = values %$sc_row;

        # Store mapping from "colno" to column name
        $colno_to_name{$sc_row->{'colno'}} = $sc_row->{'colname'};

        ##
        ## Painfully derive the data type name (TYPE_NAME)
        ##

        # If the coltype is a value greater than or equal to 256, the
        # column does not allow null values.  To determine the data type for
        # a coltype column that contains a value greater than 256, subtract
        # 256 from the value and evaluate the remainder, based on the
        # possible coltype values.  For example, if a column has a coltype
        # value of 262, subtracting 256 from 262 leaves a remainder of 6,
        # which indicates that this column uses a SERIAL data type.

        my $type_num;

        if($sc_row->{'coltype'} >= 256)
        {
          $col_info->{'informix_type_num'} = $type_num = 
            $sc_row->{'coltype'} - 256;

          # This situation also indicates that the column is NOT NULL,
          # so set all the DBI-style attributes to indicate that.
          $col_info->{'IS_NULLABLE'} = 'NO';
          $col_info->{'NULLABLE'}    = SQL_NO_NULLS;
        }
        else
        {
          $col_info->{'informix_type_num'} = $type_num = $sc_row->{'coltype'};

          $col_info->{'IS_NULLABLE'} = 'YES';
          $col_info->{'NULLABLE'}    = SQL_NULLABLE;      
        }

        #
        # Now we need to turn $type_num into a type name.  Hold on to your hat.
        #

        my $type_name;

        # The following data types are implemented by the database server
        # as built-in opaque types: BLOB, BOOLEAN, CLOB, and LVARCHAR
        #
        # A built-in opaque data type is one for which the database server
        # provides the type definition.  Because these data types are built-in
        # opaque types, they do not have a unique coltype value.  Instead, they
        # have one of the coltype values for opaque types: 41 (fixed-length
        # opaque type), or 40 (varying-length opaque type). The different
        # fixed-length opaque types are distinguished by the extended_id column
        # in the sysxtdtypes system catalog table.
        #
        # The following table summarizes the coltype values for the predefined
        # data types.
        #
        # Type       coltype   symbolic constant
        # --------   -------   -----------------
        # BLOB          41     FIXED_LENGTH_OPAQUE
        # CLOB          41     FIXED_LENGTH_OPAQUE
        # BOOLEAN       41     FIXED_LENGTH_OPAQUE
        # LVARCHAR      40     VARIABLE_LENGTH_OPAQUE

         # BLOB, CLOB, or BOOLEAN
        if($type_num == FIXED_LENGTH_OPAQUE)
        {
          # Maybe we already looked this one up
          if($extended_type{$sc_row->{'extended_id'}})
          {
            $type_name = $extended_type{$col_info->{'informix_extended_id'}};
          }
          else # look it up and cache it
          {
            $sxt_sth ||= 
              $dbh->prepare("SELECT name FROM informix.sysxtdtypes WHERE extended_id = ?");

            $sxt_sth->execute($sc_row->{'extended_id'});

            my $name = $sxt_sth->fetchrow_array;

            # We only handle BOOLEANS specially, and the name column for
            # booleans is already in our type name format: "boolean"
            # So just copy the name value into the cache.
            $type_name = $extended_type{$sc_row->{'extended_id'}} = $name;
          }
        }
        elsif($type_num == VARIABLE_LENGTH_OPAQUE) # LVARCHAR
        {
          $type_name = 'varchar';
        }
        elsif($type_num == DATETIME)
        {
          # Determine the full "datetime X to Y" type string
          $type_name = _ix_datetime_specific_type($self, $type_num, $sc_row->{'collength'}, $col_info);
        }
        else
        {
          $type_name = $Column_Types{$type_num};
        }

        # Finally, set the type name
        $col_info->{'TYPE_NAME'} = $type_name;

        #
        # Mine column length for information
        #

        # COLUMN_SIZE is the maximum length in characters for character data
        # types, the number of digits or bits for numeric data types or the
        # length in the representation of temporal types. See the relevant
        # specifications for detailed information.

        $col_info->{'COLUMN_SIZE'} = 
          _ix_max_length($type_num, $sc_row->{'collength'});

        if($type_num == SMALLINT || $type_num == INTEGER ||
           $type_num == SERIAL   || $type_num == DECIMAL ||
           $type_num == MONEY)
        {
          $col_info->{'DECIMAL_DIGITS'} = 
            _ix_numeric_scale($type_num, $sc_row->{'collength'});

          $col_info->{'COLUMN_SIZE'} =
            _ix_numeric_precision($type_num, $sc_row->{'collength'});

          $col_info->{'NUM_PREC_RADIX'} =
            _ix_numeric_precision_radix($type_num, $sc_row->{'collength'});
        }
      }

      #
      # Get all the column default values from the sysdefaults table
      #

      # class 'T' means "table" (the other possible value us "t" for "row type")
      # http://www-306.ibm.com/software/data/informix/pubs/library/datablade/dbdk/sqlr/01.fm16.html
      my $sd_sth = $dbh->prepare(<<"EOF");
SELECT * FROM informix.sysdefaults WHERE tabid = ? AND class = 'T'
EOF

      $sd_sth->execute($table_id);

      while(my $sd_row = $sd_sth->fetchrow_hashref)
      {
        my $col_name = $colno_to_name{$sd_row->{'colno'}}
          or die "While getting defaults: no column name found for colno '$sd_row->{'colno'}'";

        my $col_info = $col_info{$col_name}
          or die "While getting defaults: no column info found for column '$col_name'";

        # The "type" column of the sysdefaults table looks like this:
        #
        # type  CHAR(1)
        #
        # 'L' = Literal default
        # 'U' = User
        # 'C' = Current
        # 'N' = Null
        # 'T' = Today
        # 'S' = Dbservername 
        #
        # If a literal is specified for the default value, it is stored in
        # the default column as text. If the literal value is not of type
        # CHAR, the default column consists of two parts. The first part is
        # the 6-bit representation of the binary value of the default-value
        # structure. The second part is the default value in English text.
        # The two parts are separated by a space.
        #
        # If the data type of the column is not CHAR or VARCHAR, a binary
        # representation is encoded in the default column. 

        if($sd_row->{'type'} eq 'T')
        {
          $col_info->{'COLUMN_DEF'} = 'today';
        }
        elsif($sd_row->{'type'} eq 'C')
        {
          $col_info->{'COLUMN_DEF'} = 'current';
        }
        elsif($sd_row->{'type'} eq 'L')
        {
          if($col_info->{'informix_type_num'} == CHAR)
          {
            $col_info->{'COLUMN_DEF'} = $sd_row->{'default'};
          }
          else
          {
            # The first part is the 6-bit representation of the binary value
            # of the default-value structure. The second part is the default
            # value in English text. The two parts are separated by a space.
            my $default = $sd_row->{'default'};
            $default =~ s/^.+ //; # cheat by just looking for the space

            $col_info->{'COLUMN_DEF'} = $default;
          }
        }
      }

      # Finally, generate the columns based on the DBI-like $col_info
      # that we built in the previous steps.

      foreach my $col_info (values %col_info)
      {
        $db->refine_dbi_column_info($col_info);

        $columns{$col_info->{'COLUMN_NAME'}} = 
          $self->auto_generate_column($col_info->{'COLUMN_NAME'}, $col_info);
      }
    };

    $error = $@;
  }

  if($error || !keys %columns)
  {
    Carp::croak "Could not auto-generate columns for class $class - $error";
  }

  $self->auto_alias_columns(values %columns);

  return wantarray ? values %columns : \%columns;
}

sub auto_generate_unique_keys
{
  my($self) = shift;

  unless(defined wantarray)
  {
    Carp::croak "Useless call to auto_generate_unique_keys() in void context";
  }

  my($class, %unique_keys, $error);

  TRY:
  {
    local $@;

    eval
    {
      require DBD::Informix::Metadata;

      $class = $self->class or die "Missing class!";

      my $db  = $self->db;  
      my $dbh = $db->dbh or die $db->error;

      local $dbh->{'FetchHashKeyName'} = 'NAME';

      # We need the table id.  To get it, we need the "owner" name.  Asking
      # for column information is the only way I know of to reliably get
      # this information.
      #
      # Informix does not support DBI's column_info() method so we have
      # to get all that into "the hard way."
      #
      # Each item in @col_list is a reference to an array of values:
      #
      #   0     owner name
      #   1     table name
      #   2     column number
      #   3     column name
      #   4     data type (encoded)
      #   5     data length (encoded)
      #
      my @col_list = DBD::Informix::Metadata::ix_columns($dbh, lc $self->table);

      # Here's the query for the table id
      my $st_sth = $dbh->prepare(<<"EOF");
SELECT tabid FROM informix.systables WHERE tabname = ? AND owner = ?
EOF

      # Take the info from the first column (arbitrarily selected)
      #                table name       owner name
      $st_sth->execute($col_list[0][1], $col_list[0][0]);
      my $table_id = $st_sth->fetchrow_array;

      unless(defined $table_id)
      {
        die "Could not find informix.systables record for table ",
            "'$col_list[0][1]' with owner '$col_list[0][0]'";
      }

      # Then comes this monster query to get the unique key column names.
      # (The subquery filters out any primary keys.) I'd love to know a
      # better/easier way to do this...
      my $uk_sth = $dbh->prepare(<<'EOF');
SELECT
  col.colname,
  idx.idxname
FROM
  informix.sysindexes idx, 
  informix.syscolumns col
WHERE
  idx.tabid   = ?   AND 
  idx.idxtype = 'U' AND 
  idx.tabid   = col.tabid
  AND 
  (
    col.colno = idx.part1 OR
    col.colno = idx.part2 OR
    col.colno = idx.part3 OR
    col.colno = idx.part4 OR
    col.colno = idx.part5 OR
    col.colno = idx.part6 OR
    col.colno = idx.part7 OR
    col.colno = idx.part8 OR
    col.colno = idx.part9 OR
    col.colno = idx.part10 OR
    col.colno = idx.part11 OR
    col.colno = idx.part12 OR
    col.colno = idx.part13 OR
    col.colno = idx.part14 OR
    col.colno = idx.part15 OR
    col.colno = idx.part16
  )
  AND NOT EXISTS
  (
    SELECT * FROM
      informix.sysconstraints con
    WHERE
      con.tabid      = ?   AND
      con.constrtype = 'P' AND
      con.idxname    = idx.idxname
  );
EOF

      $uk_sth->execute($table_id, $table_id);

      my($column, $key);

      $uk_sth->bind_columns(\$column, \$key);

      while($uk_sth->fetch)
      {
        my $uk = $unique_keys{$key} ||= 
          Rose::DB::Object::Metadata::UniqueKey->new(name => $key, parent => $self);

        $uk->add_column($column);
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
  my @uk = map { $unique_keys{$_} } sort map { lc } keys(%unique_keys);

  return wantarray ? @uk : \@uk;
}

use constant FK_INDEXES_SQL =><<'EOF';
SELECT
    c1.constrname   referring_constraint_name,
    c1.owner        referring_constraint_owner,
    c1.idxname      referring_index_name,
    t2.tabid        referring_table_id,
    t2.owner        referring_table_owner,
    t2.tabname      referring_table_name,
    c2.constrname   referred_constraint_name,
    c2.owner        referred_constraint_owner,
    c2.idxname      referred_index_name,
    t1.tabid        referred_table_id,
    t1.owner        referred_table_owner,
    t1.tabname      referred_table_name
FROM
    informix.sysreferences   r,
    informix.sysconstraints c1,
    informix.sysconstraints c2,
    informix.systables      t1,
    informix.systables      t2
WHERE
    c1.constrtype = 'R'       AND
    c1.tabid = t2.tabid       AND
    c1.constrid = r.constrid  AND
    r.ptabid = t1.tabid       AND
    r.primary = c2.constrid   AND
    t2.tabid = ?
EOF

use constant INDEX_COLUMNS_SQL =><<'EOF';
SELECT
    tabname,
    idxname,
    c1.colname  col1,
    c2.colname  col2,
    c3.colname  col3,
    c4.colname  col4,
    c5.colname  col5,
    c6.colname  col6,
    c7.colname  col7,
    c8.colname  col8,
    c9.colname  col9,
    c10.colname col10,
    c11.colname col11,
    c12.colname col12,
    c13.colname col13,
    c14.colname col14,
    c15.colname col15,
    c16.colname col16
FROM
    informix.systables        t,
    informix.syscolumns       c1,
    OUTER(informix.syscolumns c2),
    OUTER(informix.syscolumns c3),
    OUTER(informix.syscolumns c4),
    OUTER(informix.syscolumns c5),
    OUTER(informix.syscolumns c6),
    OUTER(informix.syscolumns c7),
    OUTER(informix.syscolumns c8),
    OUTER(informix.syscolumns c9),
    OUTER(informix.syscolumns c10),
    OUTER(informix.syscolumns c11),
    OUTER(informix.syscolumns c12),
    OUTER(informix.syscolumns c13),
    OUTER(informix.syscolumns c14),
    OUTER(informix.syscolumns c15),
    OUTER(informix.syscolumns c16),
    informix.sysindexes       i
WHERE
    t.tabtype = 'T'       AND
    t.tabid = i.tabid     AND
    i.tabid = c1.tabid    AND
    i.tabid = c2.tabid    AND
    i.tabid = c3.tabid    AND
    i.tabid = c4.tabid    AND
    i.tabid = c5.tabid    AND
    i.tabid = c6.tabid    AND
    i.tabid = c7.tabid    AND
    i.tabid = c8.tabid    AND
    i.tabid = c9.tabid    AND
    i.tabid = c10.tabid   AND
    i.tabid = c11.tabid   AND
    i.tabid = c12.tabid   AND
    i.tabid = c13.tabid   AND
    i.tabid = c14.tabid   AND
    i.tabid = c15.tabid   AND
    i.tabid = c16.tabid   AND
    part1 = c1.colno      AND
    part2 = c2.colno      AND
    part3 = c3.colno      AND
    part4 = c4.colno      AND
    part5 = c5.colno      AND
    part6 = c6.colno      AND
    part7 = c7.colno      AND
    part8 = c8.colno      AND
    part9 = c9.colno      AND
    part10 = c10.colno    AND
    part11 = c11.colno    AND
    part12 = c12.colno    AND
    part13 = c13.colno    AND
    part14 = c14.colno    AND
    part15 = c15.colno    AND
    part16 = c16.colno    AND
    t.tabid = ?           AND
    i.idxname = ?
ORDER BY
    idxname
EOF

sub auto_generate_foreign_keys
{
  my($self, %args) = @_;

  unless(defined wantarray)
  {
    Carp::croak "Useless call to auto_generate_foreign_keys() in void context";
  }

  my $no_warnings = $args{'no_warnings'};

  my($class, @foreign_keys, $total_fks, $error);

  TRY:
  {
    local $@;

    eval
    {
      $class = $self->class or die "Missing class!";

      my $db  = $self->db;
      my $dbh = $db->dbh or die $db->error;

      local $dbh->{'FetchHashKeyName'} = 'NAME';

      # I'm doing this to get the table id and owner.  Gotta be a better way...
      my @col_list = DBD::Informix::Metadata::ix_columns($dbh, lc $self->table);

      my $st_sth = $dbh->prepare(<<"EOF");
SELECT tabid FROM informix.systables WHERE tabname = ? AND owner = ?
EOF
      # Each item in @col_list is a reference to an array of values:
      #
      #   0     owner name
      #   1     table name
      #   2     column number
      #   3     column name
      #   4     data type (encoded)
      #   5     data length (encoded)
      #
      my $table_name = $col_list[0][1];
      my $owner_name = $col_list[0][0];

      $st_sth->execute($table_name, $owner_name);

      my $table_id = $st_sth->fetchrow_array;

      my $col_sth = $dbh->prepare(INDEX_COLUMNS_SQL);

      my $sth = $dbh->prepare(FK_INDEXES_SQL);    
      $sth->execute($table_id);

      my %fk;

      my $cm = $self->convention_manager;

      FK: while(my $index_info = $sth->fetchrow_hashref)
      {
        # Sanity check - should never happen
        unless(lc $self->table eq lc $index_info->{'referring_table_name'} &&
               lc $owner_name eq lc $index_info->{'referring_table_owner'})
        {
          Carp::confess
            "Fatal mismatch between table ('", lc $self->table, "' vs. '",
            lc $index_info->{'referring_table_name'}, "' and/or owner ('",
            lc $owner_name, "' vs. '", lc $index_info->{'referring_table_owner'},
            "')";
        }

        my $key_name      = $index_info->{'referring_index_name'};
        my $foreign_table = $index_info->{'referred_table_name'};

        # Get local columns
        $col_sth->execute(@$index_info{qw(referring_table_id referring_index_name)});

        my $local_cols_info = $col_sth->fetchrow_hashref;
        my @local_cols = grep { defined && /\S/ } @$local_cols_info{map { "col$_" } 1 .. 16};

        # Get foreign columns
        $col_sth->execute(@$index_info{qw(referred_table_id referred_index_name)});

        my $foreign_cols_info = $col_sth->fetchrow_hashref;
        my @foreign_cols = grep { defined && /\S/ } @$foreign_cols_info{map { "col$_" } 1 .. 16};

        # Another sanity check - should never happen
        unless(@local_cols > 0 && @local_cols == @foreign_cols)
        {
          Carp::confess "Failed to extract matching sets of foreign key ",
                        "columns for table $table_name";
        }

        my $foreign_class = $self->class_for(table => $foreign_table);

        unless($foreign_class)
        {
          # Add deferred task
          $self->add_deferred_task(
          {
            class  => $self->class, 
            method => 'auto_init_foreign_keys',
            args   => \%args,

            code   => sub
            {
              $self->auto_init_foreign_keys(%args);
              $self->make_foreign_key_methods(%args, preserve_existing => 1);
            },

            check  => sub
            {
              my $fks = $self->foreign_keys;
              return @$fks == $total_fks ? 1 : 0;
            }
          });

          unless($no_warnings || $self->allow_auto_initialization)
          {
            no warnings; # Allow undef coercion to empty string
            warn "No Rose::DB::Object-derived class found for table ",
                 "'$foreign_table'";
          }

          $total_fks++;
          next FK;
        }

        my %key_columns;
        @key_columns{@local_cols} = @foreign_cols;

        my $fk = 
          Rose::DB::Object::Metadata::ForeignKey->new(
            name        => $key_name,
            class       => $foreign_class,
            key_columns => \%key_columns);

        push(@foreign_keys, $fk);
        $total_fks++;
      }

      # This step is important!  It ensures that foreign keys will be created
      # in a deterministic order, which in turn allows the "auto-naming" of
      # foreign keys to work in a predictable manner.  This exact sort order
      # (lowercase table name comparisons) is part of the API for foreign
      # key auto generation.
      @foreign_keys = 
        sort { lc $a->class->meta->table cmp lc $b->class->meta->table } 
        @foreign_keys;

      my %used_names;

      foreach my $fk (@foreign_keys)
      {
        my $name =
          $cm->auto_foreign_key_name($fk->class, $fk->name, scalar $fk->key_columns, \%used_names);

        unless(defined $name)
        {
          $fk->name($name = $self->foreign_key_name_generator->($self, $fk));
        }

        unless(defined $name && $name =~ /^\w+$/)
        {
          die "Missing or invalid key name '$name' for foreign key ",
              "generated in $class for ", $fk->class;
        }

        $used_names{$name}++;

        $fk->name($name);
      }
    };

    $error = $@;
  }

  if($error)
  {
    Carp::croak "Could not auto-generate foreign keys for class $class - $error";
  }

  @foreign_keys = sort { lc $a->name cmp lc $b->name } @foreign_keys;

  return wantarray ? @foreign_keys : \@foreign_keys;
}

#
# Crazy Informix helper functions
#

# Helper functions from $INFORMIXDIR/etc/xpg4_is.sql
# http://www-306.ibm.com/software/data/informix/pubs/library/datablade/dbdk/sqlr/01.fm50.html
#
# In call cases, the "coltype" argument is replaces with the already-
# adjusted $type_num, so ignore the subtraction of 256 in all of the
# pasted code.

# create procedure 'informix'.ansinumprec(coltype smallint, collength smallint)
# returning int;
# 
#         { FLOAT and SMALLFLOAT precisions are in bits }
# 
#         if (coltype >= 256) then
#             let coltype = coltype - 256;
#         end if;
# 
#         if (coltype = 1) then                           -- smallint
#             return 5;
#         elif (coltype = 2) or (coltype = 6) then        -- int
#             return 10;
#         elif (coltype = 3) then                         -- float
#             return 64;
#         elif (coltype = 4) then                         -- smallfloat
#             return 32;
#         elif (coltype = 5) or (coltype = 8) then        -- decimal
#             return (trunc(collength / 256));
#         else
#             return NULL;
#         end if;
# end procedure
# document
#         'returns the precision of a numeric column',
#         'Synopsis: ansinumprec(smallint, smallint) returns int';

sub _ix_numeric_precision
{
  my($type_num, $collength) = @_;

  if(exists $Numeric_Precision{$type_num})
  {
    return $Numeric_Precision{$type_num};
  }

  if($type_num == DECIMAL || $type_num == MONEY)
  {
    return int($collength / 256);
  }

  return undef;
}

# create procedure 'informix'.ansinumscale(coltype smallint, collength smallint)
# returning int;
# 
#   if (coltype >= 256) then
#       let coltype = coltype - 256;
#   end if;
# 
#   if (coltype = 1) or (coltype = 2) or 
#      (coltype = 6) then
#       return 0;
#   elif (coltype = 5) or (coltype = 8) then
#       return (collength - ((trunc(collength / 256))*256));
#   else
#       return NULL;
#   end if;
# end procedure
# document
#   'returns the scale of a numeric column',
#   'Synopsis: ansinumscale(smallint, smallint) returns int';

sub _ix_numeric_scale
{
  my($type_num, $collength) = @_;

  if($type_num == SMALLINT || $type_num == INTEGER ||
     $type_num == SERIAL)
  {
    return 0;
  }

  if($type_num == DECIMAL || $type_num == MONEY)
  {
    return $collength - ((int($collength / 256)) * 256);
  }

  return undef;
}

# create procedure 'informix'.ansinumprecradix( coltype smallint)
# returning int;
# 
#   if (coltype >= 256) then
#       let coltype = coltype - 256;
#   end if;
# 
#   if (coltype = 1) or (coltype = 2) or 
#      (coltype = 5) or (coltype = 6) or
#      (coltype = 8) then
#       return 10;
#   elif (coltype = 3) or (coltype = 4) then
#       return 2;
#   else
#       return NULL;
#   end if;
# end procedure
# document
#   'returns the precision radix of a numeric column',
#   'Synopsis: ansinumprecradix(smallint) returns int';

sub _ix_numeric_precision_radix
{
  my($type_num, $collength) = @_;

  if($type_num == SMALLINT || $type_num == INTEGER ||
     $type_num == DECIMAL  || $type_num == SERIAL  ||
     $type_num == MONEY)
  {
    return 10;
  }

  if($type_num == FLOAT || $type_num == SMALLFLOAT)
  {
    return 2;
  }

  return undef;
}

# create procedure 'informix'.ansimaxlen(coltype smallint, collength smallint)
# returning int;
# 
#         if (coltype >= 256) then
#             let coltype = coltype - 256;
#         end if;
# 
#         if (coltype = 0) then
#             return collength;
#         elif (coltype = 13) or (coltype = 16) then
#             return (collength - (trunc(collength / 256))*256);
#         else
#             return NULL;
#         end if;
# end procedure
# document
#         'returns the maximum length of character oriented column',
#         'Synopsis: ansimaxlen(smallint, smallint) returns int';

sub _ix_max_length
{
  my($type_num, $collength) = @_;

  if($type_num == CHAR)
  {
    return $collength;
  }

  if($type_num == VARCHAR || $type_num == NVARCHAR)
  {
    return $collength - (int($collength / 256)) * 256;
  }

  return undef;
}

# create procedure 'informix'.ansidatprec(coltype smallint, collength smallint)
# returning int;
# 
#   { if the column is nullable then coltype = coltype+256 }
# 
#   if (coltype = 7 or coltype = 263) then
#       return 0;
#   elif (coltype = 10 or coltype = 266) then
#       let collength = collength - 16*trunc(collength/16) - 10;
#       if (collength > 0) then
#       return collength;
#       else
#       return 0;
#       end if;
#   else
#       return NULL;
#   end if;
# end procedure
# document
#   'returns the date precision for a datetime column',
#   'Synopsis: ansidatprec(smallint, smallint) returns int';

# Don't seem to need this...
# sub _ix_datetime_precision
# {
#   my($type_num, $collength) = @_;
#   
#   if($type_num == DATE)
#   {
#     return 0;
#   }
#   
#   if($type_num == DATETIME)
#   {
#     $collength = $collength - (16 * int($collength / 16)) - 10;
#     
#     if($collength > 0)
#     {
#       return $collength;
#     }
#     
#     return 0;
#   }
#   
#   return undef;
# }

# For columns of type DATETIME or INTERVAL, collength is determined using
# the following formula:
# 
# (length * 256) + (largest_qualifier_value * 16) + smallest_qualifier_value
# 
# The length is the physical length of the DATETIME or INTERVAL field, and
# largest_qualifier and smallest_qualifier have the values shown in the
# following table.
#
# Field Qualifier   Value
# YEAR                 0
# MONTH                2
# DAY                  4
# HOUR                 6
# MINUTE               8
# SECOND              10
# FRACTION(1)         11
# FRACTION(2)         12
# FRACTION(3)         13
# FRACTION(4)         14
# FRACTION(5)         15
#
# For example, if a DATETIME YEAR TO MINUTE column has a length of 12
# (such as YYYY:DD:MM:HH:MM), a largest_qualifier value of 0 (for YEAR),
# and a smallest_qualifier value of 8 (for MINUTE), the collength value is
# 3080, or (256 * 12) + (0 * 16) + 8.
#
# The above is all just a fancy way of saying:
#
# largest_qualifier_value  = (collength & 0xF0) >> 4
# smallest_qualifier_value = collength & 0xF
#

sub _ix_datetime_specific_type
{
  my($meta, $type_num, $collength, $col_info) = @_;

  return  unless($type_num == DATETIME);

  my $largest_qualifier  = ($collength & 0xF0) >> 4;
  my $smallest_qualifier = $collength & 0xF;

  unless(exists $Datetime_Qualifiers{$largest_qualifier} &&
         exists $Datetime_Qualifiers{$smallest_qualifier})
  {
    die "No datetime qualifier(s) found for collength $collength";
  }

  # Handle DATETIME HOUR TO (MINUTE|SECOND|FRACTION(1-5)) as a "time" column.
  if($largest_qualifier == $Datetime_Qualifiers_Reverse{'hour'} &&
     ($smallest_qualifier == $Datetime_Qualifiers_Reverse{'minute'} ||
      $smallest_qualifier == $Datetime_Qualifiers_Reverse{'second'} ||
      ($smallest_qualifier >= MIN_DATETIME_FRACTION && 
       $smallest_qualifier <= MAX_DATETIME_FRACTION)))
  {
    if($smallest_qualifier >= MIN_DATETIME_FRACTION && 
       $smallest_qualifier <= MAX_DATETIME_FRACTION)
    {
      $col_info->{'TIME_SCALE'} = $smallest_qualifier - FRACTION_SCALE_DELTA;
    }
    else
    {
      delete $col_info->{'TIME_SCALE'};

      if($smallest_qualifier == $Datetime_Qualifiers_Reverse{'minute'})
      {
        $col_info->{'TIME_PRECISION'} = 4; # HH:MM
      }
    }

    return 'time';
  }

  my $type = "datetime $Datetime_Qualifiers{$largest_qualifier} to $Datetime_Qualifiers{$smallest_qualifier}";

  # Punt on unsupported datetime column granularities
  unless($meta->column_type_class($type))
  {
    return 'scalar';
  }

  return $type;
}

1;
