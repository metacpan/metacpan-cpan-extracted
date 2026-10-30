use strict;
use warnings;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use File::Temp qw(tempfile);
use Spreadsheet::XLSX;
use Spreadsheet::XLSX::Utility2007 qw(ExcelFmt);

for my $case (
    ['>2', 3, 1], ['>2', 2, 0], ['>=2', 2, 1], ['>=2', 1, 0],
    ['<2', 1, 1], ['<2', 2, 0], ['<=2', 2, 1], ['<=2', 3, 0],
    ['=2', 2, 1], ['=2', 3, 0], ['==2', 2, 1], ['==2', 3, 0],
    ['<>2', 3, 1], ['<>2', 2, 0], ['> -1.5', -1, 1],
    ['>=.5', '0.5', 1], ['=1.', 1, 1], ['=+1e2', 100, 1],
    ['=1E-2', '0.01', 1],
) {
    my ($condition, $value, $matches) = @$case;
    is(ExcelFmt("[$condition]0.0;0.00", $value),
        sprintf($matches ? '%.1f' : '%.2f', $value), "$value compared with $condition");
}

our $executed = 0;
my $payload = '>0 and do { $main::executed = 1 }';
for my $condition ($payload, '>0 trailing', '=>1', '>1e', '>NaN', '>1\n') {
    is(ExcelFmt("[$condition]0.0;0.00", 1), '1.00',
        "invalid condition uses fallback: $condition");
}
is($executed, 0, 'format condition cannot execute Perl');
ExcelFmt('[>0]"yes";"no"', '1"; $main::executed = 1; #');
is($executed, 0, 'cell value cannot execute Perl');

# Exercise the public parser path with a crafted workbook, without OS commands.
my %members = (
    'xl/workbook.xml' => '<workbook xmlns:r="x"><sheets><sheet name="S1" sheetId="1" r:id="rId1"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels' => '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
    'xl/styles.xml' => qq{<styleSheet><numFmts count="1"><numFmt numFmtId="164" formatCode="[$payload]0;0"/></numFmts><cellXfs count="1"><xf numFmtId="164" fontId="0" fillId="0" borderId="0"/></cellXfs></styleSheet>},
    'xl/worksheets/sheet1.xml' => '<worksheet><sheetData><row r="1"><c r="A1" s="0"><v>1</v></c></row></sheetData></worksheet>',
);
my ($fh, $filename) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
close $fh;
my $zip = Archive::Zip->new;
$zip->addString($members{$_}, $_) for keys %members;
is($zip->writeToFileNamed($filename), AZ_OK, 'created regression workbook');
my $workbook = Spreadsheet::XLSX->new($filename);
ok($workbook, 'crafted workbook parses');
is($executed, 0, 'parsing workbook cannot execute format condition');
is($workbook->{Worksheet}[0]{Cells}[0][0]->value(), '1', 'fallback formats value');
done_testing();
