=head1 NAME

SQLite::VirtualTable::Pivot -- use SQLite's virtual tables to represent pivot tables.

=head1 SYNOPSIS

 $ export SQLITE_CURRENT_DB=/tmp/foo.db
 sqlite3 $SQLITE_CURRENT_DB
 sqlite> .load perlvtab.so
 sqlite> create table object_attributes (id integer, name varchar, value integer);
 sqlite> insert into object_attributes values ( 1, "length", 20 );
 sqlite> insert into object_attributes values ( 1, "color", "red" );
 sqlite> create virtual table object_pivot using perl
           ("SQLite::VirtualTable::Pivot", "object_attributes" );
 sqlite> select * from object_pivot;
    id|color|length
    1|red|20

=head1 DESCRIPTION

A pivot table is a table in which the distinct row values of a column
in one table are used as the names of the columns in another table.

Here's an example:

Given this table :

 Student Subject    Grade
 ------- -------    -----
 Joe     Reading    A
 Joe     Writing    B
 Joe     Arithmetic C
 Mary    Reading    B-
 Mary    Writing    A+
 Mary    Arithmetic C+

A pivot table created using the columns "Student" and "Subject"
and the value "Grade" would yield :

 Student Arithmetic Reading Writing
 ------- ---------- ------- ----------
 Joe     C          A       B
 Mary    C+         B-      A+

To create a table, use the following syntax :

    create virtual table object_pivot using perl
               ("SQLite::VirtualTable::Pivot", "base_table" );

To specify the three columns, use :

    create virtual table object_pivot using perl
               ("SQLite::VirtualTable::Pivot", "base_table",
                "pivot_row", "pivot_column", "pivot_value" );

where pivot_row, pivot_column and pivot_value are three columns
in the base_table.  The distinct values of pivot_column will be
the names of the new columns in the pivot table.  (The values may
be sanitized to create valid column names.)

If any of the three columns are foreign keys, these may be
collapsed in the pivot table, as described below.

The list of distinct columns is calculated the first
time a pivot table is used (or created) in a database session.
So, if the list changes, you may need to re-connect.

=head1 Entity-Atribute-Value models

The Entity-Attribute-Value model is a representation of data in
a table containing three columns representing an entity, an attribute,
and a value.  For instance :

 Entity Attribute Value
 ------ --------- -----
 1       color    red
 1       length   20
 2       color    blue

To reduce redundancy or to constrain the possible attributes/values,
some or all of the three columns may be foreign keys.  Consider for
instance, the following :

    create table entities (
         id integer primary key,
         entity varchar, 
         unique (entity) );

    create table attributes (
        id integer primary key,
        attribute varchar,
        unique (attribute) );

    create table value_s (
        id integer primary key,
        value integer, -- nb: "integer" is only the column affinity
        unique (value) );

    create table eav (
        entity    integer references entities(id),
        attribute integer references attributes(id),
        value     integer references value_s(id),
        primary key (entity,attribute)
    );

Then the foreign keys may be "flattened" into the pivot table
by using this SQL :

 create virtual table
     eav_pivot using perl ("SQLite::VirtualTable::Pivot",
        "eav",
        "entity->entity(id).entity",
        "attribute->attributes(id).attribute",
        "value->value_s(id).value"
        );

Then the columns in eav_pivot would be the entries in
attributes.attribute corresponding to the distinct
values in eav.attribute.

Moreover, queries against the pivot table will do the right
thing, in the sense that restrictions will use the values in the
value_s table, not in the eav table.

=head1 EXAMPLE 

 create table students (student, subject, grade, primary key (student,subject)); 
 insert into students values ("Joe", "Reading", "A");
 insert into students values ("Joe", "Writing", "B");
 insert into students values ("Joe", "Arithmetic", "C");
 insert into students values ("Mary", "Reading", "B-");
 insert into students values ("Mary", "Writing", "A+");
 insert into students values ("Mary", "Arithmetic", "C+");

 select load_extension("perlvtab.so");
 create virtual table roster using perl ("SQLite::VirtualTable::Pivot", "students", "student", "subject", "grade");
 select * from roster;

 Student Reading Writing Arithmetic
 ------- ------- ------- ----------
 Joe     A       B       C
 Mary    B-      A+      C+

 select student from roster where writing = "A+";
 Mary

=head1 FUNCTIONS (called by sqlite, see SQLite::VirtualTable)

=cut

package SQLite::VirtualTable::Pivot;

# from CPAN
use DBI;
use DBIx::Simple;
use Data::Dumper;
use Scalar::Util qw/looks_like_number/;
use SQLite::VirtualTable::Util qw/unescape/;

# base modules
use base 'SQLite::VirtualTable';
use base 'Class::Accessor::Contextual';

# local module
use SQLite::VirtualTable::Pivot::Cursor;
use strict;

our $VERSION = 0.02;

# Create r/w accessors for everything that we store in the class hash
__PACKAGE__->mk_accessors(qw| table     |); # base_table name and distinct values
__PACKAGE__->mk_accessors(qw| columns   |); # distinct values in base_table.$pivot_row
__PACKAGE__->mk_accessors(qw| vcolumns  |); # valid column names based on the above
__PACKAGE__->mk_accessors(qw| indexes counts |);  # populated by BEST_INDEX, used by FILTER
__PACKAGE__->mk_accessors(qw| pivot_row    pivot_row_ref    |); # entity (in EAV) + fk info
__PACKAGE__->mk_accessors(qw| pivot_column pivot_column_ref |); # attribute + fk info
__PACKAGE__->mk_accessors(qw| pivot_value  pivot_value_ref  |); # value + fk info
__PACKAGE__->mk_accessors(qw| pivot_row_type                |); # column affinity for entity

# We need to use an env variable until DBD::SQLite + SQLite::VirtualTable
# work together to pass one to CREATE()
our $dbfile = $ENV{SQLITE_CURRENT_DB} or die "please set SQLITE_CURRENT_DB";
our $db;  # handle: DBIx::Simple object

# debug setup
#$ENV{TRACE} = 1;
#$ENV{DEBUG} = 1;
sub debug($)  { return unless $ENV{DEBUG}; print STDERR "# $_[0]\n"; }
sub trace($)  { return unless $ENV{TRACE}; print STDERR "# $_[0]\n"; }

# Initialize the database handle.  Send force => 1 to force a reconnect
sub _init_db {
    my %args = @_;
    our $db;
    return if defined($db) && !$args{force};
    debug "connect to $dbfile";
    $db = DBIx::Simple->connect( "dbi:SQLite:dbname=$dbfile", "", "" )
      or die DBIx::Simple->error;
    $db->dbh->do("PRAGMA temp_store = 2"); # use in-memory temp tables
}

# Parse the string indicating a foreign key relationship in the base_table.
# Given  "entity->entity_ref(id).value",
# return ("entity" , { table=>"entity_ref", child_key => "id", child_label => "value"} ).
sub _parse_refspec {
    my $str = shift;
    $str =~ /^(.*)->(.*)\((.*)\)\.(.*)$/
      and return ( $1, { table => $2, child_key => $3, child_label => $4 } );
    return $str;
}

=head1 CREATE (constructor)

Arguments :
    module : "perl",
    caller : "main"
    virtual_table : the name of the table being created
    base_table    : the table being pivoted
    @pivot_columns (optional) : entity, attribute, value

Returns :
    A new SQLite::VirtualTable::Pivot object.

Description :
 Create a new SQLite::VirtualTable::Pivot object.  The base_table
 is the table to be pivoted.  If this table contains only three
 columns, then they will be used in order as the pivot_row,
 pivot_column, and pivot_value columns (aka entity, attribute, value).
 Alternatively, these columns may be specified in the create
 statement by passing them as parameters.  If one of the values
 is a foreign key and the pivot table should instead use a column
 in the child table, that may be specified using the following
 notation :

    base_table_column->child_table(child_key).child_column_to_use

 If a column name contains a space, then the portion after the
 space should be the column affinity.

Examples :

   CREATE VIRTUAL TABLE pivot_table USING perl
      ("SQLite::VirtualTable::Pivot","base_table" );

   CREATE VIRTUAL TABLE pivot_table USING perl
      ("SQLite::VirtualTable::Pivot","base_table",
      "entity","attribute","value");

   CREATE VIRTUAL TABLE pivot_table USING perl
      ("SQLite::VirtualTable::Pivot","base_table",
      "entity integer","attribute varchar","value integer");

   CREATE VIRTUAL TABLE pivot_table USING perl
      ("SQLite::VirtualTable::Pivot","base_table",
        "entty",
        "attribute->attribute_lookup(id).attr",
        "value->value_lookup(id).value" );
=cut

sub CREATE {
    my ( $class, $module, $caller, $virtual_table, $base_table, @pivot_columns ) = @_;
    trace "(CREATE, got @_)";

    # connect
    _init_db();

    # Get the base_table and its metadata.  Parse the sql used to create it.
    $base_table = unescape($base_table);
    my ($createsql) =
      $db->select( 'sqlite_master', ['sql'], { name => $base_table } )->list
      or die "Could not find table '$base_table' " . $db->error;
    $createsql =~ s/^[^\(]*\(//; # remove leading
    $createsql =~ s/\)[^\)]*$//; # and trailing "CREATE" declaration, to get columns
    my @columns_and_contraints = split /,/, $createsql;

    # Set up the pivot_row (entity), pivot_column (attribute) and
    # pivot_value (value) columns, including foreign key specifications.
    my ($pivot_row, $pivot_row_type, $pivot_column, $pivot_value );
    my ($pivot_row_ref, $pivot_column_ref, $pivot_value_ref);
    if (@pivot_columns == 3) {
        ($pivot_row, $pivot_column, $pivot_value ) = map unescape($_), @pivot_columns;
        if ($pivot_row =~ / /) {
            ($pivot_row,$pivot_row_type) = split / /, $pivot_row;
        }
        ($pivot_row   ,$pivot_row_ref)    = _parse_refspec($pivot_row);
        ($pivot_column,$pivot_column_ref) = _parse_refspec($pivot_column);
        ($pivot_value ,$pivot_value_ref)  = _parse_refspec($pivot_value);
    } else {
        ($pivot_row, $pivot_column, $pivot_value ) = @columns_and_contraints;
        ($pivot_row_type) = $pivot_row =~ /^\s*\S* (.*)$/;
    }
    for my $col ($pivot_row, $pivot_column, $pivot_value ) {
        $col =~ s/^\s*//;
        $col =~ s/ .*$//;
        next if grep /$col/i, @columns_and_contraints;
        warn "could not find $col in columns for $base_table\n";
    }

    # Now compute the distinct values of pivot_row (attribute).
    debug "pivot_column (attribute) is $pivot_column";
    my @columns = (
        $pivot_row,
        $db->query( sprintf(
                "SELECT DISTINCT(%s) FROM %s",
                $pivot_column, $base_table))->flat
    );
    debug "distinct values for $pivot_column in $base_table are @columns";

    my @vcolumns = @columns;  # virtual table column names

    # Maybe apply foreign key transform to make vcolumns.
    if ($pivot_column_ref) {
        @vcolumns = ($vcolumns[0]);
        for my $c (@columns) {
            my ($next) = $db->select(
                $pivot_column_ref->{table},
                $pivot_column_ref->{child_label},
                { $pivot_column_ref->{child_key} => $c }
              )->flat or next;
            push @vcolumns, $next;
        }
    }
    # Ensure that they are valid sqlite column names
    for (@vcolumns) {
        tr/a-zA-Z0-9_//dc;
        $_ = "$pivot_column\_$_" unless $_=~/^[a-zA-Z]/;
    }

    $pivot_row_type ||= "varchar"; # default entity type
    bless {
        name           => $virtual_table,  # the virtual pivot table name
        table          => $base_table,    # the base table name
        columns        => \@columns,       # the base table distinct(pivot_column) values
        vcolumns       => \@vcolumns,      # the names of the virtual pivot table columns
        pivot_row      => $pivot_row,      # the name of the "pivot row" column in the base table
        pivot_row_type => $pivot_row_type, # the column affinity for the pivot row
        pivot_row_ref  => $pivot_row_ref,  # hash (see _parse_refspec)
        pivot_column   => $pivot_column,   # the name of the "pivot column" column in the base table
        pivot_column_ref => $pivot_column_ref,  # hash (see _parse_refspec)
        pivot_value      => $pivot_value,     # the name of the "pivot value" column in the base table
        pivot_value_ref  => $pivot_value_ref, # hash (see _parse_refspec)
    }, $class;
}
*CONNECT = \&CREATE;

=over

=item DECLARE_SQL

Arguments: none
Returns: a CREATE TABLE statement that specifies the columns of
the virtual table.

=cut

sub DECLARE_SQL {
    trace "DECLARE_SQL";
    my $self = shift;
    return sprintf "CREATE TABLE %s (%s)", $self->table, join ',', $self->vcolumns;
}

# Map from incoming operators to sql operators
our %OpMap = ( 'eq' => '=',  'lt' => '<',  'gt'    => '>',
               'ge' => '>=', 'le' => '<=', 'match' => 'like',);

# Create a new temporary table and return its name.
sub _new_temp_table {
    my ($count) = $db->select('sqlite_temp_master','count(1)')->list;
    debug "made temp table number ".($count + 1 );
    return sprintf("temp_%d_%d",$count + 1,$$);
}

# Generate and run a query using information created during BEST_INDEX
# calls.  This is called during a FILTER call.
#
# Arguments :
#  cursor : an SQLite::VirtualTable::Pivot::Cursor object
#  constraints : an array ref of hashrefs whose keys are :
#                column_name - the name of the column
#                operator - one of the keys of %OpMap above
#  bind : an arrayref of bind values, one per constraint.
# 
sub _do_query {
    my ($self, $cursor, $constraints, $args) = @_;
    my @values = @$args; # bind values for constraints
    my $ref = $self->pivot_value_ref;
    # Set up join clauses and table in case the value is a foreign key.
    my $join_clause = sprintf(
        " INNER JOIN %s ON %s.%s=%s.%s ",
        #e.g. " INNER JOIN value_s ON value_s.id=eav.value ";
        $ref->{table}, $ref->{table}, $ref->{child_key},
        $self->table,  $ref->{child_label}
    ) if $self->pivot_row_ref;
    my $value_table = $ref->{table} || $self->table;
    my $value_column = $ref->{child_label} || $self->pivot_column;
    for my $constraint (@$constraints) {
        my $value = shift @values;
        my $temp_table = _new_temp_table();
        push @{ $cursor->temp_tables }, $temp_table;
        debug "creating temporary table $temp_table ";
        my $key = $self->pivot_row_type =~ /int/i ? " INTEGER PRIMARY KEY" : "";
        $db->query( sprintf("CREATE TEMPORARY TABLE %s (%s $key)",
                             $temp_table, $self->pivot_row)
                  ) or die $db->error;

        my ($query,@bind);
        if ($constraint->{column_name} eq $self->pivot_row) {
            $query = sprintf( "INSERT INTO %s SELECT DISTINCT(%s) FROM %s WHERE %s %s ?",
                $temp_table, $self->pivot_row, $self->table, $self->pivot_row, $OpMap{$constraint->{operator}} );
            @bind = ($value);
        } else {
            $query = sprintf( "INSERT INTO %s SELECT %s FROM %s %s WHERE %s = ? AND %s.%s %s ?",
                             $temp_table,
                             $self->pivot_row,
                             $self->table, $join_clause,
                             $self->pivot_column, 
                             $value_table, $self->pivot_value, $OpMap{$constraint->{operator}});
            @bind = ( $constraint->{column_name}, $value);
        }
        debug "ready to run $query with @bind";
        $db->query($query, @bind ) or die $db->error;

        debug ("temp table $temp_table is for $constraint->{column_name} $constraint->{operator} $value");
        #info ("temp table $temp_table has : ".join ",", $db->select($temp_table,"*")->list);
    }
    debug "created ".scalar @{ $cursor->temp_tables }." temp table(s)";

    # Now we have created the temp tables, join them together to make the final query.

    my $value_table_or_a = $self->pivot_value_ref ? $self->pivot_value_ref->{table} : 'a';
    my $sql = sprintf( "SELECT a.%s, %s, %s.%s AS %s FROM %s a",
                        $self->pivot_row,    # == entity
                        $self->pivot_column, # == attribute
                        $value_table_or_a,
                        (     $self->pivot_value_ref
                            ? $self->pivot_value_ref->{child_label}
                            : $self->pivot_value ),
                        $self->pivot_value,
                        $self->table); 

    $sql .= sprintf(" INNER JOIN %s ON a.%s = %s.id ",
        $value_table_or_a, $self->pivot_value, $value_table_or_a ) if $self->pivot_value_ref;

    for my $temp_table ($cursor->temp_tables) {
        $sql .= sprintf( " INNER JOIN %s ON %s.%s=a.%s ",
            $temp_table,      $temp_table,
            $self->pivot_row, $self->pivot_row
        );
    }
    $sql .= sprintf(" ORDER BY a.%s", $self->pivot_row);

    # TODO move into cursor.pm
    my (@current_row);
    $cursor->reset;
    $cursor->{sth} = $db->dbh->prepare( $sql) or die "error in $sql : $DBI::errstr";
    $cursor->sth->execute or die $DBI::errstr;
    $cursor->set( "last" => !( @current_row = $cursor->sth->fetchrow_array ) );
    $cursor->set( current_row => \@current_row );
    debug "ran query, first row is : @current_row";
}

=item OPEN

Create and return a new cursor.
This returns a new SQLite::VirtualTable::Pivot::Cursor object.

This is called before BEST_INDEX or FILTER, just to create the
new empty object.

=cut

sub OPEN {
    my $self = shift;
    trace "(OPEN $self->{name})";
    return SQLite::VirtualTable::Pivot::Cursor->new({virtual_table => $self})->reset;
}

=item BEST_INDEX

Given a set of constraints and an order, return the name
(and number) of the best index that should be used to
run this query, and the cost of using this index.

See SQLite::VirtualTable for a more complete description of
the incoming and outgoing parameters.

=cut

sub BEST_INDEX {
    my ($self,$constraints,$order_bys) = @_;
    trace "(BEST_INDEX)";
    # $order_bys is an arrayref of hashrefs with keys "column" and "direction".
    $self->{indexes} ||= [];
    $self->{counts}  ||= {};
    my $index_number = @{ $self->indexes };
    my $index_name = "index_".$index_number;
    ( $self->counts->{__table__} ) = $db->select( $self->table, 'count(1)', )->list;
    my $cost = $self->counts->{__table__};
    my $i = 0;
    my @index_constraints;
    # We are going to build an "index" (in name only) for this set of
    # constraints. The cost will be the total number of matching attributes
    # in the table for each of the constraints.
    my %seen_column;
    for my $constraint (@$constraints) {
        # Keys of $constraint are : operator, usable, column.
        # We must fill in : arg_index, omit.
        next unless $constraint->{usable};
        $cost ||= 0;
        my $column_name = $self->{columns}[$constraint->{column}];
        debug "evaluating cost of using column $column_name, operator $constraint->{operator}";
        $constraint->{arg_index} = $i++;  # index of this constraint as it comes through in @args to FILTER
        $constraint->{omit} = 1;
        push @index_constraints, {
            operator => $constraint->{operator},
            column_name => $column_name
          };
       unless (defined($self->counts->{$column_name})) {
            # TODO cache these (when creating the table?)
            ( $self->counts->{$column_name} ) =
              $db->select( $self->table, 'count(1)',
                { $self->pivot_column => $column_name } )->list;
       }
       my $this_cost = $self->counts->{$column_name};
       #debug "this cost is $this_cost";
       $cost -= $this_cost unless $seen_column{$column_name}++;
    }
    push @{ $self->indexes }, { constraints => \@index_constraints, name => $index_name, cost => $cost };
    unless (defined($cost)) {
        ($cost) = $db->select($self->{table},'count(1)')->flat;
        debug "cost is num of rows which is $cost";
    }
    my $order_by_consumed = 0;
    if ( @$order_bys == 1 )
    {    # only consumed if we are ordering by the pivot_row in ascending order
        if (   $self->columns->[ $order_bys->[0]{column} ] eq $self->pivot_row
            && $order_bys->[0]{direction} == 1 ) {
            $order_by_consumed = 1;
        }
    }
    debug "returning:  index $index_number ($index_name) has cost $cost (orderconsumed: $order_by_consumed)";
    return ( $index_number, $index_name, $order_by_consumed, $cost );
}

=item FILTER

Given a cursor and an index number (created dynamically in BEST_FILTER)
and the @args to pass to the index, run the query on the base table,
joining as necessary to filter the results.

=cut

sub FILTER {
    # called after OPEN, before NEXT
    my ($self, $cursor, $idxnum, $idxstr, @args) = @_; 
    trace "(FILTER $cursor)";
    debug "filter -- index chosen was $idxnum ($idxstr) ";
    my $constraints = $self->indexes->[$idxnum]{constraints};
    debug "FILTER Is calling _do_query for $cursor";
    $cursor->reset;
    $self->_do_query( $cursor, $constraints, \@args );
    $self->NEXT($cursor);
}

=item EOF

Are there any more rows left?

=cut

sub EOF {
    my ($self, $cursor ) = @_;
    $cursor->done;
};

sub _row_values_are_equal {
    my $self = shift;
    my ($val1,$val2) = @_;
    return $val1==$val2 if $self->pivot_row_type =~ /integer/i;
    return $val1 eq $val2;
}

=item NEXT

Advance the cursor one row.

=cut

sub NEXT {
  my ($self,$cursor) = @_;
  trace "(NEXT $cursor)";
  $cursor->get_next_row;
}

=item COLUMN

Get a piece of data from a given column (and the current row).

=cut

sub COLUMN  {
  my ($self, $cursor, $n) = @_;
  my $value = $cursor->column_value( $self->{columns}[$n] );
  return looks_like_number($value) ? 0 + $value : $value;
}

=item ROWID

Generate a unique id for this row.

=cut

sub ROWID {
    my ($self, $cursor) = @_;
    return $cursor->row_id;
}

=item CLOSE

Close the cursor.

=cut

sub CLOSE {
  my ($self,$cursor) = @_;
  trace "(CLOSE $cursor)";
  for ($cursor->temp_tables) {
      $db->query("drop table $_") or warn "error dropping $_: ".$db->error;
  }
}

=item DROP

Drop the virtual table.

=cut

sub DROP {

}

=item DISCONNECT

Disconnect from the database.

=cut

sub DISCONNECT {}

*DESTROY = \&DISCONNECT;

=back

=head1 TODO

    - re-use the existing database handle (requires changes
      to SQLite::VirtualTable and DBD::SQLite)
    - allow modification of the data in the virtual table
    - allow value column to not have integer affinity
    - more optimization

=head1 SEE ALSO

L<SQLite::VirtualTable::Pivot::Cursor>

L<SQLite::VirtualTable>

=cut

1;


