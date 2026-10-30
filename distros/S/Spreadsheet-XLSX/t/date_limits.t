use strict;
use warnings;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use File::Temp qw(tempfile);
use Spreadsheet::XLSX;
use Spreadsheet::XLSX::Utility2007 qw(ExcelFmt ExcelLocaltime);

for my $epoch (0, 1) {
    my $limit = $epoch ? 2957004 : 2958466;
    for my $value ($limit, $limit + 1, '1e+100', '1e+9999', -1,
        'NaN', 'Inf', 'not a number', undef) {
        my $ok = eval { ExcelLocaltime($value, $epoch); 1 };
        ok(!$ok, "invalid date rejected for epoch $epoch");
        like($@, qr/Invalid or out-of-range XLSX date value/, 'controlled error');
    }
    is(ExcelFmt('yyyy-mm-dd', $limit - 1, $epoch), '9999-12-31',
        "last supported date for epoch $epoch");
    is(ExcelFmt('yyyy-mm-dd hh:mm:ss', $limit - 0.5, $epoch),
        '9999-12-31 12:00:00', 'fractional time on last day is supported');
}
is(ExcelFmt('yyyy-mm-dd', 0, 1), '1904-01-01', '1904 epoch unchanged');
is(ExcelFmt('yyyy-mm-dd', 60, 0), '1900-02-29', 'Excel leap-year compatibility');
is(ExcelFmt('yyyy-mm-dd', 61, 0), '1900-03-01', 'date after Excel leap day');

# Verify that an extreme numeric cell is rejected through the public parser.
my %members = (
    'xl/workbook.xml' => '<workbook xmlns:r="x"><sheets><sheet name="S1" sheetId="1" r:id="rId1"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels' => '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
    'xl/styles.xml' => '<styleSheet><cellXfs><xf numFmtId="14"/></cellXfs></styleSheet>',
    'xl/worksheets/sheet1.xml' => '<worksheet><sheetData><row><c r="A1" s="0"><v>1e+100</v></c></row></sheetData></worksheet>',
);
my ($fh, $filename) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
close $fh;
my $zip = Archive::Zip->new;
$zip->addString($members{$_}, $_) for keys %members;
is($zip->writeToFileNamed($filename), AZ_OK, 'created date regression workbook');
my $ok = eval { Spreadsheet::XLSX->new($filename); 1 };
ok(!$ok, 'parser rejects extreme date cell');
like($@, qr/Invalid or out-of-range XLSX date value/, 'parser propagates controlled error');
done_testing();
