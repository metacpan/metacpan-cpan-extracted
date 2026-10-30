use strict;
use warnings;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use File::Temp qw(tempfile);
use Spreadsheet::XLSX;

sub parse_reference {
    my ($reference) = @_;
    my %members = (
        'xl/workbook.xml' => '<workbook xmlns:r="x"><sheets><sheet name="S1" sheetId="1" r:id="rId1"/></sheets></workbook>',
        'xl/_rels/workbook.xml.rels' => '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
        'xl/worksheets/sheet1.xml' => '<worksheet><sheetData><row><c r="A1"><v>1</v></c><c '
            . (defined($reference) ? qq{r="$reference"} : '')
            . '><v>2</v></c></row></sheetData></worksheet>',
    );
    my ($fh, $filename) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
    close $fh;
    my $zip = Archive::Zip->new;
    $zip->addString($members{$_}, $_) for keys %members;
    die 'Cannot create test workbook' unless $zip->writeToFileNamed($filename) == AZ_OK;
    return Spreadsheet::XLSX->new($filename);
}

for my $reference ('A0', 'A1048577', 'A9999999', 'A' . ('9' x 1000),
    'A01', 'A-1', 'A1junk', 'XFE1', 'AAAA1', '', undef) {
    my $workbook = eval { parse_reference($reference) };
    my $error = $@;
    ok(!$workbook, 'invalid reference rejects workbook');
    like($error, qr/(?:Invalid XLSX cell reference|XLSX cell (?:row|column) exceeds worksheet limit)/,
        'controlled validation error before cell allocation');
}

for my $case (['A1', 0, 0], ['ZZ1', 0, 701], ['AAA1', 0, 702],
    ['XFD1', 0, 16383], ['A1048576', 1048575, 0]) {
    my ($reference, $row, $col) = @$case;
    my $workbook = parse_reference($reference);
    is($workbook->{Worksheet}[0]{Cells}[$row][$col]->value(), '2',
        "valid reference $reference is decoded correctly");
}

done_testing();
