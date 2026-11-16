use strict;
use warnings;
use utf8;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use Encode qw(encode decode);
use File::Temp qw(tempfile);
use Spreadsheet::XLSX;

{
    package EntityConverter;
    sub new { bless {}, shift }
    sub convert { Encode::decode('UTF-8', $_[1]) }
}

my @cases = (
    ['<t>&amp; &lt; &gt; &quot; &apos;</t>', '& < > " \''],
    ['<t>&#38; &#x26; &#65; &#x41;</t>', '& & A A'],
    ['<t>&#00000000000065; &#x00000000000041;</t>', 'A A'],
    ['<t>&amp;lt; &amp;#65; &amp;amp; &#38;lt;</t>', '&lt; &#65; &amp; &lt;'],
    ['<t>é &#233; &#xE9; 課 &#35506; &#x8AB2; 😀 &#128512; &#x1F600;</t>', 'é é é 課 課 課 😀 😀 😀'],
    ["<t xml:space=\"preserve\"> &#9;A&#10;B&#13; </t>", " \tA\nB\r "],
    ['<r><t>&amp;</t></r><r><t>lt;</t></r>', '&lt;'],
    ['<t>base&amp;</t><rPh sb="0" eb="1"><t>&#x30AB;&amp;</t></rPh>', 'base&'],
);

sub parse_text {
    my ($converter, $invalid) = @_;
    my ($strings, $rows) = ('', '');
    for my $i (0 .. $#cases) {
        my $row = $i + 1;
        my $content = $i == 0 && defined($invalid) ? "<t>$invalid</t>" : $cases[$i][0];
        $strings .= "<si>$content</si>";
        $rows .= qq{<row r="$row"><c r="A$row" t="s"><v>$i</v></c>}
            . qq{<c r="B$row" t="inlineStr"><is>$content</is></c></row>};
    }
    my %members = (
        'xl/workbook.xml' => '<workbook xmlns:r="x"><sheets><sheet name="Data" sheetId="1" r:id="rId1"/></sheets></workbook>',
        'xl/_rels/workbook.xml.rels' => '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
        'xl/sharedStrings.xml' => "<sst>$strings</sst>",
        'xl/worksheets/sheet1.xml' => "<worksheet><sheetData>$rows</sheetData></worksheet>",
    );
    my ($fh, $filename) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
    close $fh;
    my $zip = Archive::Zip->new;
    $zip->addString(encode('UTF-8', $members{$_}), $_) for keys %members;
    die 'Cannot create workbook' unless $zip->writeToFileNamed($filename) == AZ_OK;
    return Spreadsheet::XLSX->new($filename, $converter)->worksheet(0);
}

for my $converter (undef, EntityConverter->new) {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $sheet = parse_text($converter);
    for my $row (0 .. $#cases) {
        my $expected = $converter ? $cases[$row][1] : encode('UTF-8', $cases[$row][1]);
        for my $col (0, 1) {
            my $cell = $sheet->get_cell($row, $col);
            is($cell->unformatted, $expected, "decoded raw text for row $row, column $col");
            is($cell->value, $expected, 'formatted text is not decoded a second time');
        }
    }
    my $hint = $converter ? 'カ&' : encode('UTF-8', 'カ&');
    is($sheet->get_cell($#cases,0)->{RPh}[0]{Val}, $hint, 'shared phonetic text decoded');
    is($sheet->get_cell($#cases,1)->{RPh}[0]{Val}, $hint, 'inline phonetic text decoded');
    is_deeply(\@warnings, [], 'entity decoding emits no warnings');
}

for my $reference ('&#0;', '&#xD800;', '&#x110000;', '&#1114112;', '&#999999999999999999999;') {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $sheet = eval { parse_text(undef, $reference) };
    my $error = $@;
    ok(!$sheet, 'invalid XML character reference rejected');
    like($error, qr/Invalid XML character reference/, 'controlled character-reference error');
    is_deeply(\@warnings, [], 'invalid code point does not cause numeric conversion warnings');
}

# Original Example.xlsx from RT #93962.
my $filename = __FILE__;
$filename =~ s/\.t\z/.xlsx/;
my $sheet = Spreadsheet::XLSX->new($filename)->worksheet(0);
my $expected = 'IGNORE{CP1=0}, IGNORE{CP3=0}, IGNORE{CP1=1 & CP2=1 & CP3=1 & CP4=1}';
for my $row (33,34) {
    is($sheet->get_cell($row,10)->value, $expected, 'original K34/K35 contains ordinary ampersands');
    is($sheet->get_cell($row,10)->unformatted, $expected, 'original raw text decoded too');
}
is($sheet->get_cell(35,10)->value, 'AUTO', 'following cell unaffected');
done_testing();
