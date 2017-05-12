package SPOPS::DBI::TypeInfo;

# $Id: TypeInfo.pm,v 1.6 2004/02/26 01:03:23 lachoy Exp $

use strict;
use base qw( Class::Accessor );
use DBI                   qw( :sql_types );
use Log::Log4perl         qw( get_logger );
use SPOPS::Exception      qw( spops_error );
use SPOPS::Exception::DBI qw( spops_dbi_error );

my @FIELDS = qw( table database );
__PACKAGE__->mk_accessors( @FIELDS );

my ( $log );

my %FAKE_TYPES = (
   int   => SQL_INTEGER,
   num   => SQL_NUMERIC,
   float => SQL_FLOAT,
   char  => SQL_VARCHAR,
   date  => SQL_DATE,
);


########################################
# CONSTRUCTOR

sub new {
    my ( $class, $params ) = @_;
    my $self = bless( {}, $class );

    # First assign the simple fields

    foreach my $field ( @FIELDS ) {
        next unless ( $params->{ $field } );
        $self->$field( $params->{ $field } );
    }

    # Next assign parallel field/type arrays

    if ( ref $params->{fields} eq 'ARRAY' and ref $params->{types} eq 'ARRAY' ) {
        my $num_fields = scalar @{ $params->{fields} };
        my $num_types  = scalar @{ $params->{types} };
        if ( $num_fields != $num_types ) {
            spops_error "Incorrect parameters: number of fields ($num_fields) ",
                        "is not equal to the number of types ($num_types)";
        }
        $self->{_fields} = $params->{fields};
        $self->{_types}  = $params->{types};
        for ( 0 .. $num_fields - 1 ) {
            $self->add_type( $params->{fields}[ $_ ], $params->{types}[ $_ ] );
        }
    }

    # Next assign a map of field -> type

    if ( ref $params->{map} eq 'HASH' ) {
        while ( my ( $field, $type ) = each %{ $params->{map} } ) {
            $self->add_type( $field, $type );
        }
    }

    return $self;
}


########################################
# GET/SET METHODS

sub add_type {
    my ( $self, $field, $type ) = @_;
    $log ||= get_logger();

    # If it's already defined, issue a warning but don't change it

    if ( my $existing_type = $self->get_type( $field ) ) {
        $log->warn( "Field [$field] was already defined with type ",
                    "[$existing_type]. No action taken." );
        return $existing_type;
    }

    # Check to see if it's a fake type (suppress warnings since this
    # use of int() will issue a warning if it's 'char'/'date'/etc.,
    # which is what we're checking for.

    {
        no warnings;
        unless ( int( $type ) ) {
            my $faked = $FAKE_TYPES{ $type };
            unless ( $faked ) {
                spops_error "Type [$type] for [$field] is invalid -- it is  ",
                            "not a DBI type and not one of the 'fake' types, ",
                            "which are: ", join( ', ', sort keys %FAKE_TYPES );
            }
            $type = $faked;
        }
    }

    # Assign

    $self->{_map}{ lc $field } = int( $type );
    push @{ $self->{_fields} }, $field;
    push @{ $self->{_types} }, $type;
    return $type;
}


sub get_type {
    my ( $self, $field ) = @_;
    return undef unless ( $field );
    return $self->{_map}{ lc $field };
}


sub get_fields {
    my ( $self ) = @_;
    return @{ $self->{_fields} };
}


sub get_types {
    my ( $self ) = @_;
    return @{ $self->{_types} };
}


sub fetch_types {
    my ( $self, $dbh, $sql ) = @_;

    # Provide a default SQL implementation

    unless ( $sql ) {
        unless ( $self->table ) {
            spops_error "Cannot retrieve fields and types from database: ",
                        "no SQL given to use, and the 'table' object ",
                        "property is not set.";
        }
        $sql = sprintf( "SELECT * FROM %s WHERE 1 = 0", $self->table );
    }

    my $sth = eval { $dbh->prepare( $sql ) };
    if ( $@ ) {
        spops_dbi_error $@, { sql => $sql, action => 'prepare' };
    }

    my $rv = eval { $sth->execute };
    if ( $@ ) {
        spops_dbi_error $@, { sql => $sql, action => 'execute' };
    }

    eval {
        my $fields = $sth->{NAME};
        my $types  = $sth->{TYPE};
        for ( my $i = 0; $i < scalar @{ $fields }; $i++ ) {
            $self->add_type( $fields->[ $i ],  $types->[ $i ] );
        }
    };
    if ( $@ ) {
        spops_error "Cannot retrieve name/type info for ",
                    $self->table, ": $@";
    }
    $sth->finish;
    return $self;
}

sub as_hash {
    my ( $self ) = @_;
    my %h = ();
    my $num_fields = scalar @{ $self->{_fields} };
    for ( my $i = 0; $i < $num_fields; $i++ ) {
        $h{ $self->{_fields}[ $i ] } = $self->{_types}[ $i ];
    }
    return %h;
}

1;

__END__

=head1 NAME

SPOPS::DBI::TypeInfo - Represent type information for a single table

=head1 SYNOPSIS

 # Do everything at initialization with DBI types

 my $type_info = SPOPS::DBI::TypeInfo->new({
                     database => 'foo',
                     table    => 'cards',
                     fields   => [ 'face', 'value', 'color' ],
                     types    => [ SQL_VARCHAR, SQL_INTEGER, SQL_VARCHAR ] });

 # Do everything at initialization with fake types

 my $type_info = SPOPS::DBI::TypeInfo->new({
                     database => 'foo',
                     table    => 'cards',
                     fields   => [ 'face', 'value', 'color' ],
                     types    => [ 'char', 'int', 'char' ] });
 ...

 # Cycle through the fields and find the types

 print "Information for ",
       join( '.', $type_info->database, $type_info->table ), "\n";
 foreach my $field ( $type_info->get_fields ) {
     print "Field $field is type ", $type_info->get_type( $field ), "\n";
 }

 # Get the field/type information from the database

 my $type_info = SPOPS::DBI::TypeInfo->new({ database => 'db',
                                             table    => 'MyTable' });
 my $dbh = my_function_to_get_database_handle( ... );
 my $sql = qq/ SELECT * FROM MyTable WHERE 1 = 0 /;
 $type_info->fetch_types( $dbh, $sql );
 print "Type of 'foo' is ", $type_info->get_type( 'foo' );

 # Do the above at one time

 my $dbh = my_function_to_get_database_handle( ... );
 my $type_info = SPOPS::DBI::TypeInfo->new({ table    => 'MyTable' })
                                     ->fetch_types( $dbh );

=head1 DESCRIPTION

This is a lightweight object to maintain state about a field names and
DBI types for a particular table in a particular database. It is
generally used by L<SPOPS::SQLInterface|SPOPS::SQLInterface>, but it
is sufficiently decoupled so you might find it useful elsewhere.

It is case-insensitive when finding the type to match a field, but
stores the fields in the case added or, if you use C<fetch_types()>,
the case the database reports.

=head2 Fake Types

This class supports a small number of 'fake' types as well so you do
not have to import the DBI constants. These are:

   Fake     DBI
   ====================
   int   -> SQL_INTEGER
   num   -> SQL_NUMERIC
   float -> SQL_FLOAT
   char  -> SQL_VARCHAR
   date  -> SQL_DATE

More can be added as necessary, but these seemed to cover the
spectrum.

These fake types can be used anywhere you set a type for a field: in
the constructor, or in C<add_type()>. So the following do the same
thing:

 $type_info->add_type( 'foo', SQL_NUMERIC );
 $type_info->add_type( 'foo', 'num' );

=head1 METHODS

B<new( \%params )>

Create a new object. There are two types of parameters: the object
properties, and the fields and types to be used. The properties are
listed in L<PROPERTIES> -- just pass in a value for a property by its
name and it will be set.

You have two options for the field names and values.

=over 4

=item 1.

You can pass in parallel arrayrefs in C<fields> and C<types>.

=item 2.

You can pass a hashref of fields to values in C<map>.

=back

Example of parallel fields and types:

 my $type_info = SPOPS::DBI::TypeInfo->new({
                    table => 'mytable',
                    fields => [ 'foo', 'bar', 'baz' ],
                    types  => [ SQL_INTEGER, SQL_VARCHAR, SQL_TIMESTAMP ] });

Example of a map:

 my $type_info = SPOPS::DBI::TypeInfo->new({
                    table => 'mytable',
                    map   => { foo => SQL_INTEGER,
                               bar => SQL_VARCHAR,
                               baz => SQL_TIMESTAMP } });,

Returns: new object instance.

B<get_type( $field )>

Retrieves the DBI type for C<$field>. The case of C<$field> does not
matter, so the following will return the same value:

 my $type = $type_info->get_type( 'first_name' );
 my $type = $type_info->get_type( 'FIRST_NAME' );
 my $type = $type_info->get_type( 'First_Name' );

Returns: the DBI type for C<$field>. If C<$field> is not registered
with this object, returns undef.

B<add_type( $field, $type )>

Adds the type C<$type> for field C<$field> to the object. As noted in
C<Fake Types>, the value for C<$type> may be a 'fake' type which will
then get mapped to a DBI type.

If a type for C<$field> has already been set, no action is taken but a
warning is issued.

Examples:

 $type_info->add_type( 'first_name', SQL_VARCHAR ); # ok
 $type_info->add_type( 'last_name', 'char' );       # ok
 $type_info->add_type( 'birthdate', SQL_DATE );     # ok
 $type_info->add_type( 'BIRTHDATE', SQL_DATE );     # results in warning
 $type_info->add_type( 'FIRST_NAME', SQL_INTEGER ); # results in warning

Returns: type set for C<$field>

B<fetch_types( $dbh, [ $sql ] )>

Retrieve fields and types from the database, given the database handle
C<$dbh> and the SQL C<$sql>. If C<$sql> is not provided we try to use
a common one:

  SELECT * FROM $self->table WHERE 1 = 0

If the C<table> property is not set and no C<$sql> is passed in the
method throws an exception.

Any failures to prepare/execute the query result in a thrown
L<SPOPS::Exception::DBI|SPOPS::Exception::DBI> object.

The object will store the fields as the database returns them, so a
call to C<get_fields()> may return the fields in an unknown
order/case. (Getting the type via C<get_type()> will still work,
however.)

Returns: the object, which allows method chaining as a shortcut.

B<get_fields()>

Returns a list of fields currently registered with this object. They
are returned in the order they were added.

Example:

 print "Fields in type info object: ", join( ", ", $type_info->get_fields );

B<get_types()>

Returns a list of types currently registered with this object. They
are returned in the order they were added.

Example:

 print "Types in type info object: ", join( ", ", $type_info->get_types );

B<as_hash()>

Returns the fields and types as a simple hash. The case of the field
should be the same as it was specified or retrieved from the database.

Example:

 my %type_map = $type_info->as_hash;
 foreach my $field ( keys %type_map ) {
     print "Field $field is type $type_map{ $field }\n";
 }

=head1 PROPERTIES

All properties are get and set with the same name.

B<database>

Name of the database this object is representing. (Optional, may be
empty.)

Example:

 $type_info->database( "production" );
 print "Database for metadata: ", $type_info->database(), "\n";

B<table>

Name of the table this object is representing. This is optional unless
you call C<fetch_types()> without a second argument (C<$sql>), since
the object will try to create default SQL to find fieldnames and types
by using the table name.

Example:

 $type_info->table( "customers" );
 print "Table for metadata: ", $type_info->table(), "\n";

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

Thanks to Ray Zimmerman E<lt>rz10@cornell.eduE<gt> for pointing out
the need for this module's functionality.
