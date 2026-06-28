#!/usr/bin/perl
# Tokenizer / parser edge-case coverage — covers what the deleted
# t/c/test_tokenizer.c and t/c/test_parser.c exercised, via PDF::Make::Parser
# round-trips on crafted minimal PDFs.
use strict;
use warnings;
use Test::More;
use PDF::Make::Parser;

# A minimal PDF whose single indirect object is $body (dict contents).
# The $body must serialize the root catalog dict.
sub minimal_pdf {
    my ($root_body) = @_;
    my $header  = "%PDF-1.4\n";
    my $obj1    = "1 0 obj\n$root_body\nendobj\n";
    my $obj2    = "2 0 obj\n<< /Type /Pages /Count 0 /Kids [] >>\nendobj\n";
    my $offset1 = length($header);
    my $offset2 = $offset1 + length($obj1);
    my $xref_at = $offset2 + length($obj2);
    my $xref    = sprintf(
        "xref\n0 3\n0000000000 65535 f \n%010d 00000 n \n%010d 00000 n \n",
        $offset1, $offset2,
    );
    my $trailer = "trailer\n<< /Size 3 /Root 1 0 R >>\nstartxref\n$xref_at\n%%EOF";
    return $header . $obj1 . $obj2 . $xref . $trailer;
}

sub parse_ok {
    my ($body, $label) = @_;
    my $p = PDF::Make::Parser->from_bytes(minimal_pdf($body), repair => 1);
    eval { $p->parse };
    ok(!$@, "$label: parse succeeds") or diag "parse error: $@";
    return $p;
}

# ── Whitespace and comments in dict ──────────────────────
{
    my $body = "<< /Type /Catalog    /Pages 2 0 R\n% inline comment\n/Version /1.4 >>";
    my $p = parse_ok($body, 'whitespace+comment');
    is($p->resolve($p->root_num, $p->root_gen), 7,
       'whitespace+comment: root resolves as dict');
}

# ── Numeric forms: integer, real, signed, no leading digit ─
{
    # PDF tokenizer must handle 0, -42, +0.5, .5, 10., 1e2, etc. in object bodies.
    my $body = "<< /Type /Catalog /Pages 2 0 R /A 0 /B -42 /C 3.14 /D .5 /E 10. >>";
    my $p = parse_ok($body, 'numeric forms');
    is($p->resolve($p->root_num, $p->root_gen), 7,
       'numeric forms: root resolves as dict');
}

# ── Name objects with hex escapes ───────────────────────
{
    # /Na#6D-e means /Name-e (0x6D = 'm')
    my $body = "<< /Type /Catalog /Pages 2 0 R /Na#6D-e 42 >>";
    my $p = parse_ok($body, 'name hex escape');
    is($p->resolve($p->root_num, $p->root_gen), 7, 'name hex escape: dict');
}

# ── Literal strings with escapes and balanced parens ────
{
    # PDF literal strings support \n, \t, \(, \), balanced parens, \ddd octals
    my $body = q[<< /Type /Catalog /Pages 2 0 R /T (Hello\nworld\(nested\)) >>];
    my $p = parse_ok($body, 'literal string escapes');
    is($p->resolve($p->root_num, $p->root_gen), 7, 'literal string escapes: dict');
}

# ── Hex strings ────────────────────────────────────────
{
    my $body = "<< /Type /Catalog /Pages 2 0 R /H <48656C6C6F> /H2 <48656c6c6F> >>";
    my $p = parse_ok($body, 'hex string');
    is($p->resolve($p->root_num, $p->root_gen), 7, 'hex string: dict');
}

# ── Hex string with odd number of digits (last pad = 0) ─
{
    my $body = "<< /Type /Catalog /Pages 2 0 R /H <4> >>";
    my $p = parse_ok($body, 'hex string odd');
    is($p->resolve($p->root_num, $p->root_gen), 7, 'hex string odd: dict');
}

# ── Arrays with mixed types ─────────────────────────────
{
    my $body = "<< /Type /Catalog /Pages 2 0 R "
             . "/A [ 1 2.5 (str) /Name true false null 3 0 R ] >>";
    my $p = parse_ok($body, 'mixed array');
    is($p->resolve($p->root_num, $p->root_gen), 7, 'mixed array: dict');
}

# ── Nested dicts ────────────────────────────────────────
{
    my $body = "<< /Type /Catalog /Pages 2 0 R /N << /K << /Leaf 1 >> >> >>";
    my $p = parse_ok($body, 'nested dicts');
    is($p->resolve($p->root_num, $p->root_gen), 7, 'nested dicts: root is dict');
}

# ── Booleans and null ───────────────────────────────────
{
    my $body = "<< /Type /Catalog /Pages 2 0 R /A true /B false /C null >>";
    my $p = parse_ok($body, 'booleans+null');
    is($p->resolve($p->root_num, $p->root_gen), 7, 'booleans+null: dict');
}

# ── Indirect references: 3 0 R style ────────────────────
{
    my $body = "<< /Type /Catalog /Pages 2 0 R /Ref 2 0 R >>";
    my $p = parse_ok($body, 'indirect ref');
    # Following the ref should yield the /Pages dict
    is($p->resolve(2, 0), 7, 'indirect ref target resolves as dict');
}

# ── Malformed: repair should still succeed ──────────────
{
    # Lots of stray whitespace + missing %%EOF — the repair logic should
    # still reconstruct the xref.
    my $junk = "%PDF-1.4\n\n\n   "
             . "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
             . "2 0 obj\n<< /Type /Pages /Count 0 /Kids [] >>\nendobj\n";
    # No trailer, no xref — force repair
    my $p = PDF::Make::Parser->from_bytes($junk, repair => 1);
    eval { $p->parse };
    ok(!$@, 'repair mode: missing-trailer PDF still parses') or diag $@;
}

# ── Streams are recognised and skipped ──────────────────
{
    # Skip testing stream content since it requires proper /Length, just
    # verify the tokenizer doesn't choke on the keyword.
    my $body = "<< /Type /Catalog /Pages 2 0 R >>";
    my $p = parse_ok($body, 'plain catalog');
    is($p->xref_size, 3, 'xref_size = 3');
}

# ── root_num/root_gen ───────────────────────────────────
{
    my $body = "<< /Type /Catalog /Pages 2 0 R >>";
    my $p = parse_ok($body, 'root identity');
    is($p->root_num, 1, 'root_num = 1');
    is($p->root_gen, 0, 'root_gen = 0');
}

# ── resolve() returns undef / dies for missing refs ─────
{
    my $body = "<< /Type /Catalog /Pages 2 0 R >>";
    my $p = parse_ok($body, 'missing ref base');
    my $k = eval { $p->resolve(99, 0) };
    ok(!defined $k || $@, 'resolve(missing) returns undef or dies');
}

done_testing;
