use strict;
use Test::More 0.98;

use_ok("Spreadsheet::Edit");
use_ok("Spreadsheet::Edit::IO", "let2cx", "cx2let", "convert_spreadsheet");
use_ok("Spreadsheet::Edit::IO", "filepath_from_spec", "sheetname_from_spec");
use_ok("Spreadsheet::Edit::Preload", {title_rx => undef}, "/dev/null");

done_testing;

