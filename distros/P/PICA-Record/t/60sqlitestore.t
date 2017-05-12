#!perl -Tw

use strict;

use Test::More qw(no_plan);

use PICA::Record;
use PICA::SQLiteStore;
use IO::File;
use File::Temp qw(tempfile);
use Data::Dumper;

if (not $ENV{PICASQL_TEST} ) {
    diag("Set PICASQL_TEST to enable additional tests of PICA::SQLiteStore!");
    ok(1);
    exit;
}

# record to insert
my $record = PICA::Record->new( IO::File->new("t/files/minimal.pica") );

# create new store
my ($dbfile, $dbfilename) = tempfile();
my $store = PICA::SQLiteStore->new( $dbfilename, rebuild => 1 );
isa_ok( $store, "PICA::SQLiteStore", "new PICA::SQLiteStore $dbfilename" );

# run general store tests
require "./t/teststore.pl";
teststore( $store );

my $deletions = $store->deletions;
ok( scalar @$deletions, "has deletions" );

# reconnect via config file
$store->{dbh}->disconnect;

my ($configfile, $configfilename) = tempfile();
print $configfile "SQLite=$dbfilename\n";
close $configfile;

$store = PICA::SQLiteStore->new( config => $configfilename );
isa_ok( $store, "PICA::SQLiteStore", "reconnect via config file" );

my $d2 = $store->deletions;
is( scalar @$d2, scalar @$deletions, "still same deletions" );

# additional SQLiteStore tests

my %h = $store->create( $record );
my $id = $h{id};

%h = $store->get($id);
is( $h{record}->string, $record->string, "reuse database file" );

# recreate the database file
$store->{dbh}->disconnect;
$store = PICA::SQLiteStore->new( $dbfilename, rebuild => 1 );
isa_ok( $store, "PICA::SQLiteStore", "rebuild database" );

my $rc = $store->recentchanges();
is_deeply( $rc, [], "empty database" );

%h = $store->create($record);
$rc = $store->recentchanges();
is( scalar @$rc, 1, "recent changes (1)" );

$id = $rc->[0]->{ppn};
my $version = $rc->[0]->{version};

is_deeply( $store->history($id), $rc, "history==recent changes (1)" );

my $pn = $store->prevnext($id, $version);
is_deeply ( $pn, {}, "prevnext (0)" );

$record = PICA::Record->new('028A $0Hello');
$store->update( $id, $record, $version );
my $history = $store->history($id);
$rc = $store->recentchanges();
is_deeply( $history, $rc, "history==recent changes (2)" );

__END__

#print Dumper($store->history($id));
#print Dumper($rc);

# TODO: contributions
# TODO: deletions (check that a version is inserted)
# TODO: history including deletions (?)

# TODO: require SQLite 3.3 (?)

# TODO: prevnext (for 1,2,3)

# TODO: run additional sqlitestore-only tests

# print Dumper($rc) . "\n";
# print Dumper($rc) . "\n";
