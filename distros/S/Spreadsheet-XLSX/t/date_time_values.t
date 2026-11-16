use strict;
use warnings;
use Test::More;
use Spreadsheet::XLSX;
use Spreadsheet::XLSX::Utility2007 qw(ExcelFmt);

for my $tokens ('AM/PM', 'am/pm', 'Am/Pm', 'A/P', 'a/p') {
    my ($am, $pm) = split '/', $tokens;
    for my $case (
        [0, "12:00:00 $am", "12:00:00 $am"],
        [0.25, "6:00:00 $am", "06:00:00 $am"],
        [0.5, "12:00:00 $pm", "12:00:00 $pm"],
        [0.75, "6:00:00 $pm", "06:00:00 $pm"],
    ) {
        is(ExcelFmt("h:mm:ss $tokens", 42736 + $case->[0], 0, 'Date'),
            $case->[1], "$tokens at day fraction $case->[0]");
        is(ExcelFmt("hh:mm:ss $tokens", 42736 + $case->[0], 0, 'Date'),
            $case->[2], "zero-padded hour with $tokens at day fraction $case->[0]");
    }
}
is(ExcelFmt('h:mm:ss', 42736.75, 0, 'Date'), '18:00:00', '24-hour format unchanged');
is(ExcelFmt('h:mm:ss "AM/PM"', 42736.75, 0, 'Date'), '18:00:00 AM/PM',
    'quoted AM/PM remains literal and does not enable 12-hour format');

# Original Book1.xlsx attached to RT #119170; includes x15:workbookPr.
my $filename = __FILE__;
$filename =~ s/\.t\z/.xlsx/;
my @warnings;
my $book;
{
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $book = Spreadsheet::XLSX->new($filename);
}
my $sheet = $book->worksheet(0);
my $date = $sheet->get_cell(1, 3);
my $time = $sheet->get_cell(1, 4);
is($date->type, 'Date', 'D2 detected as date');
is($date->{Val}, '42736', 'D2 raw Val preserved');
is($date->unformatted, '42736', 'D2 unformatted value preserved');
is($date->value, '2017-01-01', 'D2 formatted date');
is($time->type, 'Date', 'E2 date/time type unchanged');
is($time->{Val}, '42736.523611111108', 'E2 raw Val preserved');
is($time->unformatted, '42736.523611111108', 'E2 unformatted value preserved');
is($time->value, '12:34:00 PM', 'E2 formatted time from RT #119170');
is_deeply(\@warnings, [], 'original workbook parses without warnings');

done_testing();
