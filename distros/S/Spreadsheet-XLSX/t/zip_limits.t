use strict;
use warnings;
use Test::More;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use File::Temp qw(tempfile);
use Spreadsheet::XLSX;

my %base = (
    'xl/workbook.xml' => '<workbook xmlns:r="x"><sheets><sheet name="S1" sheetId="1" r:id="rId1"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels' => '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
    'xl/worksheets/sheet1.xml' => '<worksheet><sheetData><row><c r="A1"><v>2</v></c></row></sheetData></worksheet>',
    'xl/sharedStrings.xml' => '<sst><si><t>hello</t></si></sst>',
    'xl/styles.xml' => '<styleSheet><cellXfs><xf numFmtId="0"/></cellXfs></styleSheet>',
);

sub archive {
    my ($members, $stored) = @_;
    my ($fh, $filename) = tempfile(SUFFIX => '.xlsx', UNLINK => 1);
    close $fh;
    my $zip = Archive::Zip->new;
    for my $name (sort keys %$members) {
        my $member = $zip->addString($members->{$name}, $name);
        $member->desiredCompressionMethod($stored ? COMPRESSION_STORED : COMPRESSION_DEFLATED);
    }
    die 'Cannot create test archive' unless $zip->writeToFileNamed($filename) == AZ_OK;
    return $filename;
}

sub rejects {
    my ($filename, $pattern, $description) = @_;
    my $ok = eval { Spreadsheet::XLSX->new($filename); 1 };
    my $error = $@;
    ok(!$ok, $description);
    like($error, $pattern, 'controlled ZIP validation error');
}

for my $stored (0, 1) {
    my $filename = archive(\%base, $stored);
    is(Spreadsheet::XLSX->new($filename)->{Worksheet}[0]{Cells}[0][0]->value(),
        '2', 'ordinary workbook parses');
    open my $fh, '<', $filename or die $!;
    binmode $fh;
    is(Spreadsheet::XLSX->new($fh)->{Worksheet}[0]{Cells}[0][0]->value(),
        '2', 'filehandle input parses');
    close $fh;
}

my $filename = archive(\%base);
{
    local $Spreadsheet::XLSX::MAX_MEMBERS = scalar(keys %base) - 1;
    rejects($filename, qr/entry count exceeds limit/, 'too many entries rejected');
}
my $total = 0;
my $largest = 0;
for my $data (values %base) {
    $total += length($data);
    $largest = length($data) if length($data) > $largest;
}
{
    local $Spreadsheet::XLSX::MAX_MEMBER_SIZE = $largest;
    local $Spreadsheet::XLSX::MAX_TOTAL_SIZE = $total;
    local $Spreadsheet::XLSX::MAX_MEMBERS = scalar(keys %base);
    ok(Spreadsheet::XLSX->new($filename), 'exact limits accepted');
}
{
    local $Spreadsheet::XLSX::MAX_TOTAL_SIZE = $total - 1;
    rejects($filename, qr/total size exceeds limit/, 'aggregate size rejected');
}
{
    local $Spreadsheet::XLSX::MAX_MEMBER_SIZE = 1024;
    my %members = (%base, 'unused.bin' => 'x' x 8192);
    rejects(archive(\%members), qr/member size exceeds limit/,
        'highly compressed unused member is included in preflight');
}

# Change only the central-directory size, leaving compressed data intact.
sub forge_size {
    my ($filename, $target, $size) = @_;
    open my $fh, '<', $filename or die $!;
    binmode $fh;
    my $bytes = do { local $/; <$fh> };
    close $fh;
    my $offset = 0;
    my $found = 0;
    while (($offset = index($bytes, "PK\x01\x02", $offset)) >= 0) {
        my ($name_length, $extra_length, $comment_length) =
            unpack('vvv', substr($bytes, $offset + 28, 6));
        if (substr($bytes, $offset + 46, $name_length) eq $target) {
            substr($bytes, $offset + 24, 4) = pack('V', $size);
            $found = 1;
            last;
        }
        $offset += 46 + $name_length + $extra_length + $comment_length;
    }
    die 'Missing central-directory entry' unless $found;
    open $fh, '>', $filename or die $!;
    binmode $fh;
    print {$fh} $bytes;
    close $fh;
}

for my $name (sort keys %base) {
    for my $delta (-1, 1) {
        my $forged = archive(\%base);
        forge_size($forged, $name, length($base{$name}) + $delta);
        rejects($forged, qr/member size does not match metadata/,
            "actual size checked for $name (delta $delta)");
    }
}
{
    local $Spreadsheet::XLSX::MAX_MEMBER_SIZE = 1024;
    my %members = (%base, 'xl/sharedStrings.xml' => '<sst>' . ('x' x 8192) . '</sst>');
    my $forged = archive(\%members);
    forge_size($forged, 'xl/sharedStrings.xml', 100);
    rejects($forged, qr/member size exceeds limit/, 'actual inflated bytes enforce limit');
}

done_testing();
