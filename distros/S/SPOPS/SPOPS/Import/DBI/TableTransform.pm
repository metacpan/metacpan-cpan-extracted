package SPOPS::Import::DBI::TableTransform;

# $Id: TableTransform.pm,v 3.7 2004/06/02 00:48:23 lachoy Exp $

use strict;
use base qw( Class::Factory );
use SPOPS::Exception;

$SPOPS::Import::DBI::TableTransform::VERSION  = sprintf("%d.%02d", q$Revision: 3.7 $ =~ /(\d+)\.(\d+)/);

sub transform {
    my ( $self, $sql ) = @_;
    $self->increment( $sql );
    $self->increment_type( $sql );
    $self->datetime( $sql );
}

my %TYPES = (
 mysql     => 'SPOPS::Import::DBI::TableTransform::MySQL',
 MySQL     => 'SPOPS::Import::DBI::TableTransform::MySQL',
 oracle    => 'SPOPS::Import::DBI::TableTransform::Oracle',
 Oracle    => 'SPOPS::Import::DBI::TableTransform::Oracle',
 pg        => 'SPOPS::Import::DBI::TableTransform::Pg' ,
 Pg        => 'SPOPS::Import::DBI::TableTransform::Pg' ,
 postgres  => 'SPOPS::Import::DBI::TableTransform::Pg',
 asany     => 'SPOPS::Import::DBI::TableTransform::Sybase',
 ASAny     => 'SPOPS::Import::DBI::TableTransform::Sybase',
 MSSQL     => 'SPOPS::Import::DBI::TableTransform::Sybase',
 mssql     => 'SPOPS::Import::DBI::TableTransform::Sybase',
 sybase    => 'SPOPS::Import::DBI::TableTransform::Sybase',
 Sybase    => 'SPOPS::Import::DBI::TableTransform::Sybase',
 sqlite    => 'SPOPS::Import::DBI::TableTransform::SQLite',
 SQLite    => 'SPOPS::Import::DBI::TableTransform::SQLite',
 interbase => 'SPOPS::Import::DBI::TableTransform::InterBase',
 InterBase => 'SPOPS::Import::DBI::TableTransform::InterBase',
 Firebird  => 'SPOPS::Import::DBI::TableTransform::InterBase',
);

sub class_initialize {
    while ( my ( $type, $class ) = each %TYPES ) {
        __PACKAGE__->register_factory_type( $type, $class );
    }
}

class_initialize();

1;

__END__

=head1 NAME

SPOPS::Import::DBI::TableTransform - Factory class for database-specific transformations

=head1 SYNOPSIS

 my $table = qq/ CREATE TABLE blah ( id %%INCREMENT%% primary key,
                                     name varchar(50) ) /;
 my $transformer = SPOPS::Import::DBI::TableTransform->new( 'sybase' );
 $transformer->increment( \$table );
 print $table;

=head1 DESCRIPTION

This class is a factory class for database-specific
transformations. This means that
L<SPOPS::Import::DBI::Table|SPOPS::Import::DBI::Table> supports
certain keys that can be replaced by database-specific values. This
class is a factory for objects that take SQL data and do the
replacements.

=head1 METHODS

B<new( $database_type )>

Create a new transformer using the database type C<$database_type>.

Available database types are:

=over 4

=item asany: Sybase Adaptive Server Anywhere

=item interbase: InterBase family (also: 'firebird')

=item mssql: Microsoft SQL Server

=item mysql: MySQL

=item oracle: Oracle

=item postgres: PostgreSQL (also: 'pg')

=item sybase: Sybase SQL Server/ASE

=back

B<register_factory_type( $database_type, $transform_class )>

Registers a new database type for a transformation class. You will
need to run this every time you run the program.

If you develop a transformation class for a database not represented
here, please email the author so it can be included with future
distributions.

=head1 CREATING A TRANSFORMATION CLASS

Creating a new subclass is extremely easy. You just need to subclass
this class, then create a subroutine for each of the built-in
transformations specified in
L<SPOPS::Import::DBI::Table|SPOPS::Import::DBI::Table>.

Each transformation takes two arguments: C<$self> and a scalar
reference to the SQL to be transformed. For example, here is a
subclass for a made-up database:

 package SPOPS::Import::DBI::TableTransform::SavMor;

 use strict;
 use base qw( SPOPS::Import::DBI::TableTransform );

 sub increment {
    my ( $self, $sql ) = @_;
    $$sql =~ s/%%INCREMENT%%/UNIQUE_VALUE/g;
 }

 sub increment_type {
    my ( $self, $sql ) = @_;
    $$sql =~ s/%%INCREMENT_TYPE%%/INT/g;
 }

 sub datetime {
    my ( $self, $sql ) = @_;
    $$sql =~ s/%%DATETIME%%/timestamp/g;
 }

 1;

And then we could register the transformation agent with every run:

 SPOPS::Import::DBI::TableTransform->register_factory_type(
          'savmor', 'SPOPS::Import::DBI::TableTransform::SavMor' );
 my $transformer = SPOPS::Import::DBI::TableTransform->new( 'savmor' );
 my $sql = qq/ CREATE TABLE ( id %%INCREMENT%% primary key ) /;
 $transformer->increment( \$sql );
 print $sql;

Output:

 CREATE TABLE ( id UNIQUE_VALUE primary key )

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::Import::DBI::Table|SPOPS::Import::DBI::Table>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
