#!/usr/bin/perl
use strict;
use warnings;
use DBI;

my $dbfile = "turk.db";
unlink($dbfile) if (-f $dbfile);
die "Couldn't remove $dbfile." if (-f $dbfile);

my $dbh = DBI->connect("dbi:SQLite2:dbname=${dbfile}","","", {
    RaiseError => 1,
    AutoCommit => 0
});

$dbh->do(qq{
    CREATE TABLE cities (
        id INTEGER PRIMARY KEY,
        city VARCHAR(30) NOT NULL,
        state VARCHAR(2) NOT NULL
    )
});

$dbh->do(qq{
    CREATE TABLE hits (
        hitid VARCHAR(100) PRIMARY KEY,
        hittypeid VARCHAR(100) NOT NULL,
        cityid INTEGER NOT NULL,
        question TEXT
    )
});

my @cities = (
    ['Seattle', 'WA'],
    ['NewYork', 'NY'],
    ['Phoenix', 'AZ']
);

my $sth = $dbh->prepare(qq{
    INSERT INTO cities (id,city,state)
    VALUES (?,?,?)
});

my $id = 0;
foreach my $city (@cities) {
    $id++;
    $sth->execute($id, $city->[0], $city->[1]);
}

print "Inserted $id rows.";

$dbh->commit;
$dbh->disconnect;

