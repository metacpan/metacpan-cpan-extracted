use strict;
use warnings;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use File::Temp qw(tempfile);
use Spreadsheet::XLSX;

sub parse_style {
    my ($reference, $declaration, $format_code) = @_;
    $format_code = '0.000' unless defined $format_code;
    my @references = ref($reference) eq 'ARRAY' ? @$reference : ($reference);
    my %members = (
        'xl/workbook.xml' => '<workbook xmlns:r="x"><sheets><sheet name="S1" sheetId="1" r:id="rId1"/></sheets></workbook>',
        'xl/_rels/workbook.xml.rels' => '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
        'xl/styles.xml' => '<styleSheet>'
            . (defined($declaration) ? qq{<numFmts><numFmt numFmtId="$declaration" formatCode="$format_code"/></numFmts>} : '')
            . '<cellXfs>' . join('', map { qq{<xf numFmtId="$_"/>} } @references)
            . '</cellXfs></styleSheet>',
        'xl/worksheets/sheet1.xml' => '<worksheet><sheetData>'
            . join('', map { my $row = $_ + 1; qq{<row r="$row"><c r="A$row" s="$_"><v>2</v></c></row>} } 0 .. $#references)
            . '</sheetData></worksheet>',
    );
    my ($fh, $filename) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
    close $fh;
    my $zip = Archive::Zip->new;
    $zip->addString($members{$_}, $_) for keys %members;
    die 'Cannot create test workbook' unless $zip->writeToFileNamed($filename) == AZ_OK;
    return Spreadsheet::XLSX->new($filename);
}

for my $id ('(', '.*', '164|14', '(a+)+$', '[0-9]+', '', '-1', '1.5',
    ' 164', '164junk', '1e2') {
    for my $location ('reference', 'declaration') {
        my $ok = eval {
            $location eq 'reference' ? parse_style($id, '164') : parse_style('164', $id);
            1;
        };
        ok(!$ok, "reject invalid $location ID: $id");
        like($@, qr/\AInvalid XLSX number format ID\n\z/,
            'controlled validation error instead of regex compilation');
    }
}

is(parse_style('164', '164')->{Worksheet}[0]{Cells}[0][0]->value(),
    '2.000', 'custom numeric format ID still resolves');
is(parse_style('0', undef)->{Worksheet}[0]{Cells}[0][0]->value(),
    '2', 'default numeric format ID still resolves');
is(parse_style('14', undef)->{Worksheet}[0]{Cells}[0][0]->value(),
    '1900-01-02', 'built-in date format ID still resolves');
for my $references (['164', '164'], ['0', '164', '164', '164'],
    ['164', '0', '164', '14', '164']) {
    my $sheet = parse_style($references, '164', '00000')->worksheet(0);
    for my $row (0 .. $#$references) {
        my $id = $references->[$row];
        my $cell = $sheet->get_cell($row, 0);
        is($cell->value(), $id eq '164' ? '00002' : $id eq '14' ? '1900-01-02' : '2',
            "RT #132420: format $id preserved at style index $row (@$references)");
        is($cell->unformatted(), '2', 'underlying numeric value is preserved');
    }
}

done_testing();
