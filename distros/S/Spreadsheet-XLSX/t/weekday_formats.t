use strict;
use warnings;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use File::Temp qw(tempfile);
use Spreadsheet::XLSX;
use Spreadsheet::XLSX::Utility2007 qw(ExcelFmt);

# 2016-08-14 is Sunday; fractions include nonzero milliseconds to ensure
# the weekday is not accidentally taken from the millisecond component.
my @long = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
my @short = qw(Sun Mon Tue Wed Thu Fri Sat);
for my $epoch (0, 1) {
    for my $day (0 .. 6) {
        my $serial = 42596 + $day - ($epoch ? 1462 : 0);
        for my $fraction (0, 0.25352) {
            is(ExcelFmt('dddd', $serial + $fraction, $epoch, 'Date'), $long[$day],
                "long weekday $long[$day], 1904=$epoch, fraction=$fraction");
            is(ExcelFmt('ddd', $serial + $fraction, $epoch, 'Date'), $short[$day],
                "short weekday $short[$day], 1904=$epoch, fraction=$fraction");
        }
    }
}
is(ExcelFmt('yyyy-mm-dd dddd', 42598.25352, 0, 'Date'),
    '2016-08-16 Tuesday', 'weekday in combined date format');

sub parse_formats {
    my @formats = @_;
    my ($styles, $cells) = ('', '');
    for my $i (0 .. $#formats) {
        my ($format, $value) = @{$formats[$i]};
        $format =~ s/"/&quot;/g;
        my $id = 164 + $i;
        my $row = $i + 1;
        $styles .= qq{<numFmt numFmtId="$id" formatCode="$format"/>};
        $cells .= qq{<row r="$row"><c r="A$row" s="$i"><v>$value</v></c></row>};
    }
    my %members = (
        'xl/workbook.xml' => '<workbook xmlns:r="x"><sheets><sheet name="Data" sheetId="1" r:id="rId1"/></sheets></workbook>',
        'xl/_rels/workbook.xml.rels' => '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
        'xl/styles.xml' => '<styleSheet><numFmts>' . $styles . '</numFmts><cellXfs>'
            . join('', map { my $id = 164 + $_; qq{<xf numFmtId="$id"/>} } 0 .. $#formats)
            . '</cellXfs></styleSheet>',
        'xl/worksheets/sheet1.xml' => "<worksheet><sheetData>$cells</sheetData></worksheet>",
    );
    my ($fh, $filename) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
    close $fh;
    my $zip = Archive::Zip->new;
    $zip->addString($members{$_}, $_) for keys %members;
    die 'Cannot create workbook' unless $zip->writeToFileNamed($filename) == AZ_OK;
    return Spreadsheet::XLSX->new($filename)->worksheet(0);
}

my @cases = (
    ['dddd', '42598.25351851853', 'Tuesday', 'Date'],
    ['ddd', '42598.25351851853', 'Tue', 'Date'],
    ['AM/PM', '0.25351851851851853', 'AM', 'Text'],
    ['AM/PM', '0.75351851851851848', 'PM', 'Text'],
    ['A/P', '0.75', 'P', 'Text'],
    ['am/pm', '0.25', 'am', 'Text'],
    ['yyyy', '42598', '2016', 'Date'],
    ['[$-409]dd\\-mmm\\-yy;@', '41510', '24-Aug-13', 'Date'],
    ['dd"-"mmm"-"yy', '41511', '25-Aug-13', 'Date'],
    ['"AM/PM"0', '2', 'AM/PM2', 'Numeric'],
    ['"ddd"0', '2', 'ddd2', 'Numeric'],
);
my @warnings;
{
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $sheet = parse_formats(@cases);
    for my $row (0 .. $#cases) {
        my ($format, $raw, $display, $type) = @{$cases[$row]};
        my $cell = $sheet->get_cell($row, 0);
        is($cell->value, $display, "formatted cell using $format ($raw)");
        is($cell->type, $type, "cell type using $format");
        # Retain the existing convention that pure times (<1) become Text.
        is($cell->unformatted, $type eq 'Text' ? $display : $raw,
            "existing raw-value convention for $format");
    }
}
is_deeply(\@warnings, [], 'formatting emits no warnings');
done_testing();
