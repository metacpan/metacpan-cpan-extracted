use strict;
use DBI ();

# Locate the SQLite database
my $file = <STDIN>;
chomp($file);
unless ( -f $file and -w $file ) {
	die "SQLite file $file does not exist";
}

# Connect to the SQLite database
my $dbh = DBI->connect("dbi:SQLite(RaiseError=>1):$file");
unless ( $dbh ) {
	die "Failed to connect to $file";
}





#####################################################################
# Migration

foreach ( split /;\s+/, <<'END_SQL' ) { $dbh->do( $_ ) }

insert into foo values ( 2, 'bar' )

END_SQL
