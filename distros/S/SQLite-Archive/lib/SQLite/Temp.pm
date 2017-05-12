package SQLite::Temp;

use 5.005;
use strict;
use DBI         ();
use DBD::SQLite ();
use File::Spec  ();
use File::Temp  ();
use SQL::Script ();
use Parse::CSV  ();

use vars qw{$VERSION @ISA @EXPORT};
BEGIN {
	$VERSION = '0.02';
	require Exporter;
	@ISA    = 'Exporter';
	@EXPORT = qw{ empty_db create_db };
}

sub sqlite_db {
	# Get a temp file name
	my $dir  = File::Temp::tempdir( CLEANUP => 1 );
	my $file = File::Spec->catfile( $dir, 'sqlite.db' );

	# Create the database
	DBI->connect( 'dbi:SQLite:' . $file ) or die "Failed to create test DB handle";
}

sub create_db {
	my $dbh = empty_db();

	# For each value provided fill the database
	foreach my $file ( @_ ) {
		if ( $file =~ /\.sql$/ ) {
			fill_sql( $dbh, $file );
		} elsif ( $file =~ /\.csv$/ ) {
			fill_csv( $dbh, $file );
		} else {
			die "Unsupported file type $file";
		}
	}

	return $dbh;
}

sub fill_sql {
	my $dbh  = shift;
	my $file = shift;
	my @sql  = ();

	# Read in the file
	SCOPE: {
		local $/;
		open( SQLFILE, $file ) or die "open: $!";
		my $buffer = <SQLFILE>;
		close SQLFILE;
		@sql = split /\n\n/, $buffer;
	}

	# Execute the SQL commands
	foreach my $statement ( @sql ) {
		defined($dbh->do($statement)) or die "$statement failes";
	}

	return 1;
}

sub fill_csv {
	my $dbh    = shift;
	my $file   = shift;
	my $parser = Parse::CSV->new(
		file   => $file,
		fields => 'auto',
		) or die "Failed to create parser";
	my (undef, undef, $table) = File::Spec->splitpath($file);
	$table =~ s/\.csv$// or die "Failed to trim table name";

	# Process the inserts
	while ( my $row = $parser->fetch ) {
		my $sql = "INSERT INTO $table ( "
			. join( ', ',  keys %$row )
			. " ) values ( "
			. join( ', ', map { '?' } values %$row )
			. " )";
		my $sth = $dbh->prepare( $sql ) or die "prepare_cached failed";
		my $rv  = $sth->execute( values %$row ) or die "execute failed";
		$sth->finish;
	}

	return 1;
}

1;
