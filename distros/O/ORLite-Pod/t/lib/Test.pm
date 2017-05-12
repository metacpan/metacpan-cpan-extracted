package t::lib::Test;

use strict;
use autodie;
use Exporter     ();
use ORLite       ();
use ORLite::Pod  ();
use Test::More   ();
use Test::XT     'WriteXT';
use File::Remove 'clear';
use File::Spec::Functions ':ALL';

use vars qw{$VERSION @ISA @EXPORT};
BEGIN {
	$VERSION = '0.11';
	@ISA     = 'Exporter';
	@EXPORT  = qw{ test_db connect_ok create_ok create_dist };
}





#####################################################################
# Test Methods

sub test_db {
	my $file = catfile( @_ ? @_ : 't', 'sqlite.db' );
	clear($file);
	return $file;
}

sub connect_ok {
	my $dbh = DBI->connect(@_);
	Test::More::isa_ok( $dbh, 'DBI::db' );
	return $dbh;
}

sub create_ok {
	my %param = @_;

	# Read the create script
	my $file = $param{file};
	local *FILE;
	local $/ = undef;
	open( FILE, $file );
	my $buffer = <FILE>;
	close( FILE );

	# Get a database connection
	my $dbh = connect_ok( @{$param{connect}} );

	# Create the tables
	my @statements = split( /\s*;\s*/, $buffer );
	foreach my $statement ( @statements ) {
		# Test::More::diag( "\n$statement" );
		$dbh->do($statement);
	}

	# Set the user_version if needed
	if ( $param{user_version} ) {
		$dbh->do("pragma user_version = $param{user_version}");
	}

	return $dbh;
}





######################################################################
# Distribution Generation

sub create_dist {
	my $sql_file = shift;

	# Clear and recreate any existing directory
	my $dist = catdir( 't', 'Foo-Bar' );
	clear( $dist );
	mkdir $dist;

	# Create the database
	create_ok(
		file    => catfile( 't', $sql_file ),
		connect => [
			'dbi:SQLite:' . catfile( $dist, 'sqlite.db' ),
		],
	);

	# Create the pm file
	mkdir catdir( $dist, 'lib' );
	mkdir catdir( $dist, 'lib', 'Foo' );
	open( FILE, '>', catfile( $dist, 'lib', 'Foo', 'Bar.pm' ) );
	print FILE <<'END_PERL'; close FILE;
package Foo::Bar;

use strict;
use ORLite 'sqlite.db';

1;
END_PERL

	# Create the automatic tests
	mkdir catdir( $dist, 't' );
	WriteXT(
		'Test::Pod' => catfile( $dist, 't', 'pod.t' ),
	);
	
	return $dist;
}

1;
