#!/usr/bin/env perl
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch', 'lib';
use PDF::Make::Document;
use PDF::Make::Canvas;
use PDF::Make::Page qw(:fonts);
use PDF::Make::Layer;

my $doc = PDF::Make::Document->new;
$doc->title('Layer Demo');

my $page = $doc->add_page(612, 792);
$page->add_std14_font('F1', HELVETICA);
$page->add_std14_font('F1B', HELVETICA_BOLD);

# ── Create layers ─────────────────────────────────────────

my $bg     = PDF::Make::Layer->create($doc, 'Background');
my $dims   = PDF::Make::Layer->create($doc, 'Dimensions');
my $notes  = PDF::Make::Layer->create($doc, 'Annotations');
my $wmark  = PDF::Make::Layer->create($doc, 'Watermark');

# Annotations hidden by default
$notes->visible(0);

# Watermark: print-only (visible when printing, hidden on screen)
$wmark->set_print_state(0);   # STATE_ON
$wmark->set_view_state(1);    # STATE_OFF

# Write OCG objects and register on page
for my $layer ($bg, $dims, $notes, $wmark) {
    my $num = $layer->write_to_doc($doc);
    $page->add_ocg($layer->res_name, $num);
}

# ── Draw content ──────────────────────────────────────────

my $c = PDF::Make::Canvas->new;

# Title (not on any layer — always visible)
$c->BT
  ->Tf('F1B', 28)->Tm(1, 0, 0, 1, 72, 720)
  ->Tj('PDF Layer Demo')
  ->Tf('F1', 11)->Tm(1, 0, 0, 1, 72, 700)
  ->rg(0.5, 0.5, 0.5)
  ->Tj('Open in Acrobat to see the layers panel')
  ->ET;

# ── Background layer: colored rectangles ──────────────────
$c->begin_layer($bg->res_name);
$c->q->rg(0.93, 0.95, 0.98)->re(50, 200, 512, 450)->f->Q;  # light blue bg
$c->q->rg(1, 1, 1)->re(60, 210, 492, 430)->f->Q;             # white inner
$c->end_layer;

# ── Dimensions layer: measurement lines ───────────────────
$c->begin_layer($dims->res_name);

# Horizontal dimension line
$c->q->w(1)->RG(0, 0, 0.8)
  ->m(100, 500)->l(400, 500)->S               # main line
  ->m(100, 510)->l(100, 490)->S               # left tick
  ->m(400, 510)->l(400, 490)->S               # right tick
  ->Q;
$c->BT->Tf('F1', 9)->rg(0, 0, 0.8)
  ->Tm(1, 0, 0, 1, 230, 505)->Tj('300 pt')
  ->ET;

# Vertical dimension line
$c->q->w(1)->RG(0, 0, 0.8)
  ->m(450, 300)->l(450, 600)->S
  ->m(440, 300)->l(460, 300)->S
  ->m(440, 600)->l(460, 600)->S
  ->Q;
$c->BT->Tf('F1', 9)->rg(0, 0, 0.8)
  ->Tm(0, 1, -1, 0, 465, 430)->Tj('300 pt')
  ->ET;

$c->end_layer;

# ── Annotations layer: callout notes ──────────────────────
$c->begin_layer($notes->res_name);

# Note box
$c->q->rg(1, 0.95, 0.85)->RG(0.9, 0.3, 0.1)->w(1)
  ->re(100, 350, 250, 60)->B->Q;
$c->BT->Tf('F1B', 10)->rg(0.9, 0.3, 0.1)
  ->Tm(1, 0, 0, 1, 110, 390)->Tj('NOTE')
  ->Tf('F1', 9)->rg(0.3, 0.3, 0.3)
  ->Tm(1, 0, 0, 1, 110, 370)->Tj('This annotation is hidden by default.')
  ->Tm(1, 0, 0, 1, 110, 358)->Tj('Toggle the Annotations layer to show it.')
  ->ET;

# Arrow pointing to dimension
$c->q->w(1.5)->RG(0.9, 0.3, 0.1)
  ->m(250, 410)->l(250, 490)->S
  ->m(245, 480)->l(250, 490)->l(255, 480)->S
  ->Q;

$c->end_layer;

# ── Watermark layer: diagonal DRAFT ───────────────────────
$c->begin_layer($wmark->res_name);

$c->q
  ->rg(0.9, 0.9, 0.9)
  ->BT
  ->Tf('F1B', 72)
  ->Tm(0.7, 0.7, -0.7, 0.7, 120, 300)
  ->Tr(1)   # stroke mode for outline text
  ->RG(0.85, 0.85, 0.85)
  ->w(2)
  ->Tj('DRAFT')
  ->ET
  ->Q;

$c->end_layer;

# ── Assemble ──────────────────────────────────────────────
$page->set_content($c->to_bytes);

my $out = 'corpus/layered.pdf';
$doc->to_file($out);
print "Wrote $out\n";
print "Layers: Background (visible), Dimensions (visible), Annotations (hidden), Watermark (print-only)\n";
print "Open in Adobe Acrobat to toggle layers.\n";
