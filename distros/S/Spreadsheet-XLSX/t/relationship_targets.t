use strict;
use warnings;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use File::Temp qw(tempfile);
use Spreadsheet::XLSX;

sub parse_target {
    my ($target, %options) = @_;
    my @attributes = ('Id="rId1"',
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/'
            . ($options{chart} ? 'chartsheet' : 'worksheet') . '"');
    push @attributes, qq{Target="$target"} if defined $target;
    push @attributes, 'TargetMode="External"' if $options{external};
    @attributes = reverse @attributes if $options{reverse};
    my %members = (
        'xl/workbook.xml' => '<workbook xmlns:r="x"><sheets><sheet sheetId="8" r:id="rId1" name="Data"/></sheets></workbook>',
        'xl/_rels/workbook.xml.rels' => '<Relationships>'
            . ($options{missing_relation} ? '' : '<Relationship ' . join($options{separator} || ' ', @attributes) . '/>')
            . '<Relationship Id="unused" Target="https://example.invalid/unused" TargetMode="External"/>'
            . '</Relationships>',
        'xl/worksheets/sheet1.xml' => '<worksheet><sheetData><row r="1"><c r="A1"><v>42</v></c></row></sheetData></worksheet>',
    );
    # An external target must not be interpreted as an existing ZIP member.
    $members{'https://example.invalid/sheet.xml'} = $members{'xl/worksheets/sheet1.xml'};
    my ($fh, $filename) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
    close $fh;
    my $zip = Archive::Zip->new;
    $zip->addString($members{$_}, $_) for keys %members;
    die 'Cannot create workbook' unless $zip->writeToFileNamed($filename) == AZ_OK;
    return Spreadsheet::XLSX->new($filename);
}

for my $target ('worksheets/sheet1.xml', '/xl/worksheets/sheet1.xml',
    './worksheets/./sheet1.xml', 'worksheets/sub/../sheet1.xml',
    '../xl/worksheets/sheet1.xml', '/xl/other/../worksheets/sheet1.xml') {
    for my $separator (' ', "\n", "\r\n") {
        for my $reverse (0, 1) {
            my @warnings;
            local $SIG{__WARN__} = sub { push @warnings, @_ };
            my $book = parse_target($target, separator => $separator, reverse => $reverse);
            is($book->worksheet(0)->get_cell(0, 0)->value, 42, "resolve target $target");
            is_deeply(\@warnings, [], 'no path warnings');
        }
    }
}

for my $case (
    ['../../outside.xml', {}, qr/escapes the package root/],
    ['/../outside.xml', {}, qr/escapes the package root/],
    ['worksheets/missing.xml', {}, qr{missing ZIP member 'xl/worksheets/missing.xml'}],
    ['worksheets/sheet1.xml', { missing_relation => 1 }, qr/Missing XLSX relationship/],
    [undef, {}, qr/missing Target attribute/],
    ['', {}, qr/Invalid XLSX package target/],
    ['https://example.invalid/sheet.xml', { external => 1 }, qr/External XLSX target/],
    ['worksheets/sheet1.xml', { external => 1 }, qr/External XLSX target/],
    ['https://example.invalid/sheet.xml', {}, qr/Invalid XLSX package target/],
) {
    my ($target, $options, $pattern) = @$case;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $book = eval { parse_target($target, %$options) };
    my $error = $@;
    ok(!$book, 'invalid referenced target rejects workbook');
    like($error, $pattern, 'specific target error');
    like($error, qr/worksheet 'Data'.*relationship 'rId1'/, 'worksheet and relationship identified');
    is_deeply(\@warnings, [], 'controlled error without incidental warnings');
}
my $chart = parse_target('chartsheets/chart1.xml', chart => 1);
is($chart->worksheet(0)->get_name, 'Data', 'chartsheet placeholder retained');
ok(!defined $chart->worksheet(0)->get_cell(0, 0), 'chartsheet does not require a cell worksheet member');

done_testing();
