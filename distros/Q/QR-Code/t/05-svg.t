use strict;
use warnings;
use Test::More;
use QR::Code;

my $uri = 'otpauth://totp/Example:alice@example.com'
        . '?secret=ABCDEFGHIJKLMNOPQRSTUVWXYZ234567&issuer=Example';

sub err_of {
    my @args = @_;
    local $@;
    eval { QR::Code->svg(@args) };
    return $@;
}

# --- plain svg --------------------------------------------------------------
{
    my ($svg, $info) = QR::Code->svg('HELLO');
    my $span = $info->{size} + 8;                 # default quiet 4

    like $svg, qr/viewBox="0 0 $span $span"/, 'viewBox spans quiet zone';
    like $svg, qr/fill="#ffffff"/, 'default light, normalised';
    like $svg, qr/fill="#000000"/, 'default dark, normalised';
    unlike $svg, qr/<text|<image/, 'no logo means no logo elements';
    is $info->{ecc}, 'M', 'info carries the ecc letter';
    ok !exists $info->{logo}, 'no logo key without a logo';

    my $short = QR::Code->svg('HELLO', style => { dark => '#123' });
    like $short, qr/fill="#112233"/, '#rgb normalises to #rrggbb';
}

# --- colour validation ------------------------------------------------------
{
    like err_of('x', style => { dark => 'red' }),
        qr/not a hex colour/, 'named colours are refused';
    like err_of('x', style => { dark => '#888888', light => '#999999' }),
        qr/contrast too low/, 'a small luminance gap is refused';
    like err_of('x', style => { dark => '#ffffff', light => '#000000' }),
        qr/inverted colours/, 'light-on-dark is refused';
    like err_of('x', style => { dark => '#00000080' }),
        qr/translucent/, 'translucent dark is refused';

    my $t = QR::Code->svg('x', style => { light => 'none' });
    unlike $t, qr/<rect width/, "light => 'none' drops the ground rect";
}

# --- shapes and finders -----------------------------------------------------
{
    my $rounded = QR::Code->svg('HELLO', style => { shape => 'rounded' });
    like $rounded, qr/a0\.3 0\.3|a\d/, 'rounded modules emit arcs';

    my $dot = QR::Code->svg('HELLO', style => { shape => 'dot' });
    like $dot, qr/a0\.5 0\.5/, 'dot modules are circles';

    like err_of('x', style => { shape => 'dot', radius => 0.2 }),
        qr/below the floor/, 'dots below the blur floor are refused';
    like err_of('x', style => { shape => 'dot', radius => 0.6 }),
        qr/maximum is 0\.5/, 'dots overlapping neighbours are refused';
    like err_of('x', style => { shape => 'blob' }),
        qr/shape must be/, 'unknown shape name';

    my $circ = QR::Code->svg('HELLO', style => { finder => 'circle' });
    like $circ, qr/fill-rule="evenodd"/, 'finder ring uses evenodd';

    # finders stay solid whatever the module shape: the dot form must
    # not contain 33 tiny circles in the finder corner
    my ($dsvg) = QR::Code->svg('HELLO', style => { shape => 'dot' });
    my @rings = $dsvg =~ /fill-rule="evenodd"/g;
    is scalar @rings, 3, 'three solid finder rings';
}

# --- gradients --------------------------------------------------------------
{
    my $lin = QR::Code->svg('HELLO', style => {
        gradient => { stops => ['#000000', '#333333'] } });
    like $lin, qr/linearGradient id="qg"/, 'linear gradient emitted';
    like $lin, qr/url\(#qg\)/, 'modules reference it';

    my $rad = QR::Code->svg('HELLO', style => {
        gradient => { type => 'radial', stops => ['#000000', '#222222'] } });
    like $rad, qr/radialGradient/, 'radial gradient emitted';

    like err_of('x', style => { gradient =>
            { stops => ['#000000', '#eeeeee'] } }),
        qr/contrast too low: gradient stop 2/,
        'the worst stop gates the gradient';
    like err_of('x', style => { gradient => { stops => ['#000000'] } }),
        qr/at least two stops/, 'one stop is not a gradient';
}

# --- the logo ---------------------------------------------------------------
{
    my ($svg, $info) = QR::Code->svg($uri, logo => 'Punk');
    like $svg, qr/<text[^>]*>Punk<\/text>/, 'text logo present';
    like $svg, qr/text-anchor="middle"/, 'centred';
    like $svg, qr/ dy="/, 'positioned with dy, not dominant-baseline';
    is $info->{ecc}, 'H', 'a logo defaults the ecc to H';
    ok $info->{logo}{covered} > 0, 'info reports coverage';
    ok defined $info->{logo}{function_hits}, 'info reports function overlap';

    like err_of($uri, ecc => 'M', logo => 'Punk'),
        qr/needs ECC level Q or H/, 'an explicit low ecc with a logo refuses';

    my $esc = QR::Code->svg($uri, logo => 'A&B<C>');
    like $esc, qr/>A&amp;B&lt;C&gt;<\/text>/, 'text logo is XML-escaped';

    like err_of($uri, logo => 'this-is-far-too-long-for-any-symbol'),
        qr/exceeds the data region/, 'an oversized box refuses';

    like err_of($uri, logo => ''), qr/logo text is empty/, 'empty text';
    like err_of($uri, logo => {}),
        qr/exactly one of/, 'empty logo hash';
    like err_of($uri, logo => { text => 'a', svg => '<g/>' }),
        qr/exactly one of/, 'two logo kinds at once';
}

# --- image logos, sniffed from bytes ----------------------------------------
{
    # a structurally honest PNG header: signature, IHDR length, IHDR,
    # 32x16 pixels
    my $png = "\x89PNG\r\n\x1a\n"
            . pack('N', 13) . 'IHDR' . pack('NN', 32, 16)
            . "\x08\x02\x00\x00\x00";
    my ($svg, $info) = QR::Code->svg($uri, logo => { image => $png });
    like $svg, qr/data:image\/png;base64,/, 'PNG magic sniffed';

    # aspect 2:1 carries into the box: wider than tall
    ok $info->{logo}{width} > $info->{logo}{height},
        'image aspect ratio shapes the box';

    # a minimal JPEG: SOI, then an SOF0 segment declaring 16x32
    my $jpg = "\xFF\xD8"
            . "\xFF\xC0" . pack('n', 17) . "\x08" . pack('nn', 16, 32)
            . ("\x00" x 10);
    $svg = QR::Code->svg($uri, logo => { image => $jpg });
    like $svg, qr/data:image\/jpeg;base64,/, 'JPEG SOF sniffed';

    # SVG bytes become markup, not a raster data: URI
    my $art = qq{<?xml version="1.0"?>\n}
            . qq{<svg xmlns="x" viewBox="0 0 50 25"><rect/></svg>};
    $svg = QR::Code->svg($uri, logo => { image => $art });
    like $svg, qr/<svg x="[^"]+"[^>]*viewBox="0 0 50 25">/,
        'SVG bytes are lifted into a nested svg with their viewBox';
    unlike $svg, qr/data:image\/svg/, 'and not base64d';

    like err_of($uri, logo => { image => 'GIF89a junk here' }),
        qr/neither PNG, JPEG nor SVG/, 'unknown bytes refuse';
    like err_of($uri, logo => { image => "\x89PNG\r\n\x1a\n truncated" }),
        qr/truncated or malformed/, 'a PNG with no IHDR refuses';

    # a bare fragment is wrapped in a scaled group
    $svg = QR::Code->svg($uri, logo => { svg => '<circle r="40"/>' });
    like $svg, qr/<g transform="translate\([^)]+\) scale\([^)]+\)">/,
        'rootless fragment gets a scaled group';
    like $svg, qr/<circle r="40"\/>/, 'and is inlined verbatim';

    like err_of($uri, logo => { file => '/nonexistent/x.png' }),
        qr{/nonexistent/x\.png}, 'missing logo file names the path';
}

# --- option validation ------------------------------------------------------
{
    like err_of('x', wibble => 1), qr/unknown svg option/, 'unknown option';
    like err_of('x', ecc => 'X'), qr/ecc must be/, 'bad ecc';
    like err_of('x', style => { wobble => 1 }),
        qr/unknown style option/, 'unknown style key';
    like err_of('x', logo => { wums => 1 }),
        qr/unknown logo option/, 'unknown logo key';
}

# --- pbm agrees with matrix -------------------------------------------------
{
    my $m    = QR::Code->matrix('HELLO');
    my $size = @$m;
    my $pbm  = QR::Code->pbm('HELLO', quiet => 0);
    my ($w, $h, $rest) = $pbm =~ /\AP1\n(\d+) (\d+)\n(.*)\z/s;

    is $w, $size, 'pbm width';
    is $h, $size, 'pbm height';
    my @cells = split ' ', $rest;
    my $diff = 0;
    for my $r (0 .. $size - 1) {
        for my $c (0 .. $size - 1) {
            $diff++ if $cells[$r * $size + $c] != $m->[$r][$c];
        }
    }
    is $diff, 0, 'every pbm cell matches the matrix';
}

done_testing;
