use strict;
use warnings;

use Test::More tests => 8;

use PerlIO::via::csv;

chdir 't' if -d 't';
my $xlsfile = 'test.xls';

# read row by row
{
    ok(open(my $fh, '<:via(csv)', $xlsfile), "open <:via(csv) $xlsfile");
    my $csv = <$fh>;
    is($csv, qq{A1,B1,,D1\n}, "Read one row");
    $csv = <$fh>;
    is($csv, qq{A2,B2,,\n}, "Read another row");

    my @csv = <$fh>;
    is(join('',@csv), qq{A3,,C3,D3\nA4,B4,C4,\n}, "Read remaining rows");

    ok(close($fh), "close <:via(csv) $xlsfile");
}

# slurp rows
{
    ok(open(my $fh, '<:via(csv)', $xlsfile), "open <:via(csv) $xlsfile");
    local $/;
    my $csv = <$fh>;
    is($csv, qq{A1,B1,,D1\nA2,B2,,\nA3,,C3,D3\nA4,B4,C4,\n}, "Slurp rows");
    ok(close($fh), "close <:via(csv) $xlsfile");
}
