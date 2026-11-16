use strict;
use warnings;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use File::Temp qw(tempfile);
use Spreadsheet::XLSX;

for my $after_name (' ', "\n", "\r\n", "\t") {
    for my $between (' ', "\n", "\r\n", "\t") {
        for my $reverse (0, 1) {
            my @attributes = ('Id="rId1"',
                'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"',
                'Target="worksheets/sheet1.xml"');
            @attributes = reverse @attributes if $reverse;
            my %members = (
                'xl/workbook.xml' => '<workbook xmlns:r="x"><sheets><sheet name="Data" sheetId="1" r:id="rId1"/></sheets></workbook>',
                'xl/_rels/workbook.xml.rels' => '<Relationships><Relationship'
                    . $after_name . join($between, @attributes)
                    . '/><Relationship Id="rId2" Target="worksheets/sheet2.xml"/></Relationships>',
                'xl/worksheets/sheet1.xml' => '<worksheet><sheetData><row r="1"><c r="A1"><v>42</v></c></row></sheetData></worksheet>',
            );
            my ($fh, $filename) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
            close $fh;
            my $zip = Archive::Zip->new;
            $zip->addString($members{$_}, $_) for keys %members;
            die 'Cannot create workbook' unless $zip->writeToFileNamed($filename) == AZ_OK;
            my @warnings;
            local $SIG{__WARN__} = sub { push @warnings, @_ };
            my $sheet = Spreadsheet::XLSX->new($filename)->worksheet(0);
            my $cell = $sheet->get_cell(0, 0);
            is($cell ? $cell->value : undef, 42,
                'worksheet relationship resolves with XML whitespace and either attribute order');
            is_deeply(\@warnings, [], 'no undefined-path warnings (RT #111087)');
        }
    }
}

done_testing();
