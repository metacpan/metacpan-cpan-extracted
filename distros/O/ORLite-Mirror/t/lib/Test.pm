package t::lib::Test;

use strict;
use Exporter       ();
use ORLite::Mirror ();
use Test::More     ();
use File::Remove   ();
use File::HomeDir  ();
use File::Spec::Functions ':ALL';

use vars qw{$VERSION @ISA @EXPORT};
BEGIN {
	$VERSION = '1.24';
	@ISA     = 'Exporter';
	@EXPORT  = qw{
		test_db
		create_ok
		mirror_db
		connect_ok
	};
}





#####################################################################
# Test Methods

sub test_db {
	my $file = catfile( @_ ? @_ : 't', 'sqlite.db' );
	File::Remove::clear($file);
	return $file;
}

sub mirror_db {
	my $dir = catdir(
		File::HomeDir->my_data,
		($^O eq 'MSWin32' ? 'Perl' : '.perl'),
		'ORLite-Mirror',
	);
	my $file = shift;
	$file =~ s/::/-/g;
	my $sqlite = catfile( $dir, "$file.sqlite" );
	return ( $sqlite, "$sqlite.gz", "$sqlite.bz2", "$sqlite.lz" );
}

sub connect_ok {
	my $dbh = DBI->connect(@_);
	Test::More::isa_ok( $dbh, 'DBI::db' );
	return $dbh;
}

sub create_ok {
	# Read the create script
	my $file = shift;
	local *FILE;
	local $/ = undef;
	open( FILE, $file )          or die "open: $!";
	defined(my $buffer = <FILE>) or die "readline: $!";
	close( FILE )                or die "close: $!";

	# Get a database connection
	my $dbh = connect_ok(@_);

	# Create the tables
	my @statements = split( /\s*;\s*/, $buffer );
	foreach my $statement ( @statements ) {
		# Test::More::diag( "\n$statement" );
		$dbh->do($statement);
	}

	return $dbh;
}

1;
