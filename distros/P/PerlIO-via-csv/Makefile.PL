require 5.008001;

use strict;
use warnings;

use Config;

# shouldn't this die or something?
warn <<WHOA unless $Config{useperlio};
    *** WHOA THERE!!! ***
    This is not a perlio-enabled perl !

    This module will not function with this perl !
WHOA


use inc::Module::Install;

name 'PerlIO-via-csv';
all_from 'lib/PerlIO/via/csv.pm';

requires 'Spreadsheet::Read'               => '0.34';
requires 'Spreadsheet::ParseExcel'         => '0.49';
requires 'Text::CSV'                       => '1.10';
recommends 'Text::CSV_XS'                  => '0.59';

WriteAll;
