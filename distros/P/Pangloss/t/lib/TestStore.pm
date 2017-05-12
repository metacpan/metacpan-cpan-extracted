package TestStore;

use strict;
use warnings;

use Pixie;
use File::Spec;

our $STORE;
our $USE_BDB;
our $BDB_DIR  = File::Spec->catdir( qw( t tmp store ) );
our $BDB_FILE = File::Spec->catdir( $BDB_DIR, qw( objects.bdb) );

BEGIN {
    if ($ENV{PG_TEST_DSN}) {
	print "Using test Pixie dsn: $ENV{PG_TEST_DSN}\n";
    } else {
	eval { require BerkeleyDB; };
	if ($@) {
	    print "No Pixie store available\n";
	    $USE_BDB = 0;
	} else {
	    print "Using BerkeleyDB Pixie store\n";
	    $USE_BDB = 1;
	}
    }
}


sub STORE {
    my $class = shift;
    return $STORE if $STORE;
    return $class->create_store;
}

sub create_store {
    my $class = shift;

    if ($ENV{PG_TEST_DSN}) {
	$STORE = Pixie->new
	  ->connect(
		    $ENV{PG_TEST_DSN},
		    $ENV{PG_TEST_USER} ? (user => $ENV{PG_TEST_USER}) : (),
		    $ENV{PG_TEST_PASS} ? (pass => $ENV{PG_TEST_PASS}) : (),
		   );
    } elsif ($USE_BDB) {
	unless (-d $BDB_DIR) {
	    require File::Path;
	    import File::Path;
	    mkpath( [ $BDB_DIR ] );
	}
	$STORE = Pixie->new->connect( "bdb:$BDB_FILE" );
    }

    return $STORE;
}

sub reset_store {
    my $class = shift;
    $STORE    = undef;
    return $class;
}

1;
