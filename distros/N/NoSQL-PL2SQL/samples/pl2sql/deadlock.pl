use NoSQL::PL2SQL ;
use NoSQL::PL2SQL::DBI::MySQL ;

package TestRequest ;
use base qw( NoSQL::PL2SQL ) ;
use Carp ;
use Storable qw( store retrieve ) ;

## A deadlock occurs if a process or database crashes while holding a lock 
## and the lock is never released- circumstances that are generally unusual
## but never say never.  Use the sample code below will reset the lock
## manually.  The dumped data also needs to be manually reloaded.  This 
## operation is pretty specific, so modify the example below to accommodate
## your particular data needs.

## A deadlock is a catastrophic event.  Make sure you know what you're doing.

## The recordid is stored as the last term in the dump file name.

__PACKAGE__->SQLError( TableLockFailure => sub {
		my $package = shift ;
		my $error = shift ;
		my $errortext = pop ;

		if ( @_ ) {
			$error->{filename} = '/tmp/' ;
			$error->{filename} .= join '-', 'dump', $package, 
					@$error{ 
					  qw( Error timestamp recordid ) } ;
			store $_[0], $error->{filename} ;
			}
	
		carp( join ': ', %$error ) ;
		} ) ;


## This method is not defined in the NoSQL::PL2SQL::DBI package

sub NoSQL::PL2SQL::DBI::LockReset {
	my $self = shift ;
	my $recordid = shift ;
	return $self->update( $recordid => [ deleted => 0 ] ) ;
	}

$dsn->LockReset( $recordid ) ;

## Recovery of a simple NVP hash reference:

sub RecoverFromDump {
	my $dsn = shift ;
	my $recordid = shift ;
	my $recovered = shift ;

	my $objectid = $dsn->fetch( 
			[ id => $recordid ] )->{$recordid}->{objectid} ;
	my $testObject = TestRequest->SQLObject( $dsn, $objectid ) ;

	map { delete $testObject->{$_} } keys %$testObject ;
	map { $testObject->{$_} = $recovered->{$_} } keys %$recovered ;
	undef $testObject ;
	}

RecoverFromDump( $dsn, $recordid, retrieve $dumpFilename ) ;

1
