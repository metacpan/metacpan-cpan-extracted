package SPOPS::Import::DBI::Table;

# $Id: Table.pm,v 3.7 2004/06/02 00:48:23 lachoy Exp $

use strict;
use base qw( SPOPS::Import );
use Data::Dumper qw( Dumper );
use SPOPS::Exception;
use SPOPS::Import::DBI::TableTransform;

$SPOPS::Import::DBI::Table::VERSION  = sprintf("%d.%02d", q$Revision: 3.7 $ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( database_type transforms print_only return_only );
SPOPS::Import::DBI::Table->mk_accessors( @FIELDS );

########################################
# CORE API

sub get_fields { return ( $_[0]->SUPER::get_fields(), @FIELDS ) }

sub run {
    my ( $self ) = @_;

    unless ( $self->data ) {
        my $m = "Cannot import a table without data\n" .
                "Please set it using \$table_import->data( \$table_sql )\n" .
                "or \$table_import->read_table_from_file( '/path/to/mytable.sql' )\n" .
                "or \$table_import->read_table_from_fh( \$filehandle )";
        SPOPS::Exception->throw( $m );
    }

    unless ( $self->database_type ) {
        my $m = "Cannot import a table without specifying a database type.\n" .
                "Please set the database type using:\n" .
                "\$table_import->database_type( 'dbtype' )";
        SPOPS::Exception->throw( $m );

    }

    my $table_sql = $self->transform_table;

    if ( $self->print_only ) {
        print $table_sql;
        return;
    }

    if ( $self->return_only ) {
        return $table_sql;
    }

    my $object_class = $self->object_class;
    unless ( $object_class ) {
        my $m = "Cannot retrieve a database handle without an object class being\n" . 
                "defined. Please set it using \$table_import->object_class( 'My::Class' )\n" .
                "so I know what to use.";
        SPOPS::Exception->throw( $m );
    }

    my $db = $object_class->global_datasource_handle;
    unless ( $db ) {
        my $m = "No datasource defined for ($object_class) -- please ensure that\n" .
                "when I call \$object_class->global_datasource_handle() I get a\n" .
                "DBI database handle back.\n";
        SPOPS::Exception->throw( $m );
    }

    eval { $db->do( $table_sql ) };
    return [ undef, $table_sql, $@ ] if ( $@ );
    return [ 1, $table_sql, undef ];
}


########################################
# TABLE TRANSFORMATIONS

sub transform_table {
    my ( $self ) = @_;

    # Make a copy of 'data' so that it will remain in the
    # untransformed state

    my $table_sql = $self->data;

    # Create a new transformer

    my $transformer = SPOPS::Import::DBI::TableTransform->new( $self->database_type );

    # These are the built-ins (facade to all of them)

    $transformer->transform( \$table_sql );

    # Run the custom transformations

    my $transforms = $self->transforms;
    my $transforms_list = ( ref $transforms eq 'ARRAY' )
                            ? $transforms : [ $transforms ];
    foreach my $transform_sub ( @{ $transforms_list } ) {
        next unless ( ref $transform_sub eq 'CODE' );
        $transform_sub->( $transformer, \$table_sql, $self );
    }
    return $table_sql;
}


########################################
# I/O

sub read_table_from_file {
    my ( $self, $filename ) = @_;
    $self->data( $self->read_file( $filename ) );
}

sub read_table_from_fh {
    my ( $self, $fh ) = @_;
    $self->data( $self->read_fh( $fh ) );
}

1;

__END__

=head1 NAME

SPOPS::Import::DBI::Table - Import a DBI table structure

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 use strict;
 use SPOPS::Import;
 
 {
     my $table_import = SPOPS::Import->new( 'table' );
     $table_import->database_type( 'sybase' );
     $table_import->read_table_from_fh( \*DATA );
     $table_import->print_only( 1 );
     $table_import->transforms([ \&table_login ]);
     $table_import->run;
 }
 
 sub table_login {
    my ( $transformer, $sql, $importer ) = @_;
    $$sql =~ s/%%LOGIN%%/varchar(25)/g;
 }
 
 __DATA__
 CREATE TABLE sys_user (
  user_id       %%INCREMENT%%,
  login_name    %%LOGIN%% not null,
  password      varchar(30) not null,
  last_login    datetime null,
  num_logins    int null,
  theme_id      %%INCREMENT_TYPE%% default 1,
  first_name    varchar(50) null,
  last_name     varchar(50) null,
  title         varchar(50) null,
  email         varchar(100) not null,
  language      char(2) default 'en',
  notes         text null,
  removal_date  %%DATETIME%% null,
  primary key   ( user_id ),
  unique        ( login_name )
 )

 Output:
 
 CREATE TABLE sys_user (
  user_id       NUMERIC( 10, 0 ) IDENTITY NOT NULL,
  login_name    varchar(25) not null,
  password      varchar(30) not null,
  last_login    datetime null,
  num_logins    int null,
  theme_id      NUMERIC( 10, 0 ) default 1,
  first_name    varchar(50) null,
  last_name     varchar(50) null,
  title         varchar(50) null,
  email         varchar(100) not null,
  language      char(2) default 'en',
  notes         text null,
  removal_date  datetime null,
  primary key   ( user_id ),
  unique        ( login_name )
 )

=head1 DESCRIPTION

This class allows you to transform and import (or simply display) a
DBI table structure.

Transformations are done via two means. The first is the
database-specific classes and the standard modifications provided by
L<SPOPS::Import::DBI::TableTransform|SPOPS::Import::DBI::TableTransform>. The
second is custom code that you can write.

=head1 METHODS

B<database_type> ($)

Type of database to generate a table for. See
L<SPOPS::Import::DBI::TableTransform|SPOPS::Import::DBI::TableTransform>
for the listing and types to use.

B<transforms> (\@ of \&, or \&)

Register with the import object one or more code references that will
get called to modify a SQL statement. See L<CUSTOM TRANSFORMATIONS>
below.

B<print_only> (boolean)

If set to true, the final table will be printed to STDOUT rather than
sent to a database.

B<return_only> (boolean)

If set to true, the final table will be returned from C<run()> rather
than sent to a database.

=head1 CUSTOM TRANSFORMATIONS

As the example in L<SYNOPSIS> indicates, you can register perl code to
modify the contents of a table before it is displayed or sent to a
database. When called the code will get three arguments:

=over 4

=item 1. an object that is a subclass of
L<SPOPS::Import::DBI::TableTransform|SPOPS::Import::DBI::TableTransform>
for the database type specified

=item 2. a scalar reference to the SQL statement to be transformed

=item 3. the L<SPOPS::Import::DBI::Table|SPOPS::Import::DBI::Table>
object being currently used.

=back

Most of the transformation code will be very simple, along the lines
of:

 sub my_transform {
    my ( $self, $sql, $importer ) = @_;
    $$sql =~ s/%%THIS_KEY%%/THAT SQL EXPRESSION/g;
 }

=head1 BUILT-IN TRANSFORMATIONS

These are the built-in transformations:

B<increment>

Key: %%INCREMENT%%

Replaces the key with an expression to generate a unique ID value with
every INSERT. Some databases accomplish this with a sequence, others
with an auto-incrementing value.

B<increment_type>

Key: %%INCREMENT_TYPE%%

Datatype of the increment field specified by %%INCREMENT%%. This is
necessary when you are creating foreign keys (logical or enforced) and
need to know the datatype of the ID you are referencing.

B<datetime>

Key: %%DATETIME%%

Datatype of the field that holds a date and time value. This should
B<not> be automatically set with every insert/update (as it is with
MySQL).

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::Manual::ImportExport|SPOPS::Manual::ImportExport>

L<SPOPS::Import::DBI::TableTransform|SPOPS::Import::DBI::TableTransform>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
