#!/usr/bin/perl
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;
use Net::Amazon::MechanicalTurk::RowData::SQLRowData;
use DBI;

#
# Use this script to see what is in the sqlite db.
# This code also uses the SQLRowData class to iterate
# through database rows, the way the loadHITs method would
# for loading.
#

sub get_tables {
    my $dbh = shift;
    my $data = Net::Amazon::MechanicalTurk::RowData::SQLRowData->new(
        dbh => $dbh,
        sql => "SELECT tbl_name FROM sqlite_master WHERE type = 'table'"
    );
    my @tables;
    $data->each(sub {
        my ($data, $row) = @_;
        push(@tables, $row->{tbl_name});
    });
    return @tables;
}


my $dbh = DBI->connect("dbi:SQLite2:dbname=turk.db","","", {
    RaiseError => 1,
    AutoCommit => 0
});

foreach my $table (get_tables($dbh)) {
    my $data = Net::Amazon::MechanicalTurk::RowData::SQLRowData->new(
        dbh => $dbh,
        sql => "SELECT * FROM $table"
    );
    my $count = 0;
    print "TABLE $table\n";
    print "-" x 60, "\n";
    $data->each(sub {
        my ($data, $row) = @_;
        my $fields = $data->fieldNames;
        print(join("|", @$fields), "\n") if ($count++ == 0);
        print(join("|", map { $row->{$_} } @$fields), "\n");
    });
    print "\n\n";
}
$dbh->commit;
$dbh->disconnect;
