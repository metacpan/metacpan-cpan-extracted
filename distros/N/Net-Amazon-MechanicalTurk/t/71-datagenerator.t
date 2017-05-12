#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { push(@INC, "lib", "t"); }
use Net::Amazon::MechanicalTurk::RowData;

# Test dynamic rowdata
my $data = Net::Amazon::MechanicalTurk::RowData->toRowData(sub {
    my ($block) = @_;
    foreach my $id (1..20) {
        $block->({
            time   => scalar localtime(),
            number => rand(),
            id     => $id
        });
    }
});

my $array = [];
$data->each(sub {
    my ($_data, $row) = @_;
    fail unless ($data->fieldNames->[0] eq "id");
    fail unless ($data->fieldNames->[1] eq "number");
    fail unless ($data->fieldNames->[2] eq "time");
    push(@$array, $row);
});

ok($#{$array} == 19, "Subroutine RowData");

$data = Net::Amazon::MechanicalTurk::RowData->toRowData($array);
$array = [];
$data->each(sub {
    my ($_data, $row) = @_;
    fail unless ($data->fieldNames->[0] eq "id");
    fail unless ($data->fieldNames->[1] eq "number");
    fail unless ($data->fieldNames->[2] eq "time");
    push(@$array, $row);
});

ok($#{$array} == 19, "ArrayHash RowData");

