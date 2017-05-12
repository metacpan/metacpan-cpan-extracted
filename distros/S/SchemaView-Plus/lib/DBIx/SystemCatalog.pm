package DBIx::SystemCatalog;

use strict;
use DBI;
use Exporter;
use vars qw/$VERSION @ISA @EXPORT/;

$VERSION = '0.06';
@ISA = qw/Exporter/;
@EXPORT = qw/SC_TYPE_TABLE SC_TYPE_VIEW SC_TYPE_UNKNOWN/;

=head1 NAME

DBIx::SystemCatalog - Perl module for accessing system catalog in common databases (access through DBI(3))

=head1 SYNOPSIS

	use DBI;
	use DBIx::SystemCatalog;

	# create DBIx::SystemCatalog object and bind DBI
	my $dbh = DBI->connect('dbi:Oracle:','login','password');
	my $catalog = new DBIx::SystemCatalog $dbh;

	# fetch all database schemas
	my @schemas = $catalog->schemas;

	# select one schema (e.g. first schema)
	$catalog->schema($schemas[0]);

	# fetch all tables and views with types of objects
	my @tables = $catalog->tables_with_types;

	# fetch columns of first fetched table
	my @columns = $catalog->table_columns($tables[0]->{name});

	# fetch all relationships between tables and views
	my @relationships = $catalog->relationships;
  
	# fetch all primary keys for table
	my @primary_keys = $catalog->primary_keys($tables[0]->{name});

	# fetch all unique indexes for table
	my @unique_indexes = $catalog->unique_indexes($tables[0]->{name});

	# fetch all indexes for table
	my @indexes = $catalog->indexes($table[0]->{name});

	# disconnect database
	$dbh->disconnect;

=head1 DESCRIPTION

This module can access to system catalog of database through DBI(3) interface.
Basic methods access to objects through standard DBI(3) interface 
(call C<tables()> for list of objects and C<selectall_arrayref()> with basic
SQL to get structure of objects).

Constructor looks for specific module implemented database interface for
used DBD driver (obtained from DBI(3)). These module can add faster and better
functions such as relationships or types of objects.

=head1 CONSTANTS

=head2 Type of object

=over 4

=item SC_TYPE_UNKNOWN

=cut

sub SC_TYPE_UNKNOWN () { return 0; }

=item SC_TYPE_TABLE

=cut

sub SC_TYPE_TABLE () { return 1; }

=item SC_TYPE_VIEW

=back

=cut

sub SC_TYPE_VIEW () { return 2; }

=head1 THE DBIx::SystemCatalog CLASS

=head2 new (DBI)

Constructor create instance of this class and bind DBI(3) connection.
Then obtain used driver name from DBI(3) class and look for descendant
of this class for this driver (e.g. C<DBIx::SystemCatalog::Oracle> module
for C<Oracle> driver). If success, return instance of this more specific class,
otherwise return itself.

You must passed connected DBI(3) instance as first argument to constructor
and you can't disconnect that instance while you use this instance of
DBIx::SystemCatalog.

	$catalog = new DBIx::SystemCatalog $dbh

=cut

sub new {
	my $class = shift;
	my $dbi = shift;
	my $obj = bless { dbi => $dbi, class => $class, schema => '' },$class;
	$obj->{Driver} = $obj->{dbi}->{Driver}->{Name};

	# Only base class can dispatch to more specific class
	if ($class eq 'DBIx::SystemCatalog') {
		my $driver_name = 'DBIx::SystemCatalog::'.$obj->{Driver};
		eval "package DBIx::SystemCatalog::_safe; require $driver_name";
		unless ($@) {	# found specific driver
			$driver_name->import();
			return $driver_name->new($dbi,@_);
		}
	}

	# Hmm, we are specific class or specific class not found
	return undef unless $obj->init(@_);
	return $obj;
}

=head2 init

Because C<new()> is quite complicated, descendant inherits this C<new()>
constructor and redefine C<init()> constructor which is called from C<new()>.

C<init()> gets all arguments from C<new()> with one exception - instead of
name of class this constructor get instance of object.

Constructor must return true value to make successful of creating instance
of object. In this base class is C<init()> abstract, always true.

This method isn't called directly from user.

=cut

sub init { 1; }

=head2 schemas

Method must return list of schemas from database. In this base class method
always return empty list, because standard DBI(3) method can't get list of
schemas.

	my @schemas = $catalog->schemas()

=cut

sub schemas {
	return ();
}

=head2 schema (NAME)

Method set current schema name. Other methods work only with this schema.
Because working with one schema is typical work, all methods in specific
class need this schema name. Method can set schema (descendant need not 
redefine it).

	$catalog->schema('IS')

=cut

sub schema {
	my $obj = shift;
	$obj->{schema} = shift;
}

=head2 tables

Method must return list of storage objects from database (mean tables and
views). In this base class method use DBI(3) function C<tables()> for
fetching this list. Specific class ussually redefine method for faster
access and return all objects (list of views is in DBI(3) functions
uncertain).

	my @tables = $catalog->tables()

=cut

sub tables {
	my $obj = shift;
	return $obj->{dbi}->tables;
}

=head2 sc_types

Method return list of names of constants C<SC_TYPE_*>.

	my @types = $catalog->sc_types()

=cut

sub sc_types {
	my $obj = shift;
	my @types = ();
	for (keys %{DBIx::SystemCatalog::}) {
		push @types,$_ if /^SC_TYPE_/;
	}
	return @types;
}

=head2 table_columns (OBJECT)

Method must return list of columns for object in argument (table or view).
In this base class method use SQL query

	SELECT * FROM object WHERE 0 = 1

and fetch names of returned columns. Specific class can redefine method
for faster access.

In future this method (or similar extended method) return
more details about columns. This feature must add specific class. API for
returned values are not still specified.

	my @columns = $catalog->table_column('USERS')

=cut

sub table_columns {
	my $obj = shift;
	my $table = shift;

	my $sth = $obj->{dbi}->prepare("SELECT * FROM $table WHERE 0 = 1");
	return () unless defined $sth;
	$sth->execute;
	my @columns = @{$sth->{NAME}};
	$sth->finish;	
	return @columns;
}

=head2 table_type (OBJECT)

Method return constant C<SC_TYPE_*> according to type of object passed
as argument (table or view). In this base class method return
C<SC_TYPE_UNKNOWN>. Specific class ussually redefine method for correct 
result.

	my $type = $catalog->table_type('USERS')

=cut

sub table_type {
	return SC_TYPE_UNKNOWN;
}

=head2 tables_with_types

Method combine C<tables()> and C<table_type()> and return list of hashes
with keys C<name> (table name) and C<type> (same meaning as returned value
from C<table_type()>). Base class implement this method as C<tables()> and
for each table call C<table_type()>. Specific class ussually redefine it for
faster access.

	for my $object ($catalog->tables_with_types()) {
		my $name = $object->{name};
		my $type = $object->{type};
	}

=cut

sub tables_with_types {
	my $obj = shift;
	return map { { name => $_, type => $obj->table_type($_) }; } 
		$obj->{dbi}->tables;
}

=head2 relationships

Method return list of all relationships in schema. Each item in list is
hash with keys:

=over 4

=item name

Name of relationship

=item from_table

Name of source table with foreign key

=item to_table

Name of destination table with reference for foreign key

=item from_columns

List of source columns, each item is hash with key C<table> (table name) and
C<column> (column name). I think all C<table> will be same as C<from_table> key
in returning hash, but only God know true.

=item to_columns

List of destination columns, each item has same structure as items in
C<from_columns> item of returning hash.

=back

Base class don't implement this method (return empty list), but specific
class can redefine it (for database which support foreign keys or another
form of relationships).

	for my $relationship ($catalog->relationships()) {
		for (%$relationship) {
			print "$_: ";
			if (ref $relationship{$_}) {
				print join ',',@{$relationship{$_}};
			} else {
				print $relationship{$_};
			}
			print "\n";
		}
	}

=cut

sub relationships {
	return ();
}

=head2 primary_keys

Method return list of all columns which are primary keys of specified
table.

	my @primary_keys = $catalog->primary_keys($tablename);

=cut

sub primary_keys {
	return ();
}

=head2 unique_indexes

Method return list of all columns which contain unique indexes of specified
table. Returns list of lists.

	my @unique_indexes = $catalog->unique_indexes($tablename);

=cut

sub unique_indexes {
	return ();
}

=head2 indexes

Method return list of all columns which contain indexes of specified table.
Returns list of lists.

	my @indexes = $catalog->indexes($tablename);

=cut

sub indexes {
	return ();
}

=head2 fs_ls CWD

Emulating filesystem for dbsh - method must return list of names according to
CWD. All items ended by / are directories. We must return ../ in subdirectories.

Standard module produce next structure:

	/Schema
	/Schema/Tables
	/Schema/Views

and generate tables and views (or unknown table objects) into this structure.

	my @files = $catalog->fs_ls('/');

=cut

sub fs_ls {
	my $obj = shift;
	my $cwd = shift;

	if ($cwd eq '/') {		# schema
		my @root = map { '/'.$_."/"; } sort $obj->schemas;
		return @root if @root;
		return ('/Schema/');
	} elsif ($cwd =~ /^\/[^\/]+\/$/) { # type of objects
		return map { $cwd.$_.'/'; } qw/.. Tables Views/;
	} elsif ($cwd =~ /^\/([^\/]+)\/([^\/]+)\/$/) { # objects
		$obj->schema($1);
		my $type = SC_TYPE_VIEW;
		if ($2 eq 'Tables') { $type = SC_TYPE_TABLE; }
		my @res = ('../');
		for my $object ($obj->tables_with_types()) {
			if ($object->{type} == $type 
				|| $object->{type} == SC_TYPE_UNKNOWN) {
				push @res,$object->{name};
			}
		}
		return map { $cwd.$_; } sort @res;
	} else {			# unknown
		return ();
	}
}

1;

__END__

=head1 SPECIFIC CLASSES

I currently support only Oracle and Pg (PostgreSQL) specific class.
Returned API is described in this man page. I think man pages for
specific classes we don't need because functions are described in
this man page.

If you want contribute another specific class, please mail me.

=head1 TODO

Support for mySQL database,
fetching detailed structure of tables,
fetching definition of views, stored procedures and functions,
fetching other objects and their specific properties.

=head1 VERSION

0.06

=head1 AUTHOR

(c) 2001 Milan Sorm, sorm@pef.mendelu.cz
at Faculty of Economics,
Mendel University of Agriculture and Forestry in Brno, Czech Republic.

This module was needed for making SchemaView Plus (C<svplus>) for fetching
schema structure and relationships between objects in schema.

=head1 SEE ALSO

perl(1), DBI(3), svplus(1).

=cut

