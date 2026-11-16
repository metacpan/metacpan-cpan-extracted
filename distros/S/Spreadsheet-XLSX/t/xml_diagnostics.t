use strict;
use warnings;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use File::Temp qw(tempfile);
BEGIN {
    unshift @INC, sub {
        die "XML::Parser must not be required for XML diagnostics\n"
            if $_[1] =~ m{\AXML/Parser(?:\.pm|/)};
        return;
    };
}
use Spreadsheet::XLSX;

my $main = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
my $package = 'http://schemas.openxmlformats.org/package/2006/relationships';
my %base = (
    'xl/workbook.xml' => qq{<workbook xmlns="$main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Data" sheetId="1" r:id="rId1"/></sheets></workbook>},
    'xl/_rels/workbook.xml.rels' => qq{<Relationships xmlns="$package"><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>},
    'xl/worksheets/sheet1.xml' => qq{<worksheet xmlns="$main"><sheetData><row r="1"><c r="A1"><v>42</v></c></row></sheetData></worksheet>},
    'xl/sharedStrings.xml' => qq{<sst xmlns="$main"><si><t>text</t></si></sst>},
    'xl/styles.xml' => qq{<styleSheet xmlns="$main"><cellXfs><xf numFmtId="0"/></cellXfs></styleSheet>},
);

sub parse_members {
    my (%overrides) = @_;
    my %members = (%base, %overrides);
    my ($fh, $filename) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
    close $fh;
    my $zip = Archive::Zip->new;
    $zip->addString($members{$_}, $_) for keys %members;
    die 'Cannot create test workbook' unless $zip->writeToFileNamed($filename) == AZ_OK;
    return Spreadsheet::XLSX->new($filename);
}

sub rejection {
    my ($member, $xml, @patterns) = @_;
    my @warnings;
    my ($book, $error);
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $book = eval { parse_members($member => $xml) };
        $error = $@;
    }
    ok(!$book, "reject $member instead of returning partial data");
    like($error, $_, 'actionable diagnostic') for @patterns;
    is_deeply(\@warnings, [], 'no incidental uninitialized-value warnings');
}

is(parse_members()->worksheet(0)->get_cell(0, 0)->value(), 42,
    'default namespaces and relationship attribute prefix remain supported');

for my $member (sort keys %base) {
    my $namespace = $member =~ /\.rels\z/ ? $package : $main;
    for my $prefix ('x', 'custom') {
        my $xml = $base{$member};
        $xml =~ s{<(/?)([A-Za-z][A-Za-z0-9]*)}{<$1$prefix:$2}g;
        $xml =~ s/\Qxmlns="$namespace"\E/xmlns:$prefix="$namespace"/;
        rejection($member, $xml, qr/Unsupported namespace-prefixed element '$prefix:/,
            qr/\Q$member\E/, qr/valid XLSX/, qr/Use Spreadsheet::ParseXLSX/);
    }
    my $xml = $base{$member};
    $xml =~ s{</[^>]+>\z}{<broken};
    rejection($member, $xml, qr/Cannot parse XLSX XML member/, qr/\Q$member\E/,
        qr/unterminated or malformed XML tag/, qr/byte \d+/);
}

rejection('xl/worksheets/sheet1.xml',
    qq{<worksheet xmlns="$main"><sheetData><row ="4"/></sheetData></worksheet>},
    qr/Cannot parse XLSX XML member/, qr/malformed attributes in element 'row'/, qr/byte \d+/);
rejection('xl/worksheets/sheet1.xml', '<x:worksheet/>',
    qr/Unsupported namespace-prefixed element 'x:worksheet'/, qr/Use Spreadsheet::ParseXLSX/);
rejection('xl/workbook.xml', qq{<x:workbook xmlns:x="$main"><x:sheets></x:workbook>},
    qr/Unsupported namespace-prefixed element 'x:workbook'/, qr/Use Spreadsheet::ParseXLSX/);

for my $declaration ('<!DOCTYPE worksheet [<!ENTITY example "text">]>',
    '<!DOCTYPE worksheet SYSTEM "file:///must-not-be-read.dtd">') {
    rejection('xl/worksheets/sheet1.xml', $declaration . $base{'xl/worksheets/sheet1.xml'},
        qr/Cannot parse XLSX XML member/, qr/DOCTYPE declarations are not supported/);
}

rejection('xl/worksheets/sheet1.xml',
    qq{<worksheet xmlns="$main"><sheetData><row r="1"><c r="Artikelnummer1"><v>42</v></c></row></sheetData></worksheet>},
    qr/Invalid XLSX cell reference 'Artikelnummer1'/, qr/worksheet 'Data'/,
    qr{xl/worksheets/sheet1.xml}, qr/expected an A1-style address/);
rejection('xl/worksheets/sheet1.xml',
    qq{<worksheet xmlns="$main"><sheetData><row r="1"><c><v>42</v></c></row></sheetData></worksheet>},
    qr/Invalid XLSX cell reference \(missing r attribute\)/, qr/worksheet 'Data'/);

for my $case (
    ['<worksheet><row r=1/></worksheet>', qr/malformed attributes/],
    ['<worksheet><row r="1></row></worksheet>', qr/unterminated or malformed XML tag/],
    ['<worksheet><!-- unfinished', qr/unterminated XML comment/],
    ['<worksheet><![CDATA[unfinished', qr/unterminated CDATA section/],
    ['<?xml version="1.0"', qr/unterminated processing instruction/],
    ['<worksheet>< ="4"/></worksheet>', qr/malformed XML tag/],
) {
    rejection('xl/worksheets/sheet1.xml', $case->[0], qr/Cannot parse XLSX XML member/,
        $case->[1], qr/byte \d+/);
}

for my $element ('rPh', 'phoneticPr') {
    rejection('xl/sharedStrings.xml',
        qq{<sst><si><t>text</t><x:$element xmlns:x="$main"/></si></sst>},
        qr/Unsupported namespace-prefixed element 'x:$element'/,
        qr/Use Spreadsheet::ParseXLSX/);
}

my $workbook_extension = $base{'xl/workbook.xml'};
$workbook_extension =~ s{</workbook>}{<extLst><ext><x15:workbookPr xmlns:x15="http://schemas.microsoft.com/office/spreadsheetml/2010/11/main" chartTrackingRefBase="1"/></ext></extLst></workbook>};
is(parse_members('xl/workbook.xml' => $workbook_extension)->worksheet(0)->get_cell(0, 0)->value(),
    42, 'x15:workbookPr extension is ignored (RT #119170)');

my $with_extension = $base{'xl/worksheets/sheet1.xml'};
$with_extension =~ s{</worksheet>}{<!-- <x:c r="bad"/> --><ext:ignored xmlns:ext="urn:extension"><![CDATA[<x:v>]]></ext:ignored></worksheet>};
is(parse_members('xl/worksheets/sheet1.xml' => $with_extension)->worksheet(0)->get_cell(0, 0)->value(),
    42, 'foreign extensions, comments and CDATA do not trigger namespace rejection');

done_testing();
