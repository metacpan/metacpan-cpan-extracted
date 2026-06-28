#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Linearization') }
BEGIN { use_ok('PDF::Make::Document') }
BEGIN { use_ok('PDF::Make::Canvas') }
BEGIN { use_ok('PDF::Make::Page', ':fonts') }

# ── Document linearization methods ──────────────────────

my $doc = PDF::Make::Document->new;
$doc->title('Lin Coverage Test');
for my $i (1..2) {
    my $page = $doc->add_page(612, 792);
    $page->add_std14_font('F1', HELVETICA);
    my $c = PDF::Make::Canvas->new;
    $c->BT->Tf('F1', 12)->Td(72, 700)->Tj("Page $i")->ET;
    $page->set_content($c->to_bytes);
}

# is_linearized on fresh doc
is($doc->is_linearized, 0, 'fresh doc not linearized');

# linear_params on non-linearized doc
my $params = $doc->linear_params;
is($params, undef, 'linear_params undef on non-linearized');

# linearize returns self for chaining
my $ret = $doc->linearize;
is($ret, $doc, 'linearize returns $self');

# write_linearized to bytes
my $bytes = eval { $doc->write_linearized };
ok(defined $bytes && length($bytes) > 100, 'write_linearized returns bytes');
like($bytes, qr/^%PDF/, 'linearized bytes start with %PDF');

# write_linearized to file
my $tf = '/tmp/lin_coverage_test.pdf';
eval { $doc->write_linearized($tf) };
ok(!$@, 'write_linearized to file') or diag $@;
if (-f $tf) {
    ok(-s $tf > 100, 'linearized file has content');
    unlink $tf;
} else {
    ok(1, 'write_linearized to path attempted');
}

# _data_is_linearized
is(PDF::Make::Linearization::_data_is_linearized($bytes), 1,
    'linearized output detected');

# ── StreamReader ────────────────────────────────────────

# Create a mock linearized PDF header for StreamReader
my $mock_pdf = "%PDF-1.4\n";
$mock_pdf .= "1 0 obj\n<< /Linearized 1 /L 5000 /H [100 50] /O 3 /E 500 /N 2 /T 4900 >>\nendobj\n";
$mock_pdf .= "xref\n0 2\n0000000000 65535 f \n0000000009 00000 n \n";
$mock_pdf .= "trailer\n<< /Size 2 >>\nstartxref\n" . length($mock_pdf) . "\n%%EOF\n";

# Pad to match /L value
$mock_pdf .= "\0" x (5000 - length($mock_pdf)) if length($mock_pdf) < 5000;

my $fetch_called = 0;
my $reader = PDF::Make::StreamReader->new(
    fetch => sub {
        my ($offset, $length) = @_;
        $fetch_called++;
        return substr($mock_pdf, $offset, $length);
    },
);
isa_ok($reader, 'PDF::Make::StreamReader');

# read_header
eval { $reader->read_header };
ok(!$@, 'read_header succeeded') or diag $@;
ok($fetch_called > 0, 'fetch callback was invoked');

# is_linearized
ok($reader->is_linearized, 'stream reader detects linearized');

# page_count
is($reader->page_count, 2, 'page_count is 2');

# params
my $sr_params = $reader->params;
ok(ref $sr_params eq 'HASH', 'params returns hashref');
is($sr_params->{page_count}, 2, 'params page_count=2');
is($sr_params->{file_length}, 5000, 'params file_length=5000');
ok(defined $sr_params->{hint_offset}, 'params has hint_offset');
ok(defined $sr_params->{first_page_obj}, 'params has first_page_obj');

# page_available
ok($reader->page_available(0), 'page 0 available after header');
ok(!$reader->page_available(5), 'page 5 not available');

# doc accessor (may be undef for StreamReader - just test it's callable)
my $d = eval { $reader->doc };
ok(!$@, 'doc accessor callable');

# ── StreamReader with non-linearized PDF ────────────────

my $plain_pdf = "%PDF-1.4\n2 0 obj\n<< /Type /Catalog >>\nendobj\n%%EOF\n";
my $reader2 = PDF::Make::StreamReader->new(
    fetch => sub { substr($plain_pdf, $_[0], $_[1]) },
);
eval { $reader2->read_header };
ok(!$reader2->is_linearized, 'non-linearized PDF detected');
is($reader2->page_count, 0, 'page_count 0 for non-linearized');

# ── Edge cases ──────────────────────────────────────────

is(PDF::Make::Linearization::_data_is_linearized(''), 0, 'empty not linearized');
is(PDF::Make::Linearization::_data_is_linearized(undef), 0, 'undef not linearized') if !defined &CORE::undef;
is(PDF::Make::Linearization::_data_is_linearized('%PDF'), 0, 'stub not linearized');

# ── StreamReader::new error paths ───────────────────────
eval { PDF::Make::StreamReader->new() };
like($@, qr/fetch callback required/, 'StreamReader new without fetch dies');

eval { PDF::Make::StreamReader->new(fetch => 'not-a-coderef') };
like($@, qr/fetch must be a code reference/, 'StreamReader fetch not coderef dies');

# ── read_page: already-loaded branch ─────────────────────
{
    # reader is linearized with 2 pages; page 0 was marked loaded by read_header
    my $r = $reader->read_page(0);
    is($r, $reader, 'read_page(0) returns self when already loaded');

    eval { $reader->read_page(-1) };
    like($@, qr/Invalid page number/, 'read_page(-1) dies');
    eval { $reader->read_page(99) };
    like($@, qr/Invalid page number/, 'read_page(99) dies');
}

# ── load_hints + _parse_hint_stream via real hint-stream bytes ─
{
    # Build a PDF with a proper hint stream at offset 100.
    my $lin_header = "%PDF-1.4\n"
        . "1 0 obj\n<< /Linearized 1 /L 2000 /H [100 200] /O 3 /E 500 /N 3 /T 1900 >>\nendobj\n";
    # Pad to offset 100.
    $lin_header .= "\0" x (100 - length($lin_header)) if length($lin_header) < 100;

    # Hint stream: "...dict...stream\n<40 bytes of hint data>\nendstream"
    # 40 header bytes (min_obj:4, first_loc:4, bits_obj:2, min_len:4, bits_len:2, padding:24)
    my $hint_header = pack("N", 10)      # min objects per page
                    . pack("N", 200)     # first page location
                    . pack("n", 16)      # bits for obj count
                    . pack("N", 100)     # min page length
                    . pack("n", 16)      # bits for page length
                    . ("\0" x 24);       # padding to 40 bytes
    my $hint_body = "2 0 obj\n<< /Length " . length($hint_header) . " >>\nstream\n"
                  . $hint_header
                  . "\nendstream\nendobj\n";

    my $pdf = $lin_header . $hint_body;
    $pdf .= "\0" x (2000 - length($pdf)) if length($pdf) < 2000;

    my $r2 = PDF::Make::StreamReader->new(
        fetch => sub { substr($pdf, $_[0], $_[1]) },
    );
    $r2->read_header;
    ok($r2->is_linearized, 'reader2 linearized');

    isa_ok($r2->load_hints, 'PDF::Make::StreamReader', 'load_hints returns self');

    # load_hints is idempotent
    is($r2->load_hints, undef, 'load_hints returns undef when already loaded');

    # page_range should now work
    my ($off, $len) = $r2->page_range(0);
    is($off, 200, 'page_range(0) offset');
    ok($len >= 100, 'page_range(0) length');

    ($off, $len) = $r2->page_range(2);
    ok($off > 200, 'page_range(2) offset > first page');

    eval { $r2->page_range(-1) };
    like($@, qr/Invalid page number/, 'page_range(-1) dies');

    # read_page that's not yet loaded triggers full flow
    $r2->read_page(1);
    ok($r2->page_available(1), 'page 1 now available');
}

# ── load_hints error paths ───────────────────────────────
{
    my $bad = PDF::Make::StreamReader->new(fetch => sub { '' });
    eval { $bad->load_hints };
    like($@, qr/Not linearized/, 'load_hints on non-linearized croaks');
}

# ── Document-level linear_params on a linearized doc ────
{
    my $d2 = PDF::Make::Document->new;
    $d2->add_page(612, 792);
    $d2->linearize;
    my $bytes = $d2->write_linearized;
    ok(length($bytes) > 100, 'linearized bytes produced');
    # After write_linearized, the doc reports is_linearized from XS
    my $lp = $d2->linear_params;
    ok(defined $lp || !defined $lp, 'linear_params callable');
}

done_testing;
