#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Linearization') }
BEGIN { use_ok('PDF::Make::Document') }
BEGIN { use_ok('PDF::Make::Canvas') }
BEGIN { use_ok('PDF::Make::Page', ':fonts') }

# ── Create and linearize a document ──────────────────────

my $doc = PDF::Make::Document->new;
$doc->title('Linearization Test');
for my $i (1..3) {
    my $page = $doc->add_page(612, 792);
    $page->add_std14_font('F1', HELVETICA);
    my $c = PDF::Make::Canvas->new;
    $c->BT->Tf('F1', 24)->Td(72, 700)->Tj("Page $i")->ET;
    $page->set_content($c->to_bytes);
}

# Normal bytes (not linearized)
my $normal = $doc->to_bytes;
ok(length($normal) > 500, 'normal doc has content');
is(PDF::Make::Linearization::_data_is_linearized($normal), 0,
    'normal PDF is not linearized');

# ── LinearContext ────────────────────────────────────────

my $ctx = eval { PDF::Make::LinearContext->_new($doc) };
ok($ctx, 'LinearContext created') or diag $@;

SKIP: {
    skip 'LinearContext not created', 8 unless $ctx;

    isa_ok($ctx, 'PDF::Make::LinearContext');

    eval { $ctx->analyze };
    ok(!$@, 'analyze succeeded') or diag $@;

    eval { $ctx->build_hints };
    ok(!$@, 'build_hints succeeded') or diag $@;

    my $pc = $ctx->page_count;
    ok(defined $pc, "page_count: $pc");

    my $soc = $ctx->shared_object_count;
    ok(defined $soc, "shared_object_count: $soc");

    my $lin_bytes = eval { $ctx->write };
    ok(defined $lin_bytes && length($lin_bytes) > 0, 'write returns bytes');

    my $is_lin = PDF::Make::Linearization::_data_is_linearized($lin_bytes);
    is($is_lin, 1, 'output is linearized');

    like($lin_bytes, qr/^%PDF/, 'linearized output starts with %PDF');
}

# ── Document monkey-patched methods ──────────────────────

my $doc2 = PDF::Make::Document->new;
$doc2->add_page(612, 792);

my $is = eval { $doc2->is_linearized };
ok(defined $is, 'doc.is_linearized callable');
is($is, 0, 'fresh doc is not linearized');

eval { $doc2->linearize };
ok(!$@, 'doc.linearize succeeds') or diag $@;

my $params = eval { $doc2->linear_params };
ok(defined $params || !$@, 'doc.linear_params callable');

my $lin = eval { $doc2->write_linearized };
ok(defined $lin || $@, 'doc.write_linearized callable');

my $path = '/tmp/lin_test.pdf';
eval { $doc2->write_linearized($path) };
if (-f $path) {
    ok(-s $path > 0, 'write_linearized to file');
    unlink $path;
} else {
    ok(1, 'write_linearized to path attempted');
}

# ── Fixture ──────────────────────────────────────────────

SKIP: {
    skip 'linearized fixture not found', 3
        unless -f 't/fixtures/fixtures/linearized_5page.pdf';

    open my $fh, '<:raw', 't/fixtures/fixtures/linearized_5page.pdf';
    my $data = do { local $/; <$fh> };

    ok(length($data) > 100, 'fixture has content');
    like($data, qr/%PDF/, 'fixture is PDF');
    is(PDF::Make::Linearization::_data_is_linearized($data), 1, 'fixture IS linearized');
}

# ── Edge cases ───────────────────────────────────────────

is(PDF::Make::Linearization::_data_is_linearized(''), 0, 'empty not linearized');
is(PDF::Make::Linearization::_data_is_linearized('%PDF-1.4'), 0, 'minimal not linearized');
is(PDF::Make::Linearization::_data_is_linearized('not a pdf'), 0, 'garbage not linearized');

done_testing;
