use strict;
use warnings;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use File::Temp qw(tempfile);
use Spreadsheet::XLSX;

sub parse_values {
    my ($cells) = @_;
    my %members = (
        'xl/workbook.xml' => '<workbook xmlns:r="x"><sheets><sheet name="S1" sheetId="1" r:id="rId1"/></sheets></workbook>',
        'xl/_rels/workbook.xml.rels' => '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
        'xl/worksheets/sheet1.xml' => '<worksheet><sheetData><row>'
            . $cells . '</row></sheetData></worksheet>',
    );
    my ($fh, $filename) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
    close $fh;
    my $zip = Archive::Zip->new;
    $zip->addString($members{$_}, $_) for keys %members;
    die 'Cannot create test workbook' unless $zip->writeToFileNamed($filename) == AZ_OK;
    return Spreadsheet::XLSX->new($filename)->{Worksheet}[0];
}

for my $opening ('<v>', '<v xml:space="preserve">', "<v\nxml:space=\"preserve\">") {
    for my $value ('Single line', "Multiline line1\n line2", "\n leading\n\ntrailing \n") {
        my $sheet = parse_values('<c r="A1" t="str">' . $opening . $value
            . '</v></c><c r="B1"><v>42</v></c>');
        is($sheet->{Cells}[0][0]->value(), $value,
            'value and whitespace preserved for ' . $opening);
        is($sheet->{Cells}[0][1]->value(), 42, 'following numeric cell unaffected');
    }
}

my $sheet = parse_values('<c r="A1" t="str"><value>ignored</value><v>kept</v></c>'
    . '<c r="B1" t="str"><v xml:space="preserve"/><ext>ignored</ext></c>'
    . '<c r="C1"><v>7</v></c>');
is($sheet->{Cells}[0][0]->value(), 'kept', 'similarly named tags are not value tags');
ok(!defined($sheet->{Cells}[0][1]), 'self-closing value tag does not consume following XML');
is($sheet->{Cells}[0][2]->value(), 7, 'parsing continues after empty value');

done_testing();
