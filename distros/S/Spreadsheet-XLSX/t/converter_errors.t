use strict;
use warnings;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use File::Temp qw(tempfile);
use Spreadsheet::XLSX;

{
    package SelectiveConverter;
    sub convert { return $_[1] eq 'fail' ? undef : $_[1] eq 'empty' ? '' : $_[1] }
}

sub parse_string {
    my ($kind, $text) = @_;
    my $content = "<r><t>before</t></r><r><t>$text</t></r><r><t>after</t></r>";
    $content = "<t>base</t><rPh sb=\"0\" eb=\"1\"><t>$text</t></rPh>"
        if $kind eq 'phonetic';
    my %members = (
        'xl/workbook.xml' => '<workbook xmlns:r="x"><sheets><sheet name="Data" sheetId="1" r:id="rId1"/></sheets></workbook>',
        'xl/_rels/workbook.xml.rels' => '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
    );
    my $cell;
    if ($kind eq 'inline') {
        $cell = "<c r=\"A1\" t=\"inlineStr\"><is>$content</is></c>";
    }
    else {
        $members{'xl/sharedStrings.xml'} = "<sst><si>$content</si></sst>";
        $cell = '<c r="A1" t="s"><v>0</v></c>';
    }
    $members{'xl/worksheets/sheet1.xml'} = "<worksheet><sheetData><row r=\"1\">$cell</row></sheetData></worksheet>";
    my ($fh, $filename) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
    close $fh;
    my $zip = Archive::Zip->new;
    $zip->addString($members{$_}, $_) for keys %members;
    die 'Cannot create workbook' unless $zip->writeToFileNamed($filename) == AZ_OK;
    return Spreadsheet::XLSX->new($filename, bless({}, 'SelectiveConverter'));
}

for my $kind (qw(shared inline phonetic)) {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $book = eval { parse_string($kind, 'fail') };
    my $error = $@;
    ok(!defined $book, "$kind: undefined conversion aborts parsing");
    like($error, qr/XLSX text conversion failed: the converter returned undef/,
        "$kind: meaningful conversion error");
    is_deeply(\@warnings, [], "$kind: no uninitialized-value warnings");

    my $cell = parse_string($kind, 'empty')->worksheet(0)->get_cell(0, 0);
    is($cell->unformatted, $kind eq 'phonetic' ? 'base' : 'beforeafter',
        "$kind: empty conversion accepted, other text preserved");
    is($cell->{RPh}[0]{Val}, '', 'empty phonetic conversion accepted') if $kind eq 'phonetic';
    $cell = parse_string($kind, 'normal')->worksheet(0)->get_cell(0, 0);
    is($cell->unformatted, $kind eq 'phonetic' ? 'base' : 'beforenormalafter',
        "$kind: defined conversion preserved");
}

done_testing();
