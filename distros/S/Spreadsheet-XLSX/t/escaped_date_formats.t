use strict;
use warnings;
use Test::More;
use Spreadsheet::XLSX;

# Original report.xlsx attached to RT #87746. C2 and C3 share custom format
# 164 ([$-409]dd\-mmm\-yy;@) through style index 8.
my $filename = __FILE__;
$filename =~ s/\.t\z/.xlsx/;
my @warnings;
{
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $book = Spreadsheet::XLSX->new($filename);
    my $sheet = $book->worksheet(0);
    is($sheet->get_name, 'Milestones', 'original workbook loaded');
    for my $case ([1, '41510', '24-Aug-13'], [2, '41511', '25-Aug-13']) {
        my ($row, $raw, $formatted) = @$case;
        my $cell = $sheet->get_cell($row, 2);
        is($cell->type, 'Date', 'escaped date format detected as Date');
        is($cell->{Val}, $raw, 'raw Val preserved');
        is($cell->unformatted, $raw, 'unformatted numeric date preserved');
        is($cell->value, $formatted, 'formatted date preserved');
        is($cell->{Format}, '[$-409]dd\\-mmm\\-yy;@', 'original format string preserved');
    }
}
is_deeply(\@warnings, [], 'original workbook parses without warnings');
done_testing();
