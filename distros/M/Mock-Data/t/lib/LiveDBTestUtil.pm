package LiveDBTestUtil;
use strict;
use warnings;
use DBI;
use DBIx::Class;
use DBIx::Class::Schema::Loader;

sub new_sqlite_schema {
	my $ddl= shift;
	my $dbh= DBI->connect("dbi:SQLite::memory:")
		or die;
	$dbh->{RaiseError}= 1;
	$dbh->{AutoCommit}= 1;
	$dbh->do("PRAGMA foreign_keys = ON;");
	$dbh->selectall_arrayref("PRAGMA foreign_keys;")->[0][0]
		or die "This SQLite version doesn't support foreign keys";

	# Build the database from DDL
	$dbh->do($_) for split /;$/m, $ddl;

	return wrap_dbi_with_dbic($dbh);
}

our @schemas;
END {
	# Make sure database connections garbage-collect before global destruction.
	# Refs might be held on the Schema object in the test case code, but the storage
	# object probably only has one ref to it.
	$_->storage(undef) for @schemas;
}

sub wrap_dbi_with_dbic {
	my $dbh= shift;
	# Create an automatic DBIx::Class from it
	my $class= __PACKAGE__.'::Schema'.@schemas;
	eval qq{
		package $class;
		use parent 'DBIx::Class::Schema::Loader';
		__PACKAGE__->naming('current');
		__PACKAGE__->use_namespaces(1);
		1;
	} or die $@;

	# Create a DBIx::Class::Schema connection wrapping the existing DBI connection
	my $schema= $class->connect({ dbh_maker => sub { $dbh } });
	push @schemas, $schema;
	return $schema;
}

1;
