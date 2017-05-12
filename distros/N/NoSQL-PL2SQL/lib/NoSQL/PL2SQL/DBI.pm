package NoSQL::PL2SQL::DBI::Null ;

sub AUTOLOAD {
	my $self = shift ;
	my $sql = shift ;
	return $sql ;
	}

sub DESTROY {}

package NoSQL::PL2SQL::DBI ;

use 5.008009;
use strict;
use warnings;
use DBI ;
use XML::Parser::Nodes ;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use NoSQL::PL2SQL::Node ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] ) ;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;

our @EXPORT = qw() ;

our $VERSION = '0.12';

# Preloaded methods go here.

my @sqllog ;
my $nulldbi = bless \( my $null = 'NoSQL::PL2SQL::DBI::Null' ), 
			'NoSQL::PL2SQL::DBI::Null' ;

## I started looking for an XML based schema that is implementation
## independent.  This one, my own invention and based on MySQL, was
## originally a placeholder.  Suffice that it remains a TODO...

my $xmlschema =<<'endschema' ;
<mysql>
  <sql>
    <table command="CREATE" table="%s">
      <column name="id" type="INT">
	  <PRIMARY />
	  <KEY />
	  <AUTO_INCREMENT />
      </column>
      <column name="objectid" type="INT" />
      <column name="objecttype" type="VARCHAR" length="40" />
      <column name="stringrepr" type="VARCHAR" length="40" />
      <column name="intdata" type="INT" />
      <column name="doubledata" type="DOUBLE" />
      <column name="stringdata" type="VARCHAR" length="512" />
      <column name="textkey" type="VARCHAR" length="256" />
      <column name="intkey" type="INT" />
      <column name="blesstype" type="VARCHAR" length="40" />
      <column name="reftype" type="VARCHAR" length="10">
	  <NOT /><NULL />
      </column>
      <column name="item" type="INT">
	  <UNSIGNED />
      </column>
      <column name="refto" type="INT">
	  <UNSIGNED />
      </column>
      <column name="chainedstring" type="INT">
	  <UNSIGNED />
      </column>
      <column name="defined" type="TINYINT" />
      <column name="deleted" type="TINYINT" />
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
      <column name="textkey" type="INT" />
      <column name="intkey" type="INT" />
      <column name="datekey" type="INT" />
      <column name="textvalue" type="VARCHAR" length="128" />
      <column name="intvalue" type="INT" />
      <column name="datevalue" type="DATE" />
      <column name="objectid" type="INT" />
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
	my $package = ref $self || $self ;
	my $schema = @_? shift( @_ ): $xmlschema ;

	my $nodes = bless XML::Parser::Nodes->new( $schema ), 
			join( '::', $package, 'Schema' ) ;

	return $nodes->schema ;
	}

## indexschema is used by NoSQL::PL2SQL::Simple.  No one has expressed
## an intention of another DBI implementation.  Since I can get away with 
## it, I'm arbitrarily extending this definition, and I really shouldn't.
## In the future apps, will have to create their own database specific 
## subclasses:  NoSQL::PL2SQL::Simple::MySQL, etc.

sub indexschema {
	return $indexschema ;
	}

sub sqldump {
	shift @_ ;
	@sqllog = () if @_ ;
	return @sqllog ;
	}

sub debug {
	push @sqllog, $_[-1] if @_ ;
	}

sub sqlstatement {
	my $self = shift ;
	my $sprintf = shift ;

	my $ct = 0 ;
	$ct++ while $sprintf =~ /%s/g ;
	return sprintf $sprintf, ( $self->[1] ) x$ct ;
	}

sub do  {
	my $self = shift ;
	push @sqllog, my $sql = $self->sqlstatement( @_ ) ;
	return $self->db->do( $sql ) ;
	}

sub rows_hash {
	my $self = shift ;
	push @sqllog, my $sql = $self->sqlstatement( @_ ) ;
	my $st = $self->db->prepare( $sql ) ;
	$st->execute ;
	my @out = () ;
	my $o ;
	push @out, { %$o } while $o = $st->fetchrow_hashref ;
	return $out[0] unless wantarray ;
	return @out ;
	}

sub rows_array {
	my $self = shift ;
	push @sqllog, my $sql = $self->sqlstatement( @_ ) ;
	my $st = $self->db->prepare( $sql ) ;
	$st->execute ;
	my @out = () ;
	my $o ;
	push @out, [ @$o ] while $o = $st->fetchrow_arrayref ;
	return $out[0] unless wantarray ;
	return @out ;
	}

sub new {
	my $package = shift ;
	my $tablename = shift( @_ ) || '%s' ;

	if ( ref $package ) {
		$tablename = $package->table ;
		$package = ref $package ;
		}

	return bless [ $nulldbi, $tablename ], $package ;
	}

sub connect {
	my $self = shift ;
	my $ref = $self ;
	$ref = $ref->[0] while ref $ref eq ref $self
				&& ref $ref->[0] eq ref $self ;
	$ref->[0] = DBI->connect( @_ ) ;
	return $self ;
	}

sub table {
	my $self = shift ;
	return $self->[1] unless @_ ;

	my $package = ref $self ;
	my $out = $package->new( @_ ) ;
	$out->[0] = $self ;
	return $out ;
	}

sub db {
	my $self = shift ;
	return ref $self->[0] eq ref $self? $self->[0]->db: $self->[0] ;
	}

sub dbconnected {
	my $self = shift ;
	my $db = $self->db ;
	my $unconnected = $db->isa('SCALAR') && $$db eq ref $db ;
	return ! $unconnected ;
	}

## Implementation Specific
## optionally pass a scalar integer- otherwise same arguments as fetch()
sub delete {
	my $self = shift ;
	my @delete = ref $_[0]? @_: ( [ id => $_[0] ] ) ;
	return $self->fetch( 'DELETE FROM %s WHERE', @delete ) ;
	}

## Implementation Specific
sub lastinsertid {
	my $self = shift ;
	my $db = $self->db ;
	return ! $self->dbconnected? 0:
			$db->last_insert_id( 
			  undef, undef, $self->table, 'id' ) ;
	}

## Implementation Specific
sub sqlupdate {
	my $self = shift ;
	my $nvp = shift ;
	my $sql = sprintf 'UPDATE %s SET %s WHERE', '%s', $nvp ;
	return $self->fetch( $sql, @_ ) ;
	}

## update() method is used for SQL "INSERT" and "UPDATE" constructions.
## Implementation Specific.  Default method is MySQL syntax.
sub update {
	my $self = shift ;
	my $id = shift ;

##	Each subsequent argument is an NVP array reference.  An optional
##	third element, if true, indicates a string value

	my @pairsf = ( '%s=%s', '%s="%s"', '%s=NULL' ) ;
	my @termsf = ( '%s', '"%s"', 'NULL' ) ;

	my $keys = join ',', map { $_->[0] } @_ ;
	my $values = join ',', map {
			sprintf $termsf[ defined $_->[1]? 
			  $_->[2] || length $_->[1] == 0: 2 ], 
			$self->stringencode( $_->[1], ! $_->[2] ) ; 
			} @_ ;
	my $nvp = join ',', map {
			sprintf $pairsf[ defined $_->[1]? 
			  $_->[2] || length $_->[1] == 0: 2 ], 
			$_->[0], $self->stringencode( $_->[1], ! $_->[2] )
			} @_ ;

	## User data should never be passed to sqlstatement()
	my $update = $self->sqlstatement( 'UPDATE %s' ) ;
	my $insert = $self->sqlstatement( 'INSERT INTO %s' ) ;
	my $sql = defined $id? 
			"$update SET $nvp WHERE id=$id":
			"$insert ($keys) VALUES ($values)" ;
	$self->debug( $sql ) if $self->dbconnected ;
	my $sqlresults = $self->db->do( $sql ) ;	## do not combine
	return { id => $id || $self->lastinsertid,
			sqlresults => $sqlresults,
			nvp => $nvp
			} ;
	}

sub insert {
	my $self = shift ;
	return $self->update( undef, @_ ) ;
	}

sub exclude {
	shift @_ ;
	my $package = join '::', __PACKAGE__, 'exclude' ;
	my @out = map { bless $_, $package } @_ ;
	return wantarray? @out: $out[0] ;
	}

## Implementation Specific.  Default method is MySQL syntax.
sub fetch {
	my $self = shift ;
	my $delete = ( @_ && ! ref $_[0] )? shift( @_ ): undef ;

	my @pairsf = ( '%s=%s', '%s="%s"', '%s=NULL' ) ;
	my @invert = ( '%s!=%s', '%s!="%s"', '%s NOT NULL' ) ;

	my $exclude = ref $self->exclude( [] ) ;

	my @terms = () ;
	foreach ( @_ ) {
		my @how = ref $_ eq $exclude? @invert: @pairsf ;
		push @terms, sprintf 
				$how[ defined $_->[1]? 
				  $_->[2] || length $_->[1] == 0: 2 ],
				$_->[0], 
				$self->stringencode( $_->[1], ! $_->[2] ) ;
		}

	my $sql = join ' ', $delete || 'SELECT * FROM %s WHERE',
			join ' AND ', @terms ;
	return $self->do( $sql ) if defined $delete || ! $self->dbconnected ;

	my @out = $self->rows_hash( $sql ) ;
	return wantarray? @out: { map { $_->{id} => $_ } @out } ;
	}

## Implementation Specific.  Default method is MySQL syntax.
sub stringencode {
	my $self = shift ;
	my $text = shift ;
	return $text unless defined $text ;
	return $text if @_ && $_[0] ;
	$text =~ s/"/""/gs ;
	$text =~ s/\\/\\\\/gs ;
	return $text ;
	}

sub AUTOLOAD {
	my $self = shift ;
	my $sql = shift ;
	my $package = ref $self ;

	use vars qw( $AUTOLOAD ) ;
	my $func = $AUTOLOAD ;
	$func =~ s/^${package}::// ;
	return if $func eq 'DESTROY' ;

	my $cmd = sprintf '$self->db->%s( sprintf $sql || "", $self->table )', 
			$func ;
	return eval $cmd ;
	}

sub loadschema {
	my $self = shift ;
	return map { $self->do( $_ ) } $self->schema( @_ ) ;
	}


package NoSQL::PL2SQL::DBI::Schema ;
use base qw( XML::Parser::Nodes ) ;

sub schema {
	shift @_ unless ref $_[0] ;
	my $self = shift ;

	my @mysql = $self->childnode('mysql') ;
	return map { $self->new( $_ )->schema } 
			@mysql? $mysql[0]->childnodes: $self->childnodes ;
	}

sub new {
	my $self = shift ;
	my $nodechild = shift ;
	my $package = ref $self ;
	my @package = () ;

	my @nodenames = () ;
	my @refself = split /::/, $package ;
	push @nodenames, pop @refself 
			while @refself && $refself[-1] ne 'Schema' ;

	push @package, join '::', $package, $nodechild->[0] ;
	return bless $nodechild->[1], $package[-1]
			if eval join '', '@', $package[-1], '::ISA' ;

	push @package, join '::', __PACKAGE__, @nodenames, $nodechild->[0] ;
	return bless $nodechild->[1], $package[-1]
			if eval join '', '@', $package[-1], '::ISA' ;

	return bless $nodechild->[1], join '::', @refself ;
	}

sub command {
	my $self = shift ;
	my $command = $self->getattributes->{command} || '' ;

	return eval sprintf '$self->%s()', $command if $command ;
	}

## Example Base Node Schemas
#
# package NoSQL::PL2SQL::DBI::Schema::table ;
# use base qw( NoSQL::PL2SQL::DBI::Schema ) ;
# 
# sub schema {
# 	shift @_ unless ref $_[0] ;
# 	my $self = shift ;
# 
# 	## default table definition
# 	}
# 
# package NoSQL::PL2SQL::DBI::Schema::index ;
# use base qw( NoSQL::PL2SQL::DBI::Schema ) ;
# 
# sub schema {
# 	shift @_ unless ref $_[0] ;
# 	my $self = shift ;
# 
# 	## default index definition
# 	}
# 
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

NoSQL::PL2SQL::DBI - Base Perl RDB driver for NoSQL::PL2SQL

=head1 SYNOPSIS

  ## Typical usage for PL2SQL

    package MyArbitraryClass ;
    use base qw( NoSQL::PL2SQL ) ;
    use NoSQL::PL2SQL::DBI::123SQL ;

  ## Primary PL2SQL operations

    my $dsn = new NoSQL::PL2SQL::DBI::123SQL $tablename ;
    $dsn->connect( $data_source, $username, $auth, \%attr ) ;
    $dsn->do('DROP TABLE %s') ;
    $dsn->loadschema ;

  ## Definition of 123SQL

    package NoSQL::PL2SQL::DBI::123SQL ;
    use base qw( NoSQL::PL2SQL::DBI ) ;

  ## Construction operation methods 

    $dsn->loadschema( $xmlschema ) ;

    ## These two statements are nearly equivalent.  Except the schema
    ## method never performs table name substitution.
    $dsn->schema( $xmlschema ) ;
    $dsn->new->loadschema( $xmlschema ) ;

  ## Conditional operation methods

    my @conditions = ( [ $name, $value, $isstring ], ... ) ;
    my @exclusions = $dsn->exclude( [ $name, $value, $isstring ], ... ) ;

    my @rows = $dsn->fetch( @conditions, @exclusions ) ;
    my $perldata = $dsn->fetch( @conditions, @exclusions ) ;
    $dsn->delete( @conditions, @exclusions ) ;

    $dsn->delete( $id ) ;	## Equivalent to the statement below
    $dsn->delete( [ id => $id ] ) ;

  ## Data assignment operation methods

    my @nvp = ( [ $name, $value, $isstring ], ... ) ;

    my $results = $dsn->insert( @nvp ) ;
    my $results = $dsn->update( $recordid, @nvp ) ;

  ## Combined operation methods

    $dsn->sqlupdate( 
		$dsn->new->update( undef => @nvp )->{nvp},
		@conditions ) ;

  ## Internally used methods
  
    my $response = $dsn->do( $sqltext ) ;
    my $encoded = $dsn->encodestring( $text ) ;
    my $recno = $dsn->lastinsertid ;
    my @sql = $dsn->schema ;
  
  ## Utilities and debugging

    $dsn->sqldump( $reset = 1 ) ;
    $dsn->debug( $arbitrarystring ) ;
    print join "\n", $dsn->sqldump() ;

    my @fetchrows = $dsn->rows_hash('SELECT * FROM %s WHERE objectid=1') ;
    my @fetchrows = $dsn->rows_array('SELECT * FROM %s WHERE objectid=1') ;

    my $sql = $dsn->sqlstatement( $sqlarg ) ;
    my $db = $dsn->db ;
    my $tablename = $dsn->table ;

=head1 DESCRIPTION

NoSQL::PL2SQL::DBI was developed as part of NoSQL::PL2SQL to provide an abstract representation of an RDB table.  Database specific implementations should be defined as subclasses to account for differences in SQL syntax, data definitions and features.  

NoSQL::PL2SQL users only need the constructor and the 3 methods listed above as "Primary PL2SQL operations".  In the PL2SQL interface, a NoSQL::PL2SQL::DBI instance is used to represent a data source.

A NoSQL::PL2SQL::DBI instance represents a single table in an RDB, with two properties:  A database handle and a string to reference a particular table.  Thus, there are a couple accessor methods, but mostly this class is responsible for the SQL translation.

PL2SQL simply provides a persistance mechanism for Perl objects that's tied to an RDB table.  Its interface is implemented primarily as declarations and definitions, with only a handful of procedural operations- there's no correspondence between an SQL operation (eg SELECT) and a PL2SQL function call (eg fetch).  Internally, of course, PL2SQL needs some SQL interface.  This functionality is consolidated in the NoSQL::PL2SQL::DBI package.  Consquently, users who want a translator for low-level database access can use NoSQL::PL2SQL::DBI directly.

There are basically four types of operations:

=head3 Construction Operations

Operations such as SQL I<CREATE> that are not called as part of normal operation require a bit more preparation.  The PL2SQL::DBI method C<loadschema()> performs these functions. Its single argument contains all the definitions as block of XML text.

=head3 Conditional Operations

Operations such as SQL I<SELECT> and I<DELETE> use defined conditionals.  The corresponding PL2SQL::DBI methods are C<fetch()> and C<delete()>.

=head3 Data Assignment Operations

Operations such as SQL I<INSERT> use only NVP's (name value pairs) to correspond to the data assignments.  SQL I<UPDATE> also falls into this category when the changes are to be applied to a single row record.  The corresponding PL2SQL::DBI methods are C<insert()> and C<update()>.

=head3 Combined Operations

When a SQL I<UPDATE> request needs to be applied to multiple row records, both NVP and Conditional definitions are required.  This operation is seldom required, and is a bit more cumbersome.  The corresponding PL2SQL::method is C<sqlupdate()>.

The methods listed above require arguments to define the conditionals and NVP's.  Each conditional or NVP term is represented by an array consisting of a name, value, and optional boolean that explicity identifies the value as a string.  An undefined value corresponds to an SQL NULL.  Multiple terms can be passed to these methods.

A conditional term can be defined as an exclusion using the C<exclude()> command.  Exclusion conditionals are treated as logical inversions.

The C<update()> method has a special requirement:  The first argument must be a scalar that identifies a particular table row record or the resulting SQL has no conditional clause.

The C<fetch()> method returns data instead of a confirmation count.  In an array context, C<fetch()> returns records in the same format as C<DBI::fetchrow_hashref()>.  The row data is nearly the same when C<fetch()> is called in a scalar context.  Each row is a value in a hash reference, keyed on the row id.

The C<insert()> and C<update()> methods have been overloaded to return a complex value:

  $results->{id}	record id resulting from an insert operation
  $results->{sql}	sql results of an operation
  $results->{nvp}	the name/values clause of the SQL translation

The C<sqlupdate()> method requires both conditional and data assignment arguments.  To distinguish between them, the data assignment arguments are first fed into the C<update()> method, the name/values clause is extracted via the result's I<nvp> property, and that string is passed as the first scalar argument to the C<sqlresults()> method.

The ability to extract literal SQL translations is a feature built into every method.  Since the $dsn data source instance needs an active database handle to be effective, a literal SQL translation is returned on every method of an unconnected instance.  This feature can be useful for debugging:

  ## This statement performs a database operation
  $results = $dsn->update( 5, [ stringdata => 20, 1 ] ) ;

  ## This statement does not perform a database operation
  $results = $dsn->new->update( 5, [ stringdata => 20, 1 ] ) ;

  ## The return value may vary in this context
  $response = $dsn->new->fetch( 5 ) ;

In the first two C<update()> examples, the return value has the same structure regardless of whether a database operation has been performed.  I<< $results->{sql} >> contains the results of the operation.  In the first, this value reflects the number of affected table rows.  In the second, this value contains translated SQL.  The difference between the two is that the second example applies the C<update()> method to a transient instance created with the C<new()> constructor.

In C<fetch()>, C<delete()> and the other conditional operation methods, the sql translation is returned directly.  With no database handle, the C<fetch()> results are the same in scalar or array context.

The C<do()> method performs the second half of these operations and applies the translated SQL as a database operation.  Extending the examples above:

  $dsn->do( $results->{sql} ) ;
  $dsn->do( $response ) ;

The C<do()> method always takes a string SQL representation.  Because the table name is embedded as an instance property, the SQL argument may use '%s' in place of the table name.  The C<do()> method automatically performs the substitution.

NoSQL::PL2SQL::DBI acts like a subclass of DBI in that C<AUTOLOAD()> attempts to apply any undefined methods to the internal database handle.  Every invocation is called like the C<do()> method: C<AUTOLOAD> assumes a single string argument, and applies the '%s' table name substitution describe above.

=head1 SCHEMA

Most SQL operations can be easily implemented as simple methods, but we have not yet acknowledged the 800 pound gorilla required to map the SQL I<Create> operations to a function.

The first challenge is that the I<Create> function is fairly complex and implementation dependent.  However, since XML and SQL have many similar properties, XML is used to define generic schemas.  Specific methods are used to translate XML nodes into SQL clauses.  Parent node translations roll all the clauses into a single SQL statement.  NoSQL::PL2SQL::DBI::Schema and its subclasses provide the engine recursing through structured XML.

Overloaded methods can be used for specific translation requirements.  So ideally, the XML definition should be independent of the database implementations.  Unfortunately, C<loadschmema()> only performs a syntactical translation.  Any differences in the definition arising from implementation specific data type definitions or features need to be explicit in the XML definition.

Consequently, the inelegant solution is to use a different XML schema in each of NoSQL::PL2SQL::DBI's implementation subclasses.  Two are actually defined:  In addition to $xmlschema, $indexschema is used by NoSQL::PL2SQL::Simple.  Ultimately, others need to be able to extend PL2SQL with their own data definitions, and also use the features independently of PL2SQL.  However, this problem is currently overshadowed by the need for more DBI subclass implementations.

=head1 IMPLEMENTATION SUBCLASSES

Currently, only MySQL and SQLite implementation subclasses are included in the PL2SQL package.  The remaining discussion is for developers who wish to build new implementation subclasses.

The following methods are implemented, by default, to use an SQL syntax compatible with MySQL and SQLite.  Other RDB implementations may require overriding these methods:

=over 8

=item C<fetch()>

=item C<update()>

=item C<sqlupdate()>

=item C<delete()>

=item C<lastinsertid()>

=item C<stringencode()>

=item Schema definitions

=back

The C<loadschema()> should not be overridden.  The C<schema()> method is responsible for the XML to SQL translation.  Through a subclassing system, each XML node calls a distinct C<schema()> method for translation.

There are two default C<schema()> definitions.  The first, C<< NoSQL::PL2SQL::DBI->schema() >>, converts the XML definition into an XML::Parser::Nodes tree.  This tree is reblessed into another package as follows:

  return bless( $nodes, ref( $dsn ) .'::Schema' )->schema() ;

Consequently, there is a second default schema called C<< NoSQL::PL2SQL::DBI::Schema->schema() >>, (For convenience, these two will be distinguished as C<schema()> and C<< Schema->schema() >>.)  An implementation must be defined as follows, using 123SQL as an example implementation.

  package NoSQL::PL2SQL::DBI::123SQL ;
  use base qw( NoSQL::PL2SQL::DBI ) ;

  package NoSQL::PL2SQL::DBI::123SQL::Schema ;
  use base qw( NoSQL::PL2SQL::DBI::Schema ) ;

By default, C<< Schema->schema() >> calls the schema method on its child nodes.  For example, each SQL statement is represented by an <sql> node.  In order to return an SQL statement, the following must be defined (using the same example):

  package NoSQL::PL2SQL::DBI::123SQL::Schema::sql ;
  use base qw( NoSQL::PL2SQL::DBI::Schema ) ;

This definition, however, is only required for explict SQL translation.  Otherwise, the default C<< Schema->schema() >> method is called in recursion on the next level of child nodes.  The nodes below are shown as XML and with defined methods:

  ## <table command="CREATE" ...>
  ##   <column ... />
  ## </table>

  package NoSQL::PL2SQL::DBI::123SQL::Schema::table ;
  use base qw( NoSQL::PL2SQL::DBI::Schema ) ;

  sub schema {
	my $self = shift ;
	return $self->command ;
	}

  sub CREATE {
	my $self = shift ;
	my @columns = NoSQL::PL2SQL::DBI::Schema->schema( $self ) ;
	## combine columns into a single SQL directive
	}

  package NoSQL::PL2SQL::DBI::123SQL::Schema::table::column ;
  use base qw( NoSQL::PL2SQL::DBI::Schema ) ;

  sub schema {
	my $self = shift ;
	## return column definition
	}

The XML node shown above, named table, is processed by C<< Schema->schema() >>, and its explicitly defined C<< Schema::table->schema() >> method is called.  That method punts to another method, defined by the "command" attribute of the node, and the C<< Schema::table->CREATE() >> method is called in turn.  That method gets its child schemas by calling the default C<< Schema->schema() >> method.  At this point, the package names of the child schemas start accumulating, and each of those C<schema()> methods return substrings that are combined into a single SQL directive.

To summarize, a schema definition requires the definition of a number of package classes.  The package names correlate to the structure of the node tree (see XML::Parser::Nodes::tree()).  Each package class needs to extend C<NoSQL::PL2SQL::DBI::Schema>, and may or may not override the C<schema()> method.  Output can be varied by defining methods that correspond to the "command" attribute.

In general, there's probably no need to define a package unless the C<schema()> method will be overridden.  But consider the following definitions:

  package NoSQL::PL2SQL::DBI::MySQL::Schema ;	## The Schema
  use base qw( NoSQL::PL2SQL::DBI::Schema ) ;	## The Base Schema

  package NoSQL::PL2SQL::DBI::MySQL::Schema::table ;	## A Node Schema
  use base qw( NoSQL::PL2SQL::DBI::Schema ) ;	## The Base Schema

  ## Not defined but part of the model
  package NoSQL::PL2SQL::DBI::Schema::table ;	## A Base Node Schema

For undefined packages, the inheritance order is:

=over 8 

=item Base Node Schema >> Schema >> Base Schema

=back

A package may be defined without an overriding C<schema()> definition in order to define a different inheritance.

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.23 with options

  -AXCO
	NoSQL::PL2SQL

=item 0.02

Cleaned perldoc formatting issues

Added optional arg to C<schema()> method

=item 0.03

Added optional arg to C<schema()> method

=item 0.04

Added C<debug()> method

=item 0.05

Generalized C<fetch()> and C<perldata()> methods to handle arbitrary schemas.

C<perldata()> arguments are now explicitly defined.

C<delete()> now accepts the same arguments as C<fetch()>.

With an argument C<table()> creates a second DSN instance chained via C<db()>.

=item 0.10

Added C<sqlupdate()>.

Added nvp element to C<update()>'s return value.

Fixed a bug in the $xmlschema "CREATE INDEX" node.

Modified C<sqlstatement()>

Added C<indexschema()> for NoSQL::PL2SQL:Simple.

=item 0.11

C<perldata()> now B<always> returns a hash ref and C<fetch()> B<always> returns an array.  In order to combine duplicated functionality, C<perldata()> is now invoked as C<< $dsn->fetch()->perldata >>.

=item 0.12

Added C<exclude()> method.

Removed the pesky C<perldata()> method- this output is now returned by C<fetch()> in scalar context.  NO BACKWARDS COMPATIBILITY.

Rewrote the documentation to reflect less dependence on PL2SQL.

=back

=head1 SEE ALSO

=over 8

=item NoSQL::PL2SQL

=item XML::Parser::Nodes

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
