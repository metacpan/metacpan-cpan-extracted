use strict;
use warnings;
use utf8;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use Encode qw(encode decode);
use File::Temp qw(tempfile);
use Spreadsheet::XLSX;

{
    package NameConverter;
    sub convert {
        my ($self, $text) = @_;
        push @{$self->{seen}}, $text;
        return undef if $self->{fail};
        return Encode::decode('UTF-8', $text);
    }
}

sub workbook {
    my ($name, $converter) = @_;
    my %members = (
        'xl/workbook.xml' => qq{<workbook xmlns:r="x"><sheets><sheet name="$name" sheetId="1" r:id="rId1"/></sheets></workbook>},
        'xl/_rels/workbook.xml.rels' => '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
        'xl/worksheets/sheet1.xml' => '<worksheet><sheetData><row r="1"><c r="A1"><v>42</v></c></row></sheetData></worksheet>',
    );
    my ($fh, $file) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
    close $fh;
    my $zip = Archive::Zip->new;
    $zip->addString(encode('UTF-8', $members{$_}), $_) for keys %members;
    die 'Cannot create workbook' unless $zip->writeToFileNamed($file) == AZ_OK;
    return Spreadsheet::XLSX->new($file, $converter);
}

my @cases = (
    ['Sales &amp; Costs', 'Sales & Costs'],
    ['&lt;Q1&gt; &quot;x&quot; &apos;y&apos;', '<Q1> "x" \'y\''],
    ['&#65;&#x42;&#00067;', 'ABC'],
    ['é &#233; &#x8AB2;', 'é é 課'],
    ['&amp;lt; &amp;#65; &amp;amp;', '&lt; &#65; &amp;'],
    ['Ordinary name', 'Ordinary name'],
);
for my $case (@cases) {
    for my $convert (0, 1) {
        my $converter = $convert ? bless({seen => []}, 'NameConverter') : undef;
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        my $book = workbook($case->[0], $converter);
        my $expected = $convert ? $case->[1] : encode('UTF-8', $case->[1]);
        is($book->worksheet(0)->{Name}, $expected, 'worksheet name decoded once');
        my $sheet = $book->worksheet($expected);
        ok(defined $sheet, 'lookup by decoded name succeeds');
        is($sheet->get_cell(0, 0)->unformatted, 42, 'worksheet contents preserved') if $sheet;
        is_deeply($converter->{seen}, [encode('UTF-8', $case->[1])],
            'converter receives decoded UTF-8 bytes exactly once') if $convert;
        is_deeply(\@warnings, [], 'no parsing warnings');
    }
}

my $book = eval { workbook('Name', bless({fail => 1}, 'NameConverter')) };
ok(!defined $book, 'undefined name conversion aborts parsing');
like($@, qr/XLSX worksheet name conversion failed: the converter returned undef/,
    'meaningful name conversion error');
for my $name ('&#0;', '&#xD800;') {
    my $invalid = eval { workbook($name) };
    ok(!defined $invalid, 'invalid XML character reference in name rejected');
    like($@, qr/Invalid XML character reference/, 'controlled character-reference error');
}
done_testing();
