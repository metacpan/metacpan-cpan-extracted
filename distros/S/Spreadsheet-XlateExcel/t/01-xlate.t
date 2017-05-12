#
# Modules.
#

use Spreadsheet::XlateExcel;
use Test::More;
use Test::Differences;

#
# Bitch.
#

use strict;
use warnings;

#
# Cases.
#

my $got;

my $all_rows_thru_values = sub { my ( $sheet_id, $row, $row_vs ) = @_ ; push @$got, $row_vs };

my @cases = (
  {
    name     => 'all sheets, all rows thru sheet id',
    file     => 'sheet-01.xls',
    option   => { for_each_row_do => sub { my ( $sheet_id, $row, $row_vs ) = @_ ; my @r = $sheet_id->col_range ; push @$got, [ map { $_ ? $_->value : '' } map { $sheet_id->get_cell ( $row, $_ ) } ( $r[0] .. $r[-1] ) ] } },
    expected => [
      [ qw( S1A1 S1B1 S1C1    S1D1  S1E1  ) ],
      [ qw( S1A2 S1B2 S1C2 ), '',  'S1E2'   ],
      [ qw( S1A3 S1B3 S1C3    S1D3  S1E3  ) ],
      [ qw( S2A1 S2B1 S2C1                ) ],
      [ qw( S2A2 S2B2 S2C2                ) ],
      [ qw( S2A3 S2B3 S2C3                ) ],
      [ qw( S2A4 S2B4 S2C4                ) ],
      [ qw( S2A5 S2B5 S2C5                ) ],

    ],
  },
  {
    name     => 'all sheets, all rows thru values',
    file     => 'sheet-01.xls',
    option   => { for_each_row_do => $all_rows_thru_values },
    expected => [
      [ qw( S1A1 S1B1 S1C1    S1D1  S1E1  ) ],
      [ qw( S1A2 S1B2 S1C2 ), '',  'S1E2'   ],
      [ qw( S1A3 S1B3 S1C3    S1D3  S1E3  ) ],
      [ qw( S2A1 S2B1 S2C1                ) ],
      [ qw( S2A2 S2B2 S2C2                ) ],
      [ qw( S2A3 S2B3 S2C3                ) ],
      [ qw( S2A4 S2B4 S2C4                ) ],
      [ qw( S2A5 S2B5 S2C5                ) ],
    ],
  },
  {
    name     => 'all sheets, odd rows thru values',
    file     => 'sheet-01.xls',
    option   => { for_each_row_do => sub { my ( $sheet_id, $row, $row_vs ) = @_ ; push @$got, $row_vs unless $row % 2 } },
    expected => [
      [ qw( S1A1 S1B1 S1C1 S1D1 S1E1 ) ],
      [ qw( S1A3 S1B3 S1C3 S1D3 S1E3 ) ],
      [ qw( S2A1 S2B1 S2C1           ) ],
      [ qw( S2A3 S2B3 S2C3           ) ],
      [ qw( S2A5 S2B5 S2C5           ) ],
    ],
  },
  {
    name     => 'one sheet thru name, all rows thru values',
    file     => 'sheet-01.xls',
    option   => { on_sheet_named => 'Sheet2', for_each_row_do => $all_rows_thru_values },
    expected => [
      [ qw( S2A1 S2B1 S2C1           ) ],
      [ qw( S2A2 S2B2 S2C2           ) ],
      [ qw( S2A3 S2B3 S2C3           ) ],
      [ qw( S2A4 S2B4 S2C4           ) ],
      [ qw( S2A5 S2B5 S2C5           ) ],
    ],
  },
  {
    name     => 'one sheet thru =~re, all rows thru values',
    file     => 'sheet-01.xls',
    option   => { on_sheets_like => qr/2$/, for_each_row_do => $all_rows_thru_values },
    expected => [
      [ qw( S2A1 S2B1 S2C1           ) ],
      [ qw( S2A2 S2B2 S2C2           ) ],
      [ qw( S2A3 S2B3 S2C3           ) ],
      [ qw( S2A4 S2B4 S2C4           ) ],
      [ qw( S2A5 S2B5 S2C5           ) ],
    ],
  },
  {
    name     => 'one sheet thru !~re, all rows thru values',
    file     => 'sheet-01.xls',
    option   => { on_sheets_unlike => qr/1$/, for_each_row_do => $all_rows_thru_values },
    expected => [
      [ qw( S2A1 S2B1 S2C1           ) ],
      [ qw( S2A2 S2B2 S2C2           ) ],
      [ qw( S2A3 S2B3 S2C3           ) ],
      [ qw( S2A4 S2B4 S2C4           ) ],
      [ qw( S2A5 S2B5 S2C5           ) ],
    ],
  },
  {
    name     => 'bad sheet thru name, all rows thru values',
    file     => 'sheet-01.xls',
    option   => { on_sheet_named => 'Sheet3', for_each_row_do => $all_rows_thru_values },
    expected => [],
  },
  {
    name     => 'all sheets, all rows thru values, some columns thru =~res',
    file     => 'sheet-01.xls',
    option   => { on_columns_heads_like => [ qr/S\d+B1/, qr/S1C\d+/, qr/S1E1/ ], for_each_row_do => $all_rows_thru_values },
    expected => [
      [ qw(      S1B1 S1C1      S1E1 ) ],
      [ qw(      S1B2 S1C2      S1E2 ) ],
      [ qw(      S1B3 S1C3      S1E3 ) ],
      [ qw(      S2B1                ) ],
      [ qw(      S2B2                ) ],
      [ qw(      S2B3                ) ],
      [ qw(      S2B4                ) ],
      [ qw(      S2B5                ) ],
    ],
  },
  {
    name     => 'one sheet thru name, all rows thru values, some columns thru =~res',
    file     => 'sheet-01.xls',
    option   => { on_sheet_named => 'Sheet1', on_columns_heads_like => [ qr/S\d+B1/, qr/S1C\d+/, qr/S1E1/ ], for_each_row_do => $all_rows_thru_values },
    expected => [
      [ qw(      S1B1 S1C1      S1E1 ) ],
      [ qw(      S1B2 S1C2      S1E2 ) ],
      [ qw(      S1B3 S1C3      S1E3 ) ],
    ],
  },
  {
    name     => 'one sheet thru name, all rows thru values, some columns thru names',
    file     => 'sheet-01.xls',
    option   => { on_sheet_named => 'Sheet1', on_columns_heads_named => [ qw( S1B1 S1C1 S1E1 ) ], for_each_row_do => $all_rows_thru_values },
    expected => [
      [ qw(      S1B1 S1C1      S1E1 ) ],
      [ qw(      S1B2 S1C2      S1E2 ) ],
      [ qw(      S1B3 S1C3      S1E3 ) ],
    ],
  },
  {
    name     => 'one sheet thru name, all rows thru values, some columns thru =~res, deranged',
    file     => 'sheet-01.xls',
    option   => { on_sheet_named => 'Sheet1', on_columns_heads_like => [ qr/S1E1/, qr/S1C\d+/, qr/S\d+B1/ ], for_each_row_do => $all_rows_thru_values },
    expected => [
      [ qw(      S1E1 S1C1      S1B1 ) ],
      [ qw(      S1E2 S1C2      S1B2 ) ],
      [ qw(      S1E3 S1C3      S1B3 ) ],
    ],
  },
  {
    name     => 'one sheet thru name, all rows thru values, some columns thru names, deranged',
    file     => 'sheet-01.xls',
    option   => { on_sheet_named => 'Sheet1', on_columns_heads_named => [ qw( S1C1 S1B1 S1E1 ) ], for_each_row_do => $all_rows_thru_values },
    expected => [
      [ qw(      S1C1 S1B1      S1E1 ) ],
      [ qw(      S1C2 S1B2      S1E2 ) ],
      [ qw(      S1C3 S1B3      S1E3 ) ],
    ],
  },
);

#
# Plan.
#

plan tests => scalar @cases;

#
# Loop.
#

for my $case ( @cases ) {
  my $id = Spreadsheet::XlateExcel->new ({ file => "t/01-xlate/$case->{file}" });
  
  $got = [];
  
  $id->xlate ( $case->{option} );
  
  eq_or_diff ( $got, $case->{expected}, $case->{name} );
}
