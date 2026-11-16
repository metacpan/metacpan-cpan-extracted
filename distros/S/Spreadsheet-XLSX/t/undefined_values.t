use strict;
use warnings;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use File::Temp qw(tempfile);
use Spreadsheet::XLSX;

sub parse_strings {
    my ($strings) = @_;
    my %members = (
        'xl/workbook.xml' => '<workbook xmlns:r="x"><sheets><sheet name="Data" sheetId="1" r:id="rId1"/></sheets></workbook>',
        'xl/_rels/workbook.xml.rels' => '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
        'xl/worksheets/sheet1.xml' => '<worksheet><sheetData><row>'
            . '<c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c>'
            . '<c r="C1" t="s"><v>99</v></c><c r="D1"><v>42</v></c>'
            . '</row></sheetData></worksheet>',
    );
    $members{'xl/sharedStrings.xml'} = $strings if defined $strings;
    my ($fh, $filename) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
    close $fh;
    my $zip = Archive::Zip->new;
    $zip->addString($members{$_}, $_) for keys %members;
    die 'Cannot create workbook' unless $zip->writeToFileNamed($filename) == AZ_OK;
    return Spreadsheet::XLSX->new($filename)->worksheet(0);
}

for my $strings (undef, '<sst><si><t/></si><si><t>following</t></si></sst>') {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $sheet = parse_strings($strings);
    my $missing = $sheet->get_cell(0, 2);
    ok($missing, 'cell with unresolved shared-string index is retained');
    is($missing->type, 'Text', 'unresolved string remains a text cell');
    ok(!defined $missing->unformatted, 'undefined raw value remains undefined');
    is($missing->value, '', 'undefined text has empty formatted value');
    is($sheet->get_cell(0, 3)->value, 42, 'following numeric cell unaffected');
    if (defined $strings) {
        is($sheet->get_cell(0, 0)->unformatted, '', 'valid empty string remains defined');
        is($sheet->get_cell(0, 1)->value, 'following', 'valid shared-string index unaffected');
    } else {
        ok(!defined $sheet->get_cell(0, 0)->unformatted, 'missing shared-string table retains undefined value');
    }
    is_deeply(\@warnings, [], 'undefined shared-string values do not produce warnings (RT #114521)');
}

done_testing();
