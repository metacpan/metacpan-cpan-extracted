use strict;
use warnings;
use Test::More tests => 36;

use PDF::Make;

#----------------------------------------------------------------------------
# Canvas lifecycle
#----------------------------------------------------------------------------

my $canvas = PDF::Make::Canvas->new();
ok(defined $canvas, 'Canvas::new returns object');
isa_ok($canvas, 'PDF::Make::Canvas', 'Canvas is correct class');

is($canvas->len, 0, 'New canvas has length 0');

#----------------------------------------------------------------------------
# Graphics state operators
#----------------------------------------------------------------------------

$canvas = PDF::Make::Canvas->new();
$canvas->q;
like($canvas->to_bytes, qr/^q\n$/, 'q operator');

$canvas = PDF::Make::Canvas->new();
$canvas->Q;
like($canvas->to_bytes, qr/^Q\n$/, 'Q operator');

$canvas = PDF::Make::Canvas->new();
$canvas->w(2.5);
like($canvas->to_bytes, qr/^2\.5 w\n$/, 'w (line width) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->J(1);
like($canvas->to_bytes, qr/^1 J\n$/, 'J (line cap) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->j(2);
like($canvas->to_bytes, qr/^2 j\n$/, 'j (line join) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->M(10);
like($canvas->to_bytes, qr/^10 M\n$/, 'M (miter limit) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->cm(1, 0, 0, 1, 100, 200);
like($canvas->to_bytes, qr/^1 0 0 1 100 200 cm\n$/, 'cm (transform) operator');

#----------------------------------------------------------------------------
# Path construction operators
#----------------------------------------------------------------------------

$canvas = PDF::Make::Canvas->new();
$canvas->m(72, 720);
like($canvas->to_bytes, qr/^72 720 m\n$/, 'm (moveto) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->l(144, 720);
like($canvas->to_bytes, qr/^144 720 l\n$/, 'l (lineto) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->c(10, 20, 30, 40, 50, 60);
like($canvas->to_bytes, qr/^10 20 30 40 50 60 c\n$/, 'c (curveto) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->re(50, 700, 100, 50);
like($canvas->to_bytes, qr/^50 700 100 50 re\n$/, 're (rectangle) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->h;
like($canvas->to_bytes, qr/^h\n$/, 'h (closepath) operator');

#----------------------------------------------------------------------------
# Path painting operators
#----------------------------------------------------------------------------

$canvas = PDF::Make::Canvas->new();
$canvas->S;
like($canvas->to_bytes, qr/^S\n$/, 'S (stroke) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->s;
like($canvas->to_bytes, qr/^s\n$/, 's (close and stroke) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->f;
like($canvas->to_bytes, qr/^f\n$/, 'f (fill) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->B;
like($canvas->to_bytes, qr/^B\n$/, 'B (fill and stroke) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->n;
like($canvas->to_bytes, qr/^n\n$/, 'n (endpath) operator');

#----------------------------------------------------------------------------
# Color operators
#----------------------------------------------------------------------------

$canvas = PDF::Make::Canvas->new();
$canvas->g(0.5);
like($canvas->to_bytes, qr/^0\.5 g\n$/, 'g (gray fill) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->G(0.8);
like($canvas->to_bytes, qr/^0\.8 G\n$/, 'G (gray stroke) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->rg(1, 0, 0);
like($canvas->to_bytes, qr/^1 0 0 rg\n$/, 'rg (RGB fill) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->RG(0, 0, 1);
like($canvas->to_bytes, qr/^0 0 1 RG\n$/, 'RG (RGB stroke) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->k(0, 1, 1, 0);
like($canvas->to_bytes, qr/^0 1 1 0 k\n$/, 'k (CMYK fill) operator');

#----------------------------------------------------------------------------
# Text operators
#----------------------------------------------------------------------------

$canvas = PDF::Make::Canvas->new();
$canvas->BT;
like($canvas->to_bytes, qr/^BT\n$/, 'BT (begin text) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->ET;
like($canvas->to_bytes, qr/^ET\n$/, 'ET (end text) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->Tf('F1', 12);
like($canvas->to_bytes, qr{^/F1 12 Tf\n$}, 'Tf (font) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->Td(72, 700);
like($canvas->to_bytes, qr/^72 700 Td\n$/, 'Td (text position) operator');

$canvas = PDF::Make::Canvas->new();
$canvas->Tj('Hello World');
like($canvas->to_bytes, qr/^\(Hello World\) Tj\n$/, 'Tj (show text) operator');

#----------------------------------------------------------------------------
# Chained operations
#----------------------------------------------------------------------------

$canvas = PDF::Make::Canvas->new();
my $result = $canvas->BT->Tf('F1', 24)->Td(72, 700)->Tj('Hello')->ET;
is($result, $canvas, 'Methods return self for chaining');

my $content = $canvas->to_bytes;
like($content, qr/BT/, 'Chained content has BT');
like($content, qr/Tj/, 'Chained content has Tj');
like($content, qr/ET/, 'Chained content has ET');

#----------------------------------------------------------------------------
# Clear operation
#----------------------------------------------------------------------------

$canvas = PDF::Make::Canvas->new();
$canvas->BT->Tf('F1', 12)->Td(72, 700)->Tj('Test')->ET;
ok($canvas->len > 0, 'Canvas has content after operations');
$canvas->clear;
is($canvas->len, 0, 'Canvas length is 0 after clear');
