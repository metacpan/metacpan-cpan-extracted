package NoSQL::PL2SQL::DBI::MySQL ;
use base qw( NoSQL::PL2SQL::DBI ) ;

## The following methods construct SQL messages and may need to be modified
## for different implementations

# sub fetch {}
# sub update {}
# sub delete {}
# sub lastinsertid {}

###############################################################################
##
##  Schema:		NoSQL::PL2SQL::DBI::MySQL
##  Base Schema:	NoSQL::PL2SQL::DBI
##  Schema Node:	NoSQL::PL2SQL::DBI::MySQL::table::column
##  Base Schema Node:	NoSQL::PL2SQL::DBI::table::column
##
##  The schema method is called for every node in the XML definition.  The
##  base schema class is called on the top node, and any node without a
##  schema class definition.
##
##  If a Schema Node class is undefined altogether, the inheritance order is
##  as follows:
##	Base Schema Node
##	Schema
##	Base Schema
##
##  If a Schema Node class is defined, but the schema() method is not, 
##  inheritance drops immediately to the Base Schema.  The default schema()
##  method, defined in the Base Schema, returns the schema results of its
##  child nodes.  Therefore, definitions are only required from the lowest 
##  level nodes containing the relevant data.
##
###############################################################################


package NoSQL::PL2SQL::DBI::MySQL::Schema ;
use base qw( NoSQL::PL2SQL::DBI::Schema ) ;

## A Schema class must be defined although the base methods should always
## be adequate.  

## No need to override.
# sub schema {
#	my $self = shift ;
#	}

package NoSQL::PL2SQL::DBI::MySQL::Schema::table ;
use base qw( NoSQL::PL2SQL::DBI::Schema ) ;

sub schema {
	my $self = shift ;
	return $self->command
			|| NoSQL::PL2SQL::DBI::Schema->schema( $self ) ;
	}

sub CREATE {
	my $self = shift ;
	my $elements = {} ;

	my @terms = () ;
	push @terms, $self->getattributes->{command}, 'TABLE' ;
	push @terms, $self->getattributes->{table} ;
	push @terms, sprintf '( %s )', join ', ',
			NoSQL::PL2SQL::DBI::Schema->schema( $self ) ;

	return join ' ', @terms ;
	}

package NoSQL::PL2SQL::DBI::MySQL::Schema::table::column ;
use base qw( NoSQL::PL2SQL::DBI::Schema ) ;

sub schema {
	my $self = shift ;

	my @terms = () ;
	my $attribs = $self->getattributes ;

	push @terms, $attribs->{name} ;
	push @terms, $attribs->{type} if exists $attribs->{type} ;
	$terms[-1] .= sprintf '(%d)', $attribs->{length}
			if exists $attribs->{length} ;

	push @terms, $self->taglist ;
	return join ' ', @terms ;
	}

package NoSQL::PL2SQL::DBI::MySQL::Schema::index ;
use base qw( NoSQL::PL2SQL::DBI::Schema ) ;

sub schema {
	my $self = shift ;
	return $self->command
			|| NoSQL::PL2SQL::DBI::Schema->schema( $self ) ;
	}

sub CREATE {
	my $self = shift ;

	my @terms = () ;
	push @terms, $self->getattributes->{command}, 'INDEX' ;
	push @terms, $self->getattributes->{name} ;
	return () unless $self->getattributes->{table} ;
	push @terms, ( ON => $self->getattributes->{table} ) ;
	push @terms, sprintf '( %s )', join ', ',
			NoSQL::PL2SQL::DBI::Schema->schema( $self ) ;

	return join ' ', @terms ;
	}

package NoSQL::PL2SQL::DBI::MySQL::Schema::index::column ;
use base qw( NoSQL::PL2SQL::DBI::MySQL::Schema::table::column ) ;

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

NoSQL::PL2SQL::DBI::MySQL - MySQL driver for NoSQL::PL2SQL

=head1 SYNOPSIS

  package AnyClass ;
  use base qw( NoSQL::PL2SQL ) ;
  use NoSQL::PL2SQL::DBI::MySQL ;

  ## define a data source
  my $dsn = new NoSQL::PL2SQL::DBI::MySQL $tablename ;

  ## connect
  $dsn->connect( $data_source, $username, $auth, \%attr ) ;

  ## access
  my $object = AnyClass->SQLObject( $dsn, $objectid ) ;

  ## create a data source
  $dsn->loadschema ;

  ## utilities
  $dsn->do('DROP TABLE %s') ;
  $dsn->do('DELETE FROM %s') ;

  my @fetchrows = $dsn->rows_hash('SELECT * FROM %s WHERE objectid=1') ;
  my @fetchrows = $dsn->rows_array('SELECT * FROM %s WHERE objectid=1') ;

=head1 DESCRIPTION

NoSQL::PL2SQL::DBI::MySQL creates a MySQL database datasource for NoSQL::PL2SQL.

Developers who are comfortable with RDB can design a thin object interface using any number of tools, such as DBIx::Class.  NoSQL::PL2SQL is designed for developers of thicker objects that may be more logical and require data flexibility.  For these developers, where the database is merely a mechanism for object persistance, NoSQL::PL2SQL provides a simple abstraction with a trivial interface, and great portability.

One of NoSQL::PL2SQL's features is a "universal" table definition that can accomodate arbitrary and indeterminate data structures.  This flexibility means that a single table can be used for heterogeneous instantiations of different classes.  In many cases, a single table can serve the data needs of an entire application.  Consequently, a NoSQL::PL2SQL::DBI object is primarily defined by the tablename using a constructor argument.

The driver object contains only one other property, a database handle, which is defined using the C<connect()> method with the same arguments as the default C<< DBI->connect() >> method.  Otherwise, the default handle is a NoSQL::PL2SQL::DBI::Null object that simply reflects statement arguments, and can be useful for debugging.

This object can also invoke any DBI method.  SQL statement arguments do not need to specify a table name which is a property of the driver object.  Use the C<sprintf()> notation '%s' intead.

Additionally, NoSQL::PL2SQL::DBI provides versions of C<< DBI->fetchrow_arrayref() >> and C<< DBI->fetchrow_hashref >>- C<rows_array()> and C<rows_hash()> respectively.  These methods take an SQL statement as an argument, perform preparation and execution, and return the same output as their counterparts.

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 0.01


=back



=head1 SEE ALSO

=over 8

=item NoSQL::PL2SQL

=item NoSQL::PL2SQL::DBI

=item http://pl2sql.tqis.com/

=back

=head1 AUTHOR

Jim Schueler, E<lt>jim@tqis.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jim Schueler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
