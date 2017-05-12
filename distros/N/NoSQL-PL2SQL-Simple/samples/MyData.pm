package TQIS::PL2SQL::MyData ;		## An arbitrary class name
use base qw( NoSQL::PL2SQL::Simple ) ;	## Do not change this line

use NoSQL::PL2SQL::DBI::SQLite ;		## Use one of the available
						## drivers.

my @dsn = () ;				## Do not change this line

## data source subclasses override this dsn() method
sub dsn {
	return @dsn if @dsn ;			## Do not change this line

	my %tables ;
	$tables{objectdata} = 'aTableName' ;	## Personal preference
	$tables{querydata} = 'anotherTableName' ;	## Ditto

	push @dsn, new NoSQL::PL2SQL::DBI::SQLite $tables{objectdata} ;
	$dsn[0]->connect( 'dbi:SQLite:dbname=:memory:', '', '') ;

	push @dsn, $dsn[0]->table( $tables{querydata} ) ;
	return @dsn ;				## Do not change this line
	}

1
