#!/usr/bin/perl
# Coverage for the Canvas operators that t/07-canvas.t doesn't assert on.
# Together with t/07 this exercises every PDF content-stream operator that
# PDF::Make::Canvas exposes (previously only covered by t/c/test_content.c).
use strict;
use warnings;
use Test::More;
use PDF::Make::Canvas;

sub bytes_of (&) {
    my $code = shift;
    my $c = PDF::Make::Canvas->new;
    $code->($c);
    return $c->to_bytes;
}

# ── Path construction variants ──────────────────────────
like(bytes_of { $_[0]->v(10, 20, 30, 40) },
    qr/^10 20 30 40 v\n$/, 'v (curveto, initial point from current)');
like(bytes_of { $_[0]->y(10, 20, 30, 40) },
    qr/^10 20 30 40 y\n$/, 'y (curveto, final point is end)');

# ── Path painting: alternative ops ──────────────────────
like(bytes_of { $_[0]->f_star }, qr/^f\*\n$/, 'f* (even-odd fill)');
like(bytes_of { $_[0]->b },      qr/^b\n$/,   'b (close + fill + stroke)');
like(bytes_of { $_[0]->b_star }, qr/^b\*\n$/, 'b* (close + even-odd fill + stroke)');
like(bytes_of { $_[0]->B },      qr/^B\n$/,   'B (fill + stroke)');
like(bytes_of { $_[0]->B_star }, qr/^B\*\n$/, 'B* (even-odd fill + stroke)');
like(bytes_of { $_[0]->s },      qr/^s\n$/,   's (close + stroke)');
like(bytes_of { $_[0]->n },      qr/^n\n$/,   'n (end path without painting)');

# ── Clipping operators ──────────────────────────────────
like(bytes_of { $_[0]->W },      qr/^W\n$/,   'W (clip by nonzero winding)');
like(bytes_of { $_[0]->W_star }, qr/^W\*\n$/, 'W* (clip by even-odd)');

# ── Graphics state: dash, flatness, rendering intent ────
like(bytes_of { $_[0]->d([3, 2], 0) }, qr/^\[ ?3 2 ?\] 0 d\n$/,
    'd (dash pattern)');
like(bytes_of { $_[0]->i(0.5) }, qr/^0\.5 i\n$/, 'i (flatness)');
like(bytes_of { $_[0]->ri('RelativeColorimetric') },
    qr/RelativeColorimetric.*ri/, 'ri (rendering intent)');
like(bytes_of { $_[0]->gs('GS1') }, qr{/GS1 gs\n$}, 'gs (ext-gstate)');

# ── Colour space operators ──────────────────────────────
like(bytes_of { $_[0]->cs('DeviceRGB') }, qr{/DeviceRGB cs\n$},
    'cs (nonstroking colour space)');
like(bytes_of { $_[0]->CS('DeviceCMYK') }, qr{/DeviceCMYK CS\n$},
    'CS (stroking colour space)');
like(bytes_of { $_[0]->G(0.25) }, qr/^0\.25 G\n$/, 'G (stroking gray)');
like(bytes_of { $_[0]->K(0.1, 0.2, 0.3, 0.4) },
    qr/^0\.1 0\.2 0\.3 0\.4 K\n$/, 'K (stroking CMYK)');

# ── XObject / shading invocation ────────────────────────
like(bytes_of { $_[0]->Do('Im1') }, qr{/Im1 Do\n$}, 'Do (XObject)');
like(bytes_of { $_[0]->sh('Sh1') }, qr{/Sh1 sh\n$}, 'sh (shading)');

# ── Marked content & compatibility ──────────────────────
like(bytes_of { $_[0]->BMC('Artifact') }, qr{/Artifact BMC\n$},
    'BMC (begin marked content)');
like(bytes_of { $_[0]->EMC },             qr/^EMC\n$/, 'EMC (end marked content)');
like(bytes_of { $_[0]->BX },              qr/^BX\n$/,  'BX (begin compatibility)');
like(bytes_of { $_[0]->EX },              qr/^EX\n$/,  'EX (end compatibility)');

# ── Text state operators ────────────────────────────────
like(bytes_of { $_[0]->BT; $_[0]->Tc(0.5); $_[0]->ET },
    qr/0\.5 Tc/, 'Tc (character spacing)');
like(bytes_of { $_[0]->BT; $_[0]->Tw(1.25); $_[0]->ET },
    qr/1\.25\S* Tw/, 'Tw (word spacing)');
like(bytes_of { $_[0]->BT; $_[0]->Tz(120); $_[0]->ET },
    qr/120 Tz/, 'Tz (horizontal scaling)');
like(bytes_of { $_[0]->BT; $_[0]->TL(14); $_[0]->ET },
    qr/14 TL/, 'TL (leading)');
like(bytes_of { $_[0]->BT; $_[0]->Tr(1); $_[0]->ET },
    qr/1 Tr/, 'Tr (rendering mode)');
like(bytes_of { $_[0]->BT; $_[0]->Ts(2); $_[0]->ET },
    qr/2 Ts/, 'Ts (text rise)');

# ── Text positioning / showing ──────────────────────────
like(bytes_of { $_[0]->BT; $_[0]->TD(10, 20); $_[0]->ET },
    qr/10 20 TD/, 'TD (move + set leading)');
like(bytes_of { $_[0]->BT; $_[0]->T_star; $_[0]->ET },
    qr/T\*/, 'T* (next line using leading)');
like(bytes_of { $_[0]->BT; $_[0]->apostrophe('hi'); $_[0]->ET },
    qr/\(hi\)\s'/, "' (move to next line, show text)");
like(bytes_of { $_[0]->BT; $_[0]->double_quote(1, 2, 'hi'); $_[0]->ET },
    qr/1 2 \(hi\)\s"/, '" (set spacing, move, show)');
like(bytes_of { $_[0]->BT; $_[0]->TJ(['he', -30, 'llo']); $_[0]->ET },
    qr/TJ/, 'TJ (show text with positioning)');

# ── Image-helper wrapper ────────────────────────────────
like(bytes_of { $_[0]->image('Im1', 10, 20, 30, 40) },
    qr{30 0 0 40 10 20 cm\n/Im1 Do},
    'image() emits cm + Do sequence');

# ── Layer helpers ───────────────────────────────────────
like(bytes_of { $_[0]->begin_layer('OC1') },
    qr{/OC /OC1 BDC}, 'begin_layer (optional content BDC)');
like(bytes_of { $_[0]->end_layer },
    qr/EMC/, 'end_layer (EMC)');

# ── Chaining returns self ───────────────────────────────
my $c = PDF::Make::Canvas->new;
isa_ok($c->q->w(1)->m(0,0)->l(10,0)->S->Q,
       'PDF::Make::Canvas', 'chained ops return self');

# ── Constants are exported sensibly ─────────────────────
is(PDF::Make::Canvas::CAP_BUTT(),  0, 'CAP_BUTT = 0');
is(PDF::Make::Canvas::CAP_ROUND(), 1, 'CAP_ROUND = 1');
is(PDF::Make::Canvas::CAP_SQUARE(),2, 'CAP_SQUARE = 2');
is(PDF::Make::Canvas::JOIN_MITER(),0, 'JOIN_MITER = 0');
is(PDF::Make::Canvas::JOIN_ROUND(),1, 'JOIN_ROUND = 1');
is(PDF::Make::Canvas::JOIN_BEVEL(),2, 'JOIN_BEVEL = 2');

done_testing;
