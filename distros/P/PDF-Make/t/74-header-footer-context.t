#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN {
    use_ok('PDF::Make::Builder');
    use_ok('PDF::Make::Builder::Page::HeaderFooterContext');
}

# ── Region accessors ──────────────────────────────────────
{
    my $ctx = PDF::Make::Builder::Page::HeaderFooterContext->new(
        builder => 'stub',
        page    => 'stub',
        canvas  => 'stub',
        x0      => 10, y0 => 20,
        w       => 100, h => 40,
        padding => 5,
        num     => 3,
        role    => 'header',
    );
    is($ctx->left,      10, 'left');
    is($ctx->right,    110, 'right');
    is($ctx->bottom,    20, 'bottom');
    is($ctx->top,       60, 'top');
    is($ctx->center_x,  60, 'center_x');
    is($ctx->center_y,  40, 'center_y');
    is($ctx->baseline(4), 24, 'baseline offset');
    is_deeply([$ctx->inset(5)], [15, 25, 90, 30], 'inset');
    is($ctx->num,        3, 'num accessor');
    is($ctx->role, 'header', 'role accessor');
}

# ── ctx passed to header/footer callbacks ────────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    my ($hdr_ctx, $ftr_ctx, $ftr_page_num);
    $b->add_page_header(
        h  => 40,
        cb => sub {
            my ($self, $builder, %args) = @_;
            $hdr_ctx = $args{ctx};
        },
    );
    $b->add_page_footer(
        h  => 30,
        cb => sub {
            my ($self, $builder, %args) = @_;
            $ftr_ctx      = $args{ctx};
            $ftr_page_num = $args{page_num};
        },
    );
    $b->add_page(page_size => 'Letter');
    $b->add_text(text => 'body');
    $b->save;

    ok($hdr_ctx, 'header callback received ctx');
    isa_ok($hdr_ctx, 'PDF::Make::Builder::Page::HeaderFooterContext');
    is($hdr_ctx->role, 'header', 'header ctx role');
    is($hdr_ctx->num, 1, 'header ctx num=1');
    ok($hdr_ctx->top > $hdr_ctx->bottom, 'header top > bottom');
    ok($hdr_ctx->w > 0, 'header w > 0');

    ok($ftr_ctx, 'footer callback received ctx');
    is($ftr_ctx->role, 'footer', 'footer ctx role');
    is($ftr_page_num, 1, 'footer legacy page_num preserved');

    unlink $f;
}

# ── Backward compat: callback using only canvas/y/w/h ────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    my $got;
    $b->add_page_header(
        h  => 30,
        cb => sub {
            my ($self, $builder, %args) = @_;
            $got = { map { $_ => $args{$_} } qw(canvas y w h) };
        },
    );
    $b->add_page;
    $b->save;
    ok($got->{canvas}, 'canvas still passed');
    ok(defined $got->{y}, 'y still passed');
    ok($got->{w} > 0,    'w still passed');
    ok($got->{h} > 0,    'h still passed');
    unlink $f;
}

# ── text() draws into the PDF ────────────────────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page_header(
        h  => 40,
        cb => sub {
            my ($self, $builder, %args) = @_;
            $args{ctx}->text(text => 'MYDOC', align => 'left');
        },
    );
    $b->add_page(page_size => 'Letter');
    $b->add_text(text => 'body');
    $b->save;
    open my $fh, '<:raw', $f or die $!;
    my $bytes = do { local $/; <$fh> };
    like($bytes, qr/MYDOC/, 'header text appears in PDF');
    unlink $f;
}

# ── page_num() substitutes {num} and {total} ─────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page_footer(
        h  => 30,
        cb => sub {
            my ($self, $builder, %args) = @_;
            $args{ctx}->page_num(format => 'Folio {num}/{total}', align => 'center');
        },
    );
    $b->add_page;
    $b->add_page;
    $b->save;
    open my $fh, '<:raw', $f or die $!;
    my $bytes = do { local $/; <$fh> };
    like($bytes, qr{Folio 1/2}, 'footer: Folio 1/2');
    like($bytes, qr{Folio 2/2}, 'footer: Folio 2/2');
    unlink $f;
}

# ── Region math ──────────────────────────────────────────
{
    my $pg = PDF::Make::Builder::Page::HeaderFooterContext->new(
        builder => 'b', page => 'p', canvas => 'c',
        x0 => 0, y0 => 100, w => 600, h => 40,
        padding => 20, num => 1, role => 'header',
    );
    is($pg->right, 600, 'full width right');
    is($pg->center_x, 300, 'center_x at 300');
    ok($pg->top > $pg->bottom, 'top above bottom');
}

# ── box() and line() don't die ───────────────────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page_header(
        h  => 40,
        cb => sub {
            my ($self, $builder, %args) = @_;
            my $c = $args{ctx};
            $c->box(x => $c->left, y => $c->bottom, w => $c->w, h => 2,
                    fill_colour => '#ccc');
            $c->line(x1 => $c->left, y1 => $c->bottom,
                     x2 => $c->right, y2 => $c->bottom, colour => '#000');
        },
    );
    $b->add_page;
    eval { $b->save };
    ok(!$@, "box+line ctx helpers don't die") or diag $@;
    unlink $f;
}

# ── note() attaches an annotation to the current page ────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page_footer(
        h  => 30,
        cb => sub {
            my ($self, $builder, %args) = @_;
            my $c = $args{ctx};
            $c->note(
                rect => [$c->left + 5, $c->bottom + 5, $c->left + 40, $c->top - 5],
                text => 'hello footer',
                icon => 'Comment',
            );
        },
    );
    $b->add_page;
    eval { $b->save };
    ok(!$@, "note ctx helper doesn't die") or diag $@;
    ok(-f $f, 'PDF created with note');
    unlink $f;
}

# ── link() attaches an external URI link ─────────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page_header(
        h  => 40,
        cb => sub {
            my ($self, $builder, %args) = @_;
            my $c = $args{ctx};
            $c->link(
                rect => [$c->right - 100, $c->bottom + 2,
                         $c->right,        $c->top - 2],
                url => 'https://example.com',
            );
        },
    );
    $b->add_page;
    eval { $b->save };
    ok(!$@, "link ctx helper doesn't die") or diag $@;
    open my $fh, '<:raw', $f or die $!;
    my $bytes = do { local $/; <$fh> };
    like($bytes, qr{example\.com}, 'link URL embedded in PDF');
    unlink $f;
}

# ── text() alignments (right/center) and override padding ─
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page_header(
        h  => 40,
        cb => sub {
            my ($self, $builder, %args) = @_;
            my $c = $args{ctx};
            $c->text(text => 'RIGHT',  align => 'right',  padding => 4);
            $c->text(text => 'CENTER', align => 'center');
            $c->text(text => '');                          # early-return branch
            $c->text(text => 'FONTOVERRIDE',
                     font => { size => 14, colour => '#f00',
                               family => 'Helvetica', bold => 1,
                               italic => 0, line_height => 16 });
        },
    );
    $b->add_page(page_size => 'Letter');
    eval { $b->save };
    ok(!$@, "text alignments+font override don't die") or diag $@;
    unlink $f;
}

# ── page_num() with {total}, text-fallback, font overrides ─
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page_footer(
        h  => 30,
        cb => sub {
            my ($self, $builder, %args) = @_;
            my $c = $args{ctx};
            # Use `text` key (falls through to format fallback chain)
            $c->page_num(text => '#{num}', align => 'left');
            $c->page_num(font => { family => 'Helvetica', bold => 1, italic => 0 });
        },
    );
    $b->add_page;
    eval { $b->save };
    ok(!$@, "page_num variants don't die") or diag $@;
    unlink $f;
}

# ── line(): from/to, dash, dashed, dots variants ──────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page_header(
        h  => 40,
        cb => sub {
            my ($self, $builder, %args) = @_;
            my $c = $args{ctx};
            $c->line(from => [$c->left, $c->bottom],
                     to   => [$c->right, $c->bottom]);
            $c->line(type => 'dashed', colour => '#888');
            $c->line(type => 'dots', width => 2);
            $c->line(dash => [3, 2], colour => '#000');
        },
    );
    $b->add_page;
    eval { $b->save };
    ok(!$@, "line variants don't die") or diag $@;
    unlink $f;
}

# ── box() with transparent (stroked outline) ──────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page_header(
        h  => 40,
        cb => sub {
            my ($self, $builder, %args) = @_;
            my $c = $args{ctx};
            $c->box(fill_colour => 'transparent', width => 2);
        },
    );
    $b->add_page;
    eval { $b->save };
    ok(!$@, "transparent box doesn't die") or diag $@;
    unlink $f;
}

# ── image() into header region ────────────────────────────
SKIP: {
    skip 'test image fixture missing', 4 unless -f 't/fixtures/images/test.png';

    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page_header(
        h  => 50,
        cb => sub {
            my ($self, $builder, %args) = @_;
            my $c = $args{ctx};
            $c->image(src => 't/fixtures/images/test.png', align => 'left');
            $c->image(src => 't/fixtures/images/test.png',
                      align => 'right', w => 20);
            $c->image(image => 't/fixtures/images/test.png',
                      align => 'center', h => 20);
            $c->image(src => 't/fixtures/images/test.png', x => 5, y => 5,
                      w => 10, h => 10);
        },
    );
    $b->add_page(page_size => 'Letter');
    eval { $b->save };
    ok(!$@, "image variants don't die") or diag $@;
    ok(-f $f, "image PDF written");
    unlink $f;

    # image error path: neither src nor image
    my $ctx = PDF::Make::Builder::Page::HeaderFooterContext->new(
        builder => 'b', page => 'p', canvas => 'c',
        x0 => 0, y0 => 0, w => 100, h => 40,
    );
    eval { $ctx->image() };
    like($@, qr/requires src or image/, 'image requires src');

    # image() on real page+builder, using x/y/w/h layout with default align
    my $f2 = tmpnam() . '.pdf';
    my $b2 = PDF::Make::Builder->new(file_name => $f2);
    $b2->add_page_header(
        h  => 50,
        cb => sub {
            my ($self, $builder, %args) = @_;
            my $c = $args{ctx};
            # Exercise w-only and h-only inference branches
            $c->image(src => 't/fixtures/images/test.png', w => 15);
        },
    );
    $b2->add_page;
    eval { $b2->save };
    ok(!$@, "image w-only branch doesn't die") or diag $@;
    unlink $f2;
}

# ── link() variants: page, action, file ───────────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page_footer(
        h  => 30,
        cb => sub {
            my ($self, $builder, %args) = @_;
            my $c = $args{ctx};
            $c->link(rect => [$c->left, $c->bottom, $c->left + 40, $c->top],
                     page => 0);
            $c->link(rect => [$c->left + 50, $c->bottom, $c->left + 90, $c->top],
                     action => 'NextPage');
            $c->link(rect => [$c->left + 100, $c->bottom, $c->left + 140, $c->top],
                     file => 'other.pdf');
        },
    );
    $b->add_page;
    $b->add_page;
    eval { $b->save };
    ok(!$@, "link variants don't die") or diag $@;
    unlink $f;

    # Error path: no destination args (needs real builder/page for _rect→doc access)
    my $f3 = tmpnam() . '.pdf';
    my $b3 = PDF::Make::Builder->new(file_name => $f3);
    my $caught;
    $b3->add_page_header(
        h  => 40,
        cb => sub {
            my ($self, $builder, %args) = @_;
            eval { $args{ctx}->link(rect => [0, 0, 10, 10]) };
            $caught = $@;
        },
    );
    $b3->add_page;
    eval { $b3->save };
    like($caught, qr/requires url, page, action, or file/, 'link requires destination');
    unlink $f3;
}

# ── _rect: x/y/w/h path and error ────────────────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page_header(
        h  => 40,
        cb => sub {
            my ($self, $builder, %args) = @_;
            my $c = $args{ctx};
            $c->note(x => $c->left, y => $c->bottom,
                     w => 30, h => 20, text => 'xywh-note');
        },
    );
    $b->add_page;
    eval { $b->save };
    ok(!$@, "note with x/y/w/h doesn't die") or diag $@;
    unlink $f;

    # Error path on _rect
    my $ctx = PDF::Make::Builder::Page::HeaderFooterContext->new(
        builder => 'b', page => 'p', canvas => 'c',
        x0 => 0, y0 => 0, w => 100, h => 40,
    );
    eval { $ctx->note(text => 'no-rect') };
    like($@, qr/requires rect or x\/y\/w\/h/, '_rect requires coords');
}

done_testing;
