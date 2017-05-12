use strict;
use warnings;

#use Test::More tests => 3;
use Test::More skip_all => "not working yet";

use PerlIO::via::csv;

chdir 't' if -d 't';
my $xlsfile = 'Dates.xls';

# read row by row
SKIP: {
    ok(open(my $fh, '<:via(csv)', $xlsfile), "open <:via(csv) $xlsfile");
    my $csv = <$fh>;
    is($csv, qq{A1,B1,,D1\n}, "Read one row");

    ok(close($fh), "close <:via(csv) $xlsfile");
}
