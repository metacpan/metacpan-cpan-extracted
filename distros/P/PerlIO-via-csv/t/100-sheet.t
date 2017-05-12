use strict;
use warnings;

use Test::More tests => 15;

use PerlIO::via::csv sheet => 2;

chdir 't' if -d 't';
my $xlsfile = 'test.xls';

# read sheet 2 (from use)
{
    ok(open(my $fh, '<:via(csv)', $xlsfile),
       "open <:via(csv) $xlsfile sheet 2");
    my $csv = <$fh>;
    is($csv, qq{x,,x,,x\n}, "Read one row");
    ok(close($fh), "close <:via(csv) $xlsfile");
}

# read sheet 1
{
    PerlIO::via::csv->sheet(1);

    ok(open(my $fh, '<:via(csv)', $xlsfile),
       "open <:via(csv) $xlsfile sheet 1");
    my $csv = <$fh>;
    is($csv, qq{A1,B1,,D1\n}, "Read one row");
    ok(close($fh), "close <:via(csv) $xlsfile");
}

# read sheet 2 by name
{
    PerlIO::via::csv->sheet('Second Sheet');

    ok(open(my $fh, '<:via(csv)', $xlsfile),
       "open <:via(csv) $xlsfile 'Second Sheet'");
    my $csv = <$fh>;
    is($csv, qq{x,,x,,x\n}, "Read one row");
    ok(close($fh), "close <:via(csv) $xlsfile");
}

# try bogus sheets
PerlIO::via::csv->sheet(42);
eval {
    open(my $fh, '<:via(csv)', $xlsfile);
};
ok($@, "open <:via(csv) $xlsfile non-existent sheet 42");
like($@, qr{no worksheet}, "no worksheet err msg 42");

PerlIO::via::csv->sheet(0);
eval {
    open(my $fh, '<:via(csv)', $xlsfile);
};
ok($@, "open <:via(csv) $xlsfile non-existent sheet 0");
like($@, qr{no worksheet}, "no worksheet err msg 0");

PerlIO::via::csv->sheet('Excession');
eval {
    open(my $fh, '<:via(csv)', $xlsfile);
};
ok($@, "open <:via(csv) $xlsfile non-existent sheet 'Excession'");
like($@, qr{no worksheet}, "no worksheet err msg 'Excession'");
