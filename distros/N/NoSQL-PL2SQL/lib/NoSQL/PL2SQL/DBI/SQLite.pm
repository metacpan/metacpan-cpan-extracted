use NoSQL::PL2SQL::DBI::MySQL ;
use NoSQL::PL2SQL::DBI::SQLite ;

package NoSQL::PL2SQL::DBI::SQLite ;
use base qw( NoSQL::PL2SQL::DBI ) ;

my $xmlschema =<<'endschema' ;
<mysql>
  <sql>
    <table command="CREATE" table="%s">
      <column name="id" type="INTEGER">
	  <PRIMARY />
	  <KEY />
      </column>
      <column name="objectid" type="INTEGER" />
      <column name="objecttype" type="TEXT" length="40" />
      <column name="stringrepr" type="TEXT" length="40" />
      <column name="intdata" type="INTEGER" />
      <column name="doubledata" type="DOUBLE" />
      <column name="stringdata" type="TEXT" length="512" />
      <column name="textkey" type="TEXT" length="256" />
      <column name="intkey" type="INTEGER" />
      <column name="blesstype" type="TEXT" length="40" />
      <column name="reftype" type="TEXT" length="10">
	  <NOT /><NULL />
      </column>
      <column name="item" type="INTEGER">
	  <UNSIGNED />
      </column>
      <column name="refto" type="INTEGER">
	  <UNSIGNED />
      </column>
      <column name="chainedstring" type="INT">
	  <UNSIGNED />
      </column>
      <column name="defined" type="INTEGER" />
      <column name="deleted" type="INTEGER" />
    </table>
  </sql>
  <sql>
    <index name="%s_reference" command="CREATE" table="%s">
      <column name="objectid" />
      <column name="objecttype" />
      <column name="reftype" />
    </index>
  </sql>
</mysql>
endschema

my $indexschema =<<'endschema' ;
<mysql>
  <sql>
    <table command="CREATE" table="%s">
      <column name="textkey" type="INTEGER" />
      <column name="intkey" type="INTEGER" />
      <column name="datekey" type="INTEGER" />
      <column name="textvalue" type="TEXT" length="128" />
      <column name="intvalue" type="INTEGER" />
      <column name="datevalue" type="TEXT" />
      <column name="objectid" type="INTEGER" />
    </table>
  </sql>
  <sql>
    <index name="%s_all" command="CREATE" table="%s">
      <column name="textkey" />
      <column name="intkey" />
      <column name="datekey" />
      <column name="textvalue" />
      <column name="intvalue" />
      <column name="datevalue" />
      <column name="objectid" />
    </index>
  </sql>
</mysql>
endschema

sub schema {
	my $self = shift ;
	my $schema = @_? shift( @_ ): $xmlschema ;
	return NoSQL::PL2SQL::DBI::schema( $self, $schema ) ;
	}

sub indexschema {
	return $indexschema ;
	}

sub stringencode {
	my $self = shift ;
	my $text = shift ;
	return $text unless defined $text ;
	return $text if @_ && $_[0] ;
	$text =~ s/"/""/gs ;
	return $text ;
	}

package NoSQL::PL2SQL::DBI::SQLite::Schema ;
use base qw( NoSQL::PL2SQL::DBI::Schema ) ;

package NoSQL::PL2SQL::DBI::SQLite::Schema::table ;
use base qw( NoSQL::PL2SQL::DBI::MySQL::Schema::table ) ;

package NoSQL::PL2SQL::DBI::SQLite::Schema::table::column ;
use base qw( NoSQL::PL2SQL::DBI::MySQL::Schema::table::column ) ;

package NoSQL::PL2SQL::DBI::SQLite::Schema::index ;
use base qw( NoSQL::PL2SQL::DBI::MySQL::Schema::index ) ;

package NoSQL::PL2SQL::DBI::SQLite::Schema::index::column ;
use base qw( NoSQL::PL2SQL::DBI::MySQL::Schema::index::column ) ;

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

NoSQL::PL2SQL::DBI::SQLite - SQLite driver for NoSQL::PL2SQL

=head1 SYNOPSIS

  package AnyClass ;
  use base qw( NoSQL::PL2SQL ) ;
  use NoSQL::PL2SQL::DBI::SQLite ;

  ## define a data source
  my $dsn = new NoSQL::PL2SQL::DBI::SQLite $tablename ;

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

NoSQL::PL2SQL::DBI::SQLite creates a SQLite database datasource for NoSQL::PL2SQL.

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
