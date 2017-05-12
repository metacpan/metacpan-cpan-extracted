#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
BEGIN { push(@INC, "lib", "t"); }
use Net::Amazon::MechanicalTurk::RowData;

# Test Tab delimited
my $data = Net::Amazon::MechanicalTurk::RowData->toRowData(
    "t/data/70-tabdelim-data.txt"
);

my $array = [];
$data->each(sub {
    my ($_data, $row) = @_;
    fail unless ($data->fieldNames->[0] eq "Name");
    fail unless ($data->fieldNames->[1] eq "Age");
    fail unless (exists $row->{Name});
    fail unless (exists $row->{Age});
    push(@$array, $row);
});

ok($#{$array} == 4, "Tab Delimited RowData");

