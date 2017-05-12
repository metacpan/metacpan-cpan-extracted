#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
BEGIN { push(@INC, "lib", "t"); }
use Net::Amazon::MechanicalTurk::RowData;

# Test Tab delimited
my $data = Net::Amazon::MechanicalTurk::RowData->toRowData(
    "t/data/72-csv-data.csv"
);

my $array = [];
$data->each(sub {
    my ($_data, $row) = @_;
    fail unless ($data->fieldNames->[0] eq "Name");
    fail unless ($data->fieldNames->[1] eq "Age");
    fail unless (exists $row->{Name});
    fail unless (exists $row->{Age});
    fail unless ($row->{Age} =~ /^\d+$/);
    push(@$array, $row);
});

ok($#{$array} == 4, "CSV RowData");

