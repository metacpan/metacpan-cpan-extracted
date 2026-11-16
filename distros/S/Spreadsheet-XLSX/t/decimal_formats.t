use strict;
use warnings;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use File::Temp qw(tempfile);
use Spreadsheet::XLSX;

sub parse_sheet {
    my ($columns, $rows) = @_;
    my %members = (
        'xl/workbook.xml' => '<workbook xmlns:r="x"><sheets><sheet name="Data" sheetId="1" r:id="rId1"/></sheets></workbook>',
        'xl/_rels/workbook.xml.rels' => '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
        'xl/styles.xml' => '<styleSheet><numFmts><numFmt numFmtId="164" formatCode="0.000"/></numFmts>'
            . '<cellXfs><xf numFmtId="0"/><xf numFmtId="2"/><xf numFmtId="164"/>'
            . '<xf numFmtId="4"/><xf numFmtId="15"/><xf numFmtId="22"/>'
            . '<xf numFmtId="9"/><xf numFmtId="10"/></cellXfs></styleSheet>',
        'xl/worksheets/sheet1.xml' => "<worksheet><cols>$columns</cols><sheetData>$rows</sheetData></worksheet>",
    );
    my ($fh, $filename) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
    close $fh;
    my $zip = Archive::Zip->new;
    $zip->addString($members{$_}, $_) for keys %members;
    die 'Cannot create workbook' unless $zip->writeToFileNamed($filename) == AZ_OK;
    return Spreadsheet::XLSX->new($filename)->worksheet(0);
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };
my $sheet = parse_sheet('<col min="1" max="2" style="1"/>',
    '<row r="1"><c r="A1"><v>14</v></c><c r="B1" s="0"><v>14</v></c>'
    . '<c r="C1" s="1"><v>14</v></c><c r="D1" s="2"><v>14</v></c>'
    . '<c r="E1" s="3"><v>1234</v></c><c r="F1"><v>14</v></c></row>'
    . '<row r="2" s="2" customFormat="1"><c r="A2"><v>14</v></c>'
    . '<c r="B2" s="1"><v>14</v></c><c r="C2" s="0"><v>14</v></c></row>'
    . '<row r="3"><c r="A3"><v>14</v></c><c r="C3"><v>14</v></c></row>'
    . '<row r="4" s="2" customFormat="0"><c r="A4"><v>14</v></c></row>'
    . '<row r="5" s="0" customFormat="true"><c r="A5"><v>14</v></c></row>'
    . '<row r="6"><c r="A6" t="inlineStr"><is><t>0014</t></is></c></row>');
for my $case (
    [0,0,'14.00'], [0,1,'14'], [0,2,'14.00'], [0,3,'14.000'], [0,4,'1,234.00'], [0,5,'14'],
    [1,0,'14.000'], [1,1,'14.00'], [1,2,'14'],
    [2,0,'14.00'], [2,2,'14'], [3,0,'14.00'], [4,0,'14'],
) {
    my ($r,$c,$expected) = @$case;
    my $cell = $sheet->get_cell($r,$c);
    is($cell->value, $expected, "formatted value at row $r column $c");
    is($cell->unformatted, $r == 0 && $c == 4 ? '1234' : '14', 'raw numeric value unchanged');
}
is($sheet->get_cell(5,0)->value, '0014', 'inherited numeric style does not convert inline text');
is($sheet->get_cell(5,0)->type, 'Text', 'inline cell remains Text');

$sheet = parse_sheet('<col min="16384" max="16384" style="1"/>',
    '<row r="1"><c r="XFD1"><v>14</v></c></row>');
is($sheet->get_cell(0,16383)->value, '14.00', 'last XLSX column supports default style');

$sheet = parse_sheet('', '<row r="1"><c r="A1" s="4"><v>41510</v></c>'
    . '<c r="B1" s="5"><v>41510.5</v></c><c r="C1" s="6"><v>0.14</v></c>'
    . '<c r="D1" s="7"><v>0.14</v></c></row>');
is($sheet->get_cell(0,0)->value, '24-Aug-13', 'built-in date 15 resolved');
is($sheet->get_cell(0,0)->type, 'Date', 'built-in date 15 detected');
is($sheet->get_cell(0,1)->value, '8-24-13 12:00', 'built-in date/time 22 resolved');
is($sheet->get_cell(0,2)->value, '14%', 'built-in integer percentage');
is($sheet->get_cell(0,3)->value, '14.00%', 'built-in decimal percentage');
is_deeply(\@warnings, [], 'style defaults parse without warnings');

for my $range (['0','2'], ['1','16385'], ['3','2'], ['1','999999999999999999999']) {
    my $book = eval { parse_sheet(qq{<col min="$range->[0]" max="$range->[1]" style="1"/>}, ''); };
    my $error = $@;
    ok(!$book, 'invalid styled column range rejected before expansion');
    like($error, qr/Invalid XLSX column style range/, 'controlled range error');
}

done_testing();
