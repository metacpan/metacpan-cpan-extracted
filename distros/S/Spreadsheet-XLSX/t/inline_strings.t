use strict;
use warnings;
use utf8;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use Encode qw(encode decode);
use File::Temp qw(tempfile);
use Spreadsheet::XLSX;

{
    package InlineConverter;
    sub new { bless {}, shift }
    sub convert { Encode::decode('UTF-8', $_[1]) }
}

my @cases = (
    ['<t>Email</t>', 'Email'],
    ['<t>00123</t>', '00123'],
    ['<t>1E-3</t>', '1E-3'],
    ["<t xml:space=\"preserve\"> leading\n\ntrailing </t>", " leading\n\ntrailing "],
    ['<r><rPr><b/></rPr><t>Rich</t></r><r><t xml:space="preserve"> text</t></r>', 'Rich text'],
    ['<t/>', ''],
    ['<t xml:space="preserve"/>', ''],
    ['<t></t>', ''],
    ['<t/><r><t>after empty run</t></r>', 'after empty run'],
    ['<t>課きく 毛こ</t><rPh sb="0" eb="1"><t>カ</t></rPh><phoneticPr fontId="1" type="Hiragana"/>', '課きく 毛こ'],
);

sub parse_strings {
    my ($inline_only, $converter) = @_;
    my @cells;
    my $strings = '';
    for my $index (0 .. $#cases) {
        my $row = $index + 2;
        my $content = $cases[$index][0];
        # A date style must not cause inline text to be treated as numeric/date.
        push @cells, qq{<row r="$row"><c s="0" t="inlineStr" r="C$row"><is>$content</is></c>}
            . qq{<c r="D$row"><v>42</v></c>}
            . ($inline_only ? '' : qq{<c r="E$row" t="s"><v>$index</v></c>}) . '</row>';
        $strings .= "<si>$content</si>";
    }
    push @cells, '<row r="12"><c r="C12" t="inlineStr"><is/></c>'
        . '<c r="D12" t="inlineStr"><is xml:space="preserve"/></c>'
        . '<c r="E12"><v>7</v></c></row>';
    my %members = (
        'xl/workbook.xml' => '<workbook xmlns:r="x"><sheets><sheet name="Data" sheetId="1" r:id="rId1"/></sheets></workbook>',
        'xl/_rels/workbook.xml.rels' => '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
        'xl/worksheets/sheet1.xml' => '<worksheet><sheetData>' . join('', @cells) . '</sheetData></worksheet>',
        'xl/styles.xml' => '<styleSheet><cellXfs><xf numFmtId="14"/></cellXfs></styleSheet>',
    );
    $members{'xl/sharedStrings.xml'} = "<sst>$strings</sst>" unless $inline_only;
    my ($fh, $filename) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
    close $fh;
    my $zip = Archive::Zip->new;
    $zip->addString(encode('UTF-8', $members{$_}), $_) for keys %members;
    die 'Cannot create workbook' unless $zip->writeToFileNamed($filename) == AZ_OK;
    return Spreadsheet::XLSX->new($filename, $converter)->worksheet(0);
}

for my $inline_only (0, 1) {
    for my $converter (undef, InlineConverter->new) {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        my $sheet = parse_strings($inline_only, $converter);
        for my $index (0 .. $#cases) {
            my $cell = $sheet->get_cell($index + 1, 2);
            ok($cell, "inline cell $index exists (inline-only=$inline_only)");
            next unless $cell;
            my $expected = $converter ? $cases[$index][1] : encode('UTF-8', $cases[$index][1]);
            is($cell->value, $expected, 'inline display text and whitespace preserved');
            is($cell->unformatted, $expected, 'inline raw text preserved');
            is($cell->type, 'Text', 'inline string is text even with a date style');
            is($sheet->get_cell($index + 1, 3)->unformatted, '42', 'following numeric cell unaffected');
            unless ($inline_only) {
                my $shared = $sheet->get_cell($index + 1, 4);
                is($cell->value, $shared->value, 'inline and shared text agree');
                is_deeply($cell->{RPh}, $shared->{RPh}, 'inline and shared phonetic runs agree');
                is_deeply($cell->{PhoneticPr}, $shared->{PhoneticPr}, 'inline and shared phonetic properties agree');
            }
        }
        my $hint = $converter ? 'カ' : encode('UTF-8', 'カ');
        is_deeply($sheet->get_cell(10, 2)->{RPh}, [{ Val => $hint, Sb => 0, Eb => 1 }],
            'inline phonetic hints remain separate from text');
        is($sheet->get_cell(11, 2)->value, '', 'self-closing is produces empty text cell');
        is($sheet->get_cell(11, 3)->value, '', 'self-closing is with attributes produces empty text cell');
        is($sheet->get_cell(11, 4)->unformatted, '7', 'parsing continues after empty inline strings');
        is_deeply([$sheet->row_range], [1, 11], 'inline strings update row bounds');
        is_deeply([$sheet->col_range], [2, 4], 'inline strings update column bounds');
        is_deeply(\@warnings, [], 'inline strings parse without warnings');
    }
}

done_testing();
