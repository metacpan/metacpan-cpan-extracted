use strict;
use Test::More;

use Net::Google::Spreadsheets::V4;

# https://developers.google.com/sheets/api/guides/concepts#a1_notation

my $sheet_title = q{M's Custom Sheet};
my $a1n;

$a1n = Net::Google::Spreadsheets::V4->a1_notation(
    sheet_title => $sheet_title,
    start_column => 1,
    start_row => 1,
    end_column => 2,
    end_row => 2,
);
is($a1n, "'M''s Custom Sheet'!A1:B2");

$a1n = Net::Google::Spreadsheets::V4->a1_notation(
    sheet_title => $sheet_title,
    start_column => 1,
    end_column => 1,
);
is($a1n, "'M''s Custom Sheet'!A:A");

$a1n = Net::Google::Spreadsheets::V4->a1_notation(
    sheet_title => $sheet_title,
    start_row => 1,
    end_row => 2,
);
is($a1n, "'M''s Custom Sheet'!1:2");

$a1n = Net::Google::Spreadsheets::V4->a1_notation(
    sheet_title => $sheet_title,
    start_column => 1,
    start_row => 5,
    end_column => 1,
);
is($a1n, "'M''s Custom Sheet'!A5:A");

$a1n = Net::Google::Spreadsheets::V4->a1_notation(
    start_column => 1,
    start_row => 1,
    end_column => 2,
    end_row => 2,
);
is($a1n, "A1:B2");

$a1n = Net::Google::Spreadsheets::V4->a1_notation(
    sheet_title => $sheet_title,
);
is($a1n, "'M''s Custom Sheet'");

done_testing;
