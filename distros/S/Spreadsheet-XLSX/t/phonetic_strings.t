use strict;
use warnings;
use utf8;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use Encode qw(encode decode);
use File::Temp qw(tempfile);
use Spreadsheet::XLSX;

{
    package TestConverter;
    sub new { bless {}, shift }
    sub convert { Encode::decode('UTF-8', $_[1]) }
}

sub parse_strings {
    my ($converter) = @_;
    my %members = (
        'xl/workbook.xml' => '<workbook xmlns:r="x"><sheets><sheet name="S1" sheetId="1" r:id="rId1"/></sheets></workbook>',
        'xl/_rels/workbook.xml.rels' => '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
        'xl/sharedStrings.xml' => '<sst><si><t>課きく 毛こ</t>'
            . '<rPh sb="0" eb="1"><t>カ</t></rPh>'
            . "<rPh\n eb=\"5\" sb=\"4\"><t>ケ</t></rPh>"
            . '<phoneticPr fontId="1"/></si>'
            . '<si><r><t>Rich</t></r><rPh sb="0" eb="4"><t>hint</t></rPh>'
            . '<r><t xml:space="preserve"> text </t></r>'
            . '<phoneticPr alignment="center" type="Hiragana" fontId="2"/></si>'
            . '<si><t>following</t></si></sst>',
        'xl/worksheets/sheet1.xml' => '<worksheet><sheetData><row>'
            . '<c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c>'
            . '<c r="C1" t="s"><v>2</v></c><c r="D1" t="s"><v>0</v></c>'
            . '</row></sheetData></worksheet>',
    );
    my ($fh, $filename) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
    close $fh;
    my $zip = Archive::Zip->new;
    $zip->addString(encode('UTF-8', $members{$_}), $_) for keys %members;
    die 'Cannot create workbook' unless $zip->writeToFileNamed($filename) == AZ_OK;
    return Spreadsheet::XLSX->new($filename, $converter)->worksheet(0);
}

for my $converter (undef, TestConverter->new) {
    my $sheet = parse_strings($converter);
    my $expected = sub { $converter ? $_[0] : encode('UTF-8', $_[0]) };
    my $cell = $sheet->get_cell(0, 0);
    is($cell->value, $expected->('課きく 毛こ'), 'phonetic hints are excluded from displayed text');
    is($cell->unformatted, $expected->('課きく 毛こ'), 'phonetic hints are excluded from raw text');
    is_deeply($cell->{RPh}, [
        { Val => $expected->('カ'), Sb => 0, Eb => 1 },
        { Val => $expected->('ケ'), Sb => 4, Eb => 5 },
    ], 'phonetic runs and offsets are available separately');
    is_deeply($cell->{PhoneticPr}, { FontId => 1 }, 'missing optional phonetic properties stay absent');
    is($sheet->get_cell(0, 1)->value, 'Rich text ', 'rich text and whitespace preserved');
    is_deeply($sheet->get_cell(0, 1)->{PhoneticPr},
        { FontId => 2, Type => 'Hiragana', Alignment => 'center' }, 'phonetic properties exposed');
    is($sheet->get_cell(0, 2)->value, 'following', 'following shared string keeps correct index');
    ok(!exists $sheet->get_cell(0, 2)->{RPh}, 'ordinary cell has no phonetic metadata');
    $cell->{RPh}[0]{Val} = 'changed';
    is($sheet->get_cell(0, 3)->{RPh}[0]{Val}, $expected->('カ'), 'cells do not share mutable phonetic metadata');
    $cell->{PhoneticPr}{FontId} = 99;
    is($sheet->get_cell(0, 3)->{PhoneticPr}{FontId}, 1, 'phonetic properties are independent per cell');
}

done_testing();
