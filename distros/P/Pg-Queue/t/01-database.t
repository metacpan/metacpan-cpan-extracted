
use strict;
use warnings;

use Test::More tests => 22;
use DBI;

require_ok('Pg::Queue');

my $schema = "queuetest";

SKIP: {
	skip "Skipping live database tests without a DSN configured", 21 
		unless $ENV{TEST_PG_QUEUE_DSN};

	my $dbh = DBI->connect( $ENV{TEST_PG_QUEUE_DSN}, $ENV{TEST_PG_QUEUE_USER}, $ENV{TEST_PG_QUEUE_PASSWORD}, {AutoCommit=>1, RaiseError=>1} )
		or die "DBI FAILURE $DBI::errstr";

	$dbh->do( "DROP SCHEMA IF EXISTS $schema CASCADE" );
	$dbh->do( "CREATE SCHEMA $schema" );
	$dbh->do( "SET search_path TO $schema" );

	my $q = Pg::Queue->new( dbh => $dbh );
	ok( $q, "Instantiated Pg::Queue" );

	ok( $q->create_queue_table, "Created table" );

	for( 0 .. 9 ) {
		ok( $q->add_work_item( "item $_" ), "Added work item" );
	}

	is( $q->count_total, 10, "Created 10 work items" );
	is( $q->count_available, 10, "All 10 are available" );

	ok( $q->pull_work_item(sub{ like( $_[1], qr/item \d/, "Work item text matches" ); 1 }), "Got a work item" );

	is( $q->count_total, 10, "Total 10 work items" );
	is( $q->count_available, 9, "Down to 9 available" );

	ok( ! $q->pull_work_item(
			sub{ 
				like( $_[1], qr/item \d/, "Work item text matches in error test" ); 
				return 0 
			}
	), "Got a work item but returned 0" );

	is( $q->count_available, 9, "Still 9 available" );

	$dbh->do( "DROP SCHEMA $schema CASCADE" );
};

