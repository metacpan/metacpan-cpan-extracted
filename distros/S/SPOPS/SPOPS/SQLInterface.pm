package SPOPS::SQLInterface;

# $Id: SQLInterface.pm,v 3.12 2004/06/02 00:48:21 lachoy Exp $

use strict;
use Data::Dumper          qw( Dumper );
use DBI;
use Log::Log4perl         qw( get_logger );
use SPOPS::DBI::TypeInfo;
use SPOPS::Exception      qw( spops_error );
use SPOPS::Exception::DBI qw( spops_dbi_error );

my $log = get_logger();

$SPOPS::SQLInterface::VERSION = sprintf("%d.%02d", q$Revision: 3.12 $ =~ /(\d+)\.(\d+)/);

my %TYPE_INFO = ();

sub throw_no_database_handle_error {
    my ( $item ) = @_;
    my $class = ref $item || $item;
    spops_error "No database handle available; pass using the 'db' ",
                "parameter or define ${class}->global_datasource_handle ",
                "to return a valid DBI handle.";
}

# Drivers that don't support the two-argument form of DBI->quote
# should override...

sub sql_quote {
    my ( $class, $value, $type, $db ) = @_;
    return 'NULL' unless ( defined $value );
    $db ||= $class->global_datasource_handle;
    unless ( ref $db ) {
        spops_error "No database handle could be found!";
    }

    # This issues a warning when '$type' is unknown; need to figure
    # out how to set '$type' to a known value

    return $db->quote( $value, $type );
}

# Note: not sure how to integrate the fieldtype discovery
# stuff in here. What if you do:
#
# select u.username from users u, logins l
#  where l.login_date > ?  and
#        l.user_id = u.user_id
#
# and pass '2000/1/13' is passed in? This seems to be a little
# too much in-depth sql processing than this library is
# appropriate for; so you can still pass in values for binding,
# but they'll all be bound with SQL_VARCHAR
#
# select   => \@ of fields to select
# select_modifier => $ to insert between 'SELECT' and fields (e.g., DISTINCT)
# from     => \@ of tables to select from ($ allowed if only one)
# order    => $ clause to order by
# group    => $ clause to group by
# where    => $ clause to limit results
# return   => sth | single | list | hash | single-list
# value    => \@ of values to bind, all as SQL_VARCHAR; they must match order of '?' in where
# sql      => $ statement to execute

sub db_select {
    my ( $class, $p ) = @_;
    my $db    = $p->{db} || $class->global_datasource_handle;
    $class->throw_no_database_handle_error unless ( $db );

  # Don't do anything if the SQL isn't passed in and you don't have
  # either a list of fields to select or a table to select them from

    unless ( $p->{sql} or ( $p->{select} and $p->{from} ) ) {
        spops_error 'Cannot run without select/from statements!';
    }

    $log->is_debug &&
        $log->debug( "Entering db_select with ", Dumper( $p ) );
    $p->{return} ||= 'list';
    $p->{value}  ||= [];
    my $sql = $p->{sql};

    # If we don't have any SQL, build it (straightforward).

    unless ( $sql ) {
        $log->is_info &&
            $log->info( "No SQL passed in to execute directly; building." );

        $p->{from} ||= $p->{table}; # allow an alias
        if ( $p->{from} and ref $p->{from} ne 'ARRAY' ) {
            $p->{from} = [ $p->{from} ];
        }

        $p->{select_modifier} ||= '';
        my $select = join ', ', @{ $p->{select} };
        my $from   = join ', ', @{ $p->{from} };
        my $order  = ( $p->{order} ) ? "ORDER BY $p->{order}" : '';
        my $where  = ( $p->{where} ) ? "WHERE $p->{where}" : '';
        my $group  = ( $p->{group} ) ? "GROUP BY $p->{group}" : '';
        $sql = qq/
           SELECT $p->{select_modifier} $select
             FROM $from
            $where
            $group
            $order
        /;
    }
    $log->is_info &&
        $log->info( "SQL for select: $sql" );

    # First prepare and check for errors...

    my $sth = eval { $db->prepare( $sql ) };
    if ( $@ ) {
        spops_dbi_error $@, { sql => $sql, action => 'prepare' };
    }

    # Execute with any bound parameters; note that for Sybase you do
    # not need to pass any types at all.

    $log->is_info &&
        $log->info( "Values bound: ", join( '//', @{ $p->{value} } ) );
    eval { $sth->execute( @{ $p->{value} } ) };
    if ( $@ ) {
        spops_dbi_error $@, { sql         => $sql,
                              bound_value => $p->{value},
                              action      => 'execute' };
    }

    # If they asked for the handle back, give it to them

    if ( $p->{return} eq 'sth' ) {
        $log->is_info &&
            $log->info( "Returning statement handle (after prepare/execute)" );
        return $sth;
    }

    # If they asked for a single row, return it in arrayref format [
    # field1, field2, ...]

    if ( $p->{return} eq 'single' ) {
        $log->is_info &&
            $log->info( "Returning single row." );
        my $row =  eval { $sth->fetchrow_arrayref; };
        if ( $@ ) {
            spops_dbi_error $@, { sql         => $sql,
                                  bound_value => $p->{value},
                                  action      => 'fetchrow_arrayref' };
        }
        return $row;
    }

    # If they asked for a list of results, return an arrayref of arrayrefs

    elsif ( $p->{return} eq 'list' ) {
        $log->is_info &&
            $log->info( "Returning list of lists." );
        my $rows = eval { $sth->fetchall_arrayref; };
        if ( $@ ) {
            spops_dbi_error $@, { sql         => $sql,
                                  bound_value => $p->{value},
                                  action      => 'fetchall_arrayref' };
        }
        return $rows;
    }

    # return the first element of each record in an arrayref

    elsif ( $p->{return} eq 'single-list' ) {
        $log->is_info &&
            $log->info( "Returning list of single items." );
        my $rows = eval { $sth->fetchall_arrayref };
        if ( $@ ) {
            spops_dbi_error $@, { sql         => $sql,
                                  bound_value => $p->{value},
                                  action      => 'fetchall_arrayref' };
        }
        return [ map { $_->[0] } @{ $rows } ];
    }

    # If they asked for a hash, return a list of hashrefs

    elsif ( $p->{return} eq 'hash' ) {
        $log->is_info &&
            $log->info( "Returning list of hashrefs." );
        my @rows = ();

        # Note -- we may need to change this to zip through $row every
        # time and push a new reference onto @rows

        eval {
            while ( my $row = $sth->fetchrow_hashref ) {
                push @rows, \%{ $row };
            }
        };
        if ( $@ ) {
            spops_dbi_error $@, { sql         => $sql,
                                  bound_value => $p->{value},
                                  action      => 'fetchall_arrayref' };
        }
        return \@rows;
    }
    return [];
}

# field    => \@ of fieldnames
# value    => \@ of values
# table    => $ of table to insert into
# no_quote => \% of fields not to quote
# sql      => $ of sql to run
# return_sth => $ if true, return the statement handle rather than status

sub db_insert {
    my ( $class, $p ) = @_;
    my $db    = $p->{db} || $class->global_datasource_handle;
    $class->throw_no_database_handle_error unless ( $db );

    $log->is_debug &&
        $log->debug( "Enter insert procedure\n", Dumper( $p ) );

    # If we weren't given direct sql or a list of values or table, bail

    unless ( $p->{sql} or ( $p->{value} and $p->{table} ) ) {
        spops_error 'Cannot continue with no SQL, values or table name';
    }

    my $sql = $p->{sql};

    # If we weren't given SQL, build it.

    unless ( $sql ) {

        # Find the types for all fields in this table (we don't have
        # to use them all...); let any errors trickle up

        my $type_info = $class->db_discover_types(
                                   $p->{table},
                                   { dbi_type_info => $p->{dbi_type_info},
                                     db            => $db });

        my ( $fields, $values );

        # Be sure these are at least empty hashrefs, otherwise we
        # will get an error

        $p->{no_quote} ||= {};
        $p->{field}    ||= [];
        $p->{value}    ||= [];
        $log->is_debug &&
            $log->debug( "Fields/values: ", Dumper( $p->{field}, $p->{value} ) );

        # Cycle through the fields and values, creating lists
        # suitable for join()ing into the SQL statement.

        my @value_list = ();
        my $count = 0;
        foreach my $field ( @{ $p->{field} } ) {
            next unless ( $field );

            # Quote the value unless the user asked us not to
            my $value = ( $p->{no_quote}{ $field } )
                          ? $p->{value}->[ $count ]
                          : $class->sql_quote( $p->{value}->[ $count ],
                                               $type_info->get_type( $field ),
                                               $db );
            $log->is_info &&
                $log->info( "Trying to add quoted value [$value] ",
                                      "for field [$field]" );
            push @value_list, $value;
            $count++;
        }

        my $field_listing = join ', ', @{ $p->{field} };
        my $value_listing = join ', ', @value_list;
        $sql = qq/
           INSERT INTO $p->{table}
           ( $field_listing )
           VALUES
           ( $value_listing )
        /;
    }

    # Note that we use the prepare()/execute() method of
    # getting this data in rather than the simpler do(),
    # since the user might want the statement handle afterward;
    # if this becomes a performance hang (doubtful), we can only
    # do p/e if the user's asked for the statement handle

    $log->is_info &&
        $log->info( "Preparing\n$sql" );
    my $sth = eval { $db->prepare( $sql ) };
    if ( $@ ) {
        spops_dbi_error $@, { sql => $sql, action => 'prepare' };
    }

    my $rv = eval { $sth->execute };
    if ( $@ ) {
        spops_dbi_error $@, { sql => $sql, action => 'execute' };
    }
    $log->is_info &&
        $log->info( "Prepare/execute went ok." );

    # Everything is ok; return either a true value
    # or the statement handle, if they've asked for it.

    return $sth   if ( $p->{return_sth} );
    return $rv;
}


# field    => \@ of fieldnames
# value    => \@ of values (includes both update values and WHERE params)
# table    => $ of table to insert into
# where    => $ clause for which we're updating
# no_quote => \% of fields not to quote
# sql      => $ of sql to run

sub db_update {
    my ( $class, $p ) = @_;
    my $db    = $p->{db} || $class->global_datasource_handle;
    $class->throw_no_database_handle_error unless ( $db );

  # If we weren't given direct sql or a list of values or table, bail

    unless ( $p->{sql} or ( $p->{value} and $p->{table} ) ) {
        spops_error 'Cannot continue with no SQL, values or table name';
    }
    my $sql = $p->{sql};

    my @values = ();
    $p->{value} ||= [];

    # If SQL provided still pass the values as bound parameters

    if ( $sql ) {
        @values = @{ $p->{value} };
    }

    # Build the SQL

    unless ( $sql ) {

        # Find the types for all fields in this table (we don't have
        # to use them all...); let the error trickle up

        my $type_info = $class->db_discover_types(
                                       $p->{table},
                                       { dbi_type_info => $p->{dbi_type_info},
                                         db            => $db } );
        my ( @update );

        # make a copy of the values given so we can modify the list as
        # we go -- it may include both update parameters and WHERE
        # parameters

        @values = @{ $p->{value} };

        # Go through each field and setup an update assign subset
        # for each; most of them get a bound parameter and push the
        # value onto the stack, but values that cannot be bound push
        # the direct information onto the stack.

        $p->{no_quote} ||= {};
        foreach my $field ( @{ $p->{field} } ) {
            my $rawval = shift @values;
            $log->is_info &&
                $log->info( "Trying to add value [", defined $rawval ? $rawval : '', "] ",
                                      "with field [$field] and type ",
                                      "[", $type_info->get_type( $field ), "]" );

            # Quote the value unless the user asked us not to

            my $value = ( $p->{no_quote}{ $field } )
                          ? $rawval
                          : $class->sql_quote( $rawval,
                                               $type_info->get_type( $field ),
                                               $db );
            push @update, "$field = $value";
        }
        my $update = join ', ', @update;
        my $where  = ( $p->{where} ) ? "WHERE $p->{where}" : '';
        $sql = qq/
           UPDATE $p->{table}
              SET $update
            $where
        /;
    }
    $log->is_info &&
        $log->info( "Prepare/execute\n$sql" );
    my $sth = eval { $db->prepare( $sql ) };
    if ( $@ ) {
        spops_dbi_error $@, { sql => $sql, action => 'prepare' };
    }

    # assign the remainder of the values in case the 'WHERE' clause
    # included any

    my $rv = eval { $sth->execute( @values ) };
    if ( $@ ) {
        spops_dbi_error $@, { sql => $sql, action => 'execute' };
    }
    return $rv;
}


# table  => $ of table we're deleting from
# where  => $ limiting our deletes
# value  => \@ of values to bind
# sql    => $ of statement to execute directly

sub db_delete {
    my ( $class, $p ) = @_;
    my $db    = $p->{db} || $class->global_datasource_handle;
    $class->throw_no_database_handle_error unless ( $db );

    # Gotta have a table to delete from

    unless ( $p->{table} or $p->{sql} ) {
        spops_error 'Cannot delete records without SQL or a table name';
    }

    # If we weren't given SQL, build it.

    my $sql = $p->{sql};
    unless ( $sql ) {

        # Hopefully you'll have a WHERE clause... but we'll let
        # you shoot yourself in the foot if you forget :)

        my $where = ( $p->{where} ) ? "WHERE $p->{where}" : '';
        $sql = qq/ DELETE FROM $p->{table} $where /;
    }

    $log->is_info &&
        $log->info( "SQL for DELETE:\n$sql" );
    $p->{value} ||= [];
    my $sth = eval { $db->prepare( $sql ) };
    if ( $@ ) {
        spops_dbi_error $@, { sql => $sql, action => 'prepare' };
    }

    my $rv = eval { $sth->execute( @{ $p->{value} } ) };
    if ( $@ ) {
        spops_dbi_error $@, { sql         => $sql,
                              bound_value => $p->{value},
                              action      => 'execute' };
    }
    return $rv;
}



sub db_discover_types {
    my ( $class, $table, $p ) = @_;

    # Create the index used to find the table info later

    my $db       = $p->{db} || $class->global_datasource_handle;
    $class->throw_no_database_handle_error unless ( $db );

    my $db_name = eval { $db->{Name} } || eval { $db->{name} };
    my $type_idx = join( '-', lc $db_name , lc $table );
    $log->is_debug &&
        $log->debug( "Type index used to discover data types: [$type_idx]" );

    # If we've already discovered the types, get the cached copy

    return $TYPE_INFO{ $type_idx } if ( $TYPE_INFO{ $type_idx } );

    my $type_info = SPOPS::DBI::TypeInfo->new({ database => $db_name,
                                                table    => $table });

    my $conf = eval { $class->CONFIG };
    my $fake_types = $p->{dbi_type_info} || $conf->{dbi_type_info};

    # Certain databases (or more specifically, DBD drivers) do not
    # process $sth->{TYPE} requests properly, so we need the user to
    # specify the types by hand

    if ( ref $fake_types eq 'HASH' ) {
        while ( my ( $field, $fake_type ) = each %{ $fake_types } ) {
            $type_info->add_type( $field, $fake_type );
        }
    }

    # Otherwise, fetch the types from the database

    else {
        my $sql = $class->sql_fetch_types( $table );
        $type_info->fetch_types( $db, $sql );
    }

    return $TYPE_INFO{ $type_idx } = $type_info
}


# Default data type discovery statement

sub sql_fetch_types { return "SELECT * FROM $_[1] where 1 = 0" }

1;

__END__

=pod

=head1 NAME

SPOPS::SQLInterface - Generic routines for DBI database interaction

=head1 SYNOPSIS

 # Make this class a parent of my class

 package My::DBIStuff;
 use SPOPS::SQLInterface;
 @My::DBIStuff::ISA = qw( SPOPS::SQLInterface );

 # You should also be able to use it directly, but you
 # need to pass in a database object with every request

 use SPOPS::SQLInterface;
 my $dbc = 'SPOPS::SQLInterface';
 my $db = DBI->connect( ... ) || die $DBI::errstr;
 my $rows = $dbc->db_select({ select => [ qw/ uid first_name last_name / ],
                              from   => [ 'users' ],
                              where  => 'first_name = ? or last_name = ?',
                              value  => [ 'fozzie', "th' bear" ],
                              db     => $db });
 foreach my $row ( @{ $results } ) {
   print "User ID $row->[0] is $row->[1] $row->[2]\n";
 }

=head1 DESCRIPTION

You are meant to inherit from this class, although you can use it as a
standalone SQL abstraction tool as well, as long as you pass the
database handle into every routine you call.

=head1 DATABASE METHODS

Relatively simple methods to do the select, update, delete and
insert statements, with the right values and table names being passed
in.

All parameters are passed in via named values, such as:

 $t->db_select({ select => [ 'this', 'that' ],
                 from   => [ 'mytable' ] });

B<VERY IMPORTANT>

The subclass that uses these methods must either pass in a DBI
database handle via a named parameter (B<db>) or make it available
through a method of the class called 'global_datasource_handle'.

=head1 METHODS

There are very few methods in this class, but each one can do quite a
bit.

=head2 sql_quote( $value, $type, $db )

Quotes a value for insertion/update or selection when bound parameters
are inappropriate or unavailable. Returns 'NULL' if C<$value> is
undef, otherwise calls C<quote( $value, $type )> on the DBI handle
C<$db>.

Drivers that do not implement the two-argument form of C<quote()>
should override this method.

Returns: quoted C<$value> appropriate to use in a SQL statement

=head2 db_select( \%params )

Executes a SELECT. Return value depends on what you ask for. Many of
the parameters are optional unless you pass in SQL to execute.

Parameters:

B<sql> ($) (optional)

Full statement to execute, although you may put '?' in the where
clause and pass values for substitution. (No quoting hassles...)

B<select> (\@) (optional unless 'sql' defined)

Fields to select

B<select_modifier> ($) (optional)

Clause to insert between 'SELECT' and fields (e.g., DISTINCT)

B<from> (\@ or $) (optional unless 'sql' defined)

List of tables to select from. (You can pass a single tablename as a
scalar if you wish.)

B<order> ($) (optional)

Clause to order results by; if not given, the order depends
entirely on the database.

B<group> ($) (optional)

Clause to group results by (in a 'GROUP BY' clause). This is normally
only done with 'COUNT(*)' and such features. See your favorite SQL
reference for more info.

B<where> ($) (optional unless 'sql' defined)

Clause to limit results. Note that you can use '?' for field values
but they will get quoted as if they were a SQL_VARCHAR type of value.

B<return> ($) (optional)

What the method should return. Potential values are:

=over 4

=item *

'list': returns an arrayref of arrayrefs (default)

=item *

'single': returns a single arrayref

=item *

'hash': returns an arrayref of hashrefs

=item *

'single-list': returns an arrayref with the first value of each record
as the element.

=item *

'sth': Returns a DBI statement handle that has been I<prepare>d and
I<execute>d with the proper values. Use this if you are executing a
query that may return a lot of rows but you only want to retrieve
values for some of the rows.

=back

B<value> (\@) (optional unless you use '?' placeholders)

List of values to bind, all as SQL_VARCHAR; they must match order of
'?' in the where clause either passed in or within the SQL statement
passed in.

B<Examples>:

Perl statement:

 $t->db_select( { select => [ qw/ first_name last_name /],
                  from   => [ 'users' ],
                  where  => 'last_name LIKE ?',
                  value  => 'moo%' } );

SQL statement:

 SELECT first_name, last_name
   FROM users
  WHERE last_name LIKE 'moo%'

Returns:

 [ [ 'stephen', 'moore' ],
   [ 'charles', 'mooron' ],
   [ 'stacy', 'moonshine' ] ]

Perl statement:

 $t->db_select( { select => [ qw/ u.username l.login_date / ],
                  from   => [ 'users u', 'logins l' ],
                  where  => "l.login_date > '2000-04-18' and u.uid = l.uid"
                  return => 'hash' } );

SQL statement:

 SELECT u.username, l.login_date
   FROM users u, logins l
  WHERE l.login_date > '2000-04-18' and u.uid = l.uid

Returns:

 [ { username => 'smoore',
     login_date => '2000-05-01' },
   { username => 'cmooron',
     login_date => '2000-04-19' },
   { username => 'smoonshine',
     login_date => '2000-05-02' } ]

Perl statement:

 $t->db_select( { select => [ qw/ login_name first_name last_name /],
                  from   => [ 'users' ],
                  where  => 'last_name LIKE ?',
                  value  => 'moo%',
                  return => 'single-list' } );

SQL statement:

 SELECT login_name, first_name, last_name
   FROM users
  WHERE last_name LIKE 'moo%'

Returns:

 [ 'smoore',
   'cmooron',
   'smoonshine' ]


=head2 db_insert( \%params )

Create and execute an INSERT statement given the parameters passed
in. Return value is true is insert was successful -- the exact value
is whatever is returned from the C<execute()> statement handle
call from your database. (See L<DBI|DBI> and your driver docs.)

Parameters:

B<sql> ($) (optional)

Full SQL statement to run; you can still pass in values to quote/bind
if you use '?' in the statement.

B<table> ($) (optional unless 'sql' defined)

Name of table to insert into

B<field> (\@) (optional unless 'sql' defined)

List of fieldnames to insert

B<value> (\@) (optional unless you use '?' placeholders)

List of values, matching up with order of field list.

B<no_quote> (\%) (optional)

Fields that we should not quote

B<return_sth> ($) (optional)

If true, return the statement handle rather than a status.

B<Examples>:

Perl statement:

 $t->db_insert( { table => 'users',
                  field => [ qw/ username first_name last_name password / ],
                  value => [ 'cmw817', "Chris O'Winters" ] } );

SQL statement:

 INSERT INTO users
 ( username, first_name, last_name, password )
 VALUES
 ( 'cmw817', 'Chris', 'O''Winters', NULL )

Perl statement:

 my $sql = qq/
   INSERT INTO users ( username ) VALUES ( ? )
 /;

 foreach my $username ( qw/ chuck stinky jackson / ) {
   $t->db_insert({ sql   => $sql,
                   value => [ $username ] } );
 }

SQL statements:

 INSERT INTO users ( username ) VALUES ( 'chuck' )
 INSERT INTO users ( username ) VALUES ( 'stinky' )
 INSERT INTO users ( username ) VALUES ( 'jackson' )

=head2 db_update( \%params )

Create and execute an UPDATE statement given the parameters passed
in. Return value is true is update was successful -- the exact value
is whatever is returned from the C<execute()> statement handle call
from your database, which many times is the number of rows affected by
the update. (See L<DBI|DBI> and your driver docs -- in particular,
note that the return value from an UPDATE can vary depending on the
database being used as well as the number of records B<actually>
updated versus those that matched the criteria but were not updated
because they already matched the value(s). In particular, see the
discussion in L<DBD::mysql|DBD::mysql> under
'mysql_client_found_rows'.)

Parameters:

B<sql> ($) (optional)

Full SQL statement to run; note that you can use '?' for
values and pass in the raw values via the 'value' parameter,
and they will be quoted as necessary.

B<field> (\@) (optional unless 'sql' defined)

List of fieldnames we are updating

B<value> (\@) (optional unless you use '?' placeholders)

List of values corresponding to the fields we are
updating and to parameters in the WHERE clause.

B<table> ($) (optional unless 'sql' defined)

Name of table we are updating

B<where> ($) (optional unless 'sql' defined)

Clause that specifies the rows we are updating

B<no_quote> (\%) (optional)

Specify fields not to quote

B<Examples>:

Perl statement:

 $t->db_update( { field => [ qw/ first_name last_name / ],
                  value => [ 'Chris', "O'Donohue" ],
                  table => 'users',
                  where => 'user_id = 98172' } );

SQL statement (assuming "'" gets quoted as "''"):

 UPDATE users
    SET first_name = 'Chris',
        last_name = 'O''Donohue',
  WHERE user_id = 98172

=head2 db_delete( \%params )

Removes the record indicated by \%params from the database. Return
value is true is delete was successful -- the exact value is whatever
is returned from the C<execute()> statement handle call from your
database. (See L<DBI|DBI>)

Parameters:

B<sql> ($) (optional)

Full SQL statement to execute directly, although you can
use '?' for values and pass the actual values in via the
'value' parameter.

B<table> ($) (optional unless 'sql' defined)

Name of table from which we are removing records.

B<where> ($) (optional unless 'sql' defined)

Specify the records we are removing. Be careful: if you pass in the
table but not the criteria, you will clear out your table! (Just like
real SQL...)

B<value> (\@) (optional unless you use '?' placeholders)

List of values to bind to '?' that may be found either in
the where clause passed in or in the where clause found
in the SQL statement.

B<Examples>:

Perl statement:

 $t->db_delete( { table => 'users', where => 'user_id = 98172' } );

SQL statement:

 DELETE FROM users
  WHERE user_id = 98172

Perl statement:

 $t->db_delete( { table => 'users', where => 'last_name LIKE ?',
                  value => [ 'moo%' ] } );

SQL statement:

 DELETE FROM users
  WHERE last_name LIKE 'moo%'

Perl statement:

 $t->db_delete( { table => 'users' } );

SQL statement:

 DELETE FROM users

Oops, just cleared out the 'users' table. Be careful!

=head2 db_discover_types( $table, \%params )

Retrieve field type information for C<$table>. Normally we simply
issue a dummy query to a particular table to get its schema -- field
names and field types. We cache the information (in a
L<SPOPS::DBI::TypeInfo|SPOPS::DBI::TypeInfo> object) and then query it
for the different field types as we need them.

If a DBD driver does not support the C<{TYPE}> attribute of the DBI
statement handle, you have to specify some simple types in your class
configuration or provide them either in the call to
C<db_discover_types()> or in the object configuration using the key
'dbi_type_info' as listed in the parameters below. (See
L<SPOPS::DBI::TypeInfo|SPOPS::DBI::TypeInfo> for an enumeration of the
the values to use.)

Return a L<SPOPS::DBI::TypeInfo|SPOPS::DBI::TypeInfo> object for
C<$table>.

Parameters:

B<table> ($)

The name of a particular table. Note that this routine is not smart
enough to distinguish between: B<users> and B<dbo.users> even though
they might refer to the same table in the database. It is not harmful
if you use the same name twice in this manner, the module just has to
do a little extra work.

Other parameters:

=over 4

=item B<db> (object) (optional)

DBI database handle. (Optional only if you have a
C<global_datasource_handle()> class method defined.

=item B<dbi_type_info> (\%) (optional)

If your DBD driver cannot retrieve type information from the database,
you need to give this module a hint as to what type of datatypes you
will be working with. See C<Fake Types> in
L<SPOPS::DBI::TypeInfo|SPOPS::DBI::TypeInfo> for the types you can use.

=back

Example:

  my $type_info = $class->db_discover_types( $class->table_name );
  foreach my $field ( $type_info->get_fields ) {
      print "$field is DBI type ", $type_info->get_type( $field ), "\n";
  }

=head1 ERROR HANDLING

All errors encountered by this module throw a
L<SPOPS::Exception|SPOPS::Exception> object (in case of a lack of
required information) or, in most cases, a
L<SPOPS::Exception::DBI|SPOPS::Exception::DBI> object.

=head1 TO DO

B<DBI binding conventions>

One of the things the DBI allows you to do is prepare a statement once
and then execute it many times -- particularly useful for INSERTs and
UPDATEs. It would be nice to be able to do that.

B<Datasource Names>

Be able to pass a name to 'global_datasource_handle' (and to pass in
that name to the relevant 'db_*' calls).

=head1 BUGS

None known.

=head1 SEE ALSO

L<DBI|DBI>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

See the L<SPOPS|SPOPS> module for the full author list.

=cut
