use strict;
use warnings;
use Test::More;
use File::Temp ();
use MIME::Base64 ();
use QR::Code;

# The centre logo: text, SVG markup, raster images, and the rules.

my $uri = 'otpauth://totp/Example:alice@example.com'
        . '?secret=JBSWY3DPEHPK3PXP&issuer=Example&period=30';

# --- fixture builders: only the headers have to be honest ------------------

sub png_bytes {
    my ($w, $h) = @_;
    return "\x89PNG\r\n\x1a\n"
         . pack('N', 13) . 'IHDR' . pack('NN', $w, $h)
         . "\x08\x06\x00\x00\x00" . "\x00" x 4
         . pack('N', 0) . 'IEND' . "\x00" x 4;
}

sub jpeg_bytes {
    my ($w, $h, %o) = @_;
    my $j = "\xFF\xD8";
    $j .= "\xFF\xE1" . pack('n', 2 + $o{app1}) . ("\x00" x $o{app1})
        if $o{app1};
    my $sof = $o{progressive} ? "\xC2" : "\xC0";
    $j .= "\xFF" . $sof . pack('n', 11) . "\x08"
        . pack('nn', $h, $w) . "\x01\x01\x11\x00";
    return $j . "\xFF\xD9";
}

# --- sniffing --------------------------------------------------------------

{
    my @r = QR::Code::_sniff(png_bytes(1, 1));
    is_deeply(\@r, ['png', 1, 1], '1x1 PNG sniffs');

    @r = QR::Code::_sniff(png_bytes(30, 10));
    is_deeply(\@r, ['png', 30, 10], 'non-square PNG dimensions');

    @r = QR::Code::_sniff(jpeg_bytes(64, 48));
    is_deeply(\@r, ['jpeg', 64, 48], 'baseline JPEG (SOF0)');

    @r = QR::Code::_sniff(jpeg_bytes(64, 48, progressive => 1));
    is_deeply(\@r, ['jpeg', 64, 48], 'progressive JPEG (SOF2)');

    @r = QR::Code::_sniff(jpeg_bytes(20, 40, app1 => 300));
    is_deeply(\@r, ['jpeg', 20, 40], 'SOF behind a fat APP1 segment');

    @r = QR::Code::_sniff('  <svg viewBox="0 0 10 10"/>');
    is($r[0], 'svg', 'markup sniffs as SVG');

    @r = QR::Code::_sniff("\xEF\xBB\xBF<?xml version=\"1.0\"?><svg/>");
    is($r[0], 'svg', 'BOM and XML declaration still sniff as SVG');

    eval { QR::Code::_sniff('BM' . 'x' x 20) };
    like($@, qr/neither PNG, JPEG nor SVG \(starts 42 4d 78 78\)/,
         'a BMP croaks naming the bytes it saw');

    eval { QR::Code::_sniff(substr(png_bytes(5, 5), 0, 12)) };
    like($@, qr/PNG bytes are truncated or malformed/,
         'a truncated PNG croaks');

    eval { QR::Code::_sniff("\xFF\xD8\xFF\xE0\x00\x04\x00\x00") };
    like($@, qr/JPEG bytes are truncated or malformed/,
         'a JPEG with no SOF croaks');
}

# --- the ECC rule ----------------------------------------------------------

{
    my (undef, $info) = QR::Code->svg($uri, logo => 'Punk');
    is($info->{ecc}, 'H', 'a logo defaults the level to H');

    (undef, $info) = QR::Code->svg($uri, logo => 'Punk', ecc => 'Q');
    is($info->{ecc}, 'Q', 'explicit Q is allowed');

    for my $ecc (qw(L M)) {
        eval { QR::Code->svg($uri, logo => 'Punk', ecc => $ecc) };
        like($@, qr/a centre logo needs ECC level Q or H, not $ecc/,
             "explicit $ecc croaks");
    }
}

# --- text ------------------------------------------------------------------

{
    my ($svg, $info) = QR::Code->svg($uri, logo => 'Punk');
    like($svg, qr/<text[^>]*text-anchor="middle"/, 'text logo present');
    like($svg, qr/font-weight="700"/, 'bold');
    like($svg, qr/<rect x="[\d.]+" y="[\d.]+" width="[\d.]+" height="[\d.]+" rx="[\d.]+" fill="#ffffff"\/>/,
         'knockout rect behind it');

    my $lg = $info->{logo};
    ok($lg->{covered} > 0, "box covers $lg->{covered} modules");
    ok($lg->{width} > $lg->{height}, 'a word gets a short wide box');
    cmp_ok($lg->{x}, '>=', 8, 'box starts inside the data region');
    cmp_ok($lg->{x} + $lg->{width}, '<=', $info->{size} - 8,
           'box ends inside it');

    my ($esc) = QR::Code->svg($uri, logo => 'A&B<C>');
    like($esc, qr/A&amp;B&lt;C&gt;/, 'text is XML-escaped');
}

# --- the clamp -------------------------------------------------------------

{
    eval { QR::Code->svg('x', logo => 'Punk') };
    like($@, qr/exceeds the data region of the version 1 symbol/,
         'a logo too big for a tiny symbol croaks');

    my ($svg, $info) = QR::Code->svg('x', logo => 'Punk', version => 10);
    is($info->{version}, 10, 'raising the version rescues it');

    eval { QR::Code->svg($uri, logo => 'openapi-proxy-enterprise') };
    like($@, qr/exceeds the data region/, 'a very long word croaks');
}

# --- raster ----------------------------------------------------------------

{
    my $png = png_bytes(30, 10);
    my ($svg, $info) = QR::Code->svg($uri, logo => { image => $png });

    like($svg, qr/href="data:image\/png;base64,/, 'PNG MIME type');
    like($svg, qr/preserveAspectRatio="xMidYMid meet"/, 'aspect preserved');

    my ($w, $h) = $svg =~ /<image[^>]*width="([\d.]+)" height="([\d.]+)"/;
    ok(abs($w / $h - 3) < 0.01, "image box keeps the 3:1 aspect ($w x $h)");
    ok($info->{logo}{width} > $info->{logo}{height},
       'a wide image gets the short wide box');

    my ($b64) = $svg =~ /base64,([A-Za-z0-9+\/=]+)"/;
    is(MIME::Base64::decode_base64($b64), $png,
       'the data URI decodes back to the input bytes');

    my $jpg = jpeg_bytes(48, 48);
    my ($jsvg) = QR::Code->svg($uri, logo => { image => $jpg });
    like($jsvg, qr/href="data:image\/jpeg;base64,/, 'JPEG MIME type');

    eval { QR::Code->svg($uri, logo => { image => 'BM' . 'x' x 20 }) };
    like($@, qr/neither PNG, JPEG nor SVG/, 'garbage image bytes croak');
}

# --- files, sniffed never trusted ------------------------------------------

{
    my ($fh, $path) = File::Temp::tempfile(SUFFIX => '.png', UNLINK => 1);
    binmode $fh;
    print $fh jpeg_bytes(10, 10);    # a JPEG wearing a .png name
    close $fh;

    my ($svg) = QR::Code->svg($uri, logo => { file => $path });
    like($svg, qr/data:image\/jpeg;base64,/,
         'a mislabelled file is embedded as what it is');

    eval { QR::Code->svg($uri, logo => { file => "$path.missing" }) };
    like($@, qr/logo file '.*\.missing'/, 'a missing file croaks');
}

# --- svg markup ------------------------------------------------------------

{
    my $art = '<svg viewBox="0 0 50 100"><path d="M0 0h50v100H0z"/></svg>';
    my ($svg) = QR::Code->svg($uri, logo => { svg => $art });
    like($svg, qr/<svg x="[\d.]+" y="[\d.]+" width="[\d.]+" height="[\d.]+" preserveAspectRatio="xMidYMid meet" viewBox="0 0 50 100">/,
         'markup nests with its viewBox kept');
    like($svg, qr/<path d="M0 0h50v100H0z"\/><\/svg>/,
         'the artwork rides inside');

    my ($tw, $th) = $svg =~ /<svg x="[\d.]+" y="[\d.]+" width="([\d.]+)" height="([\d.]+)"/;
    ok(abs($th / $tw - 2) < 0.01, 'tall art keeps its 1:2 aspect');

    my ($frag) = QR::Code->svg($uri, logo => { svg => '<circle r="40"/>' });
    like($frag, qr/<g transform="translate\([\d. ]+\) scale\([\d.]+\)"><circle r="40"\/><\/g>/,
         'a rootless fragment is wrapped and scaled');

    # image bytes that are really SVG route to the markup path
    my ($routed) = QR::Code->svg($uri, logo => { image => $art });
    like($routed, qr/viewBox="0 0 50 100"/, 'sniffed SVG bytes inline');
}

# --- logo option validation ------------------------------------------------

eval { QR::Code->svg($uri, logo => {}) };
like($@, qr/logo needs exactly one of text, svg, image or file/,
     'empty logo hash croaks');
eval { QR::Code->svg($uri, logo => { text => 'a', svg => '<x/>' }) };
like($@, qr/exactly one of/, 'two logo kinds croak');
eval { QR::Code->svg($uri, logo => { text => '' }) };
like($@, qr/logo text is empty/, 'empty text croaks');
eval { QR::Code->svg($uri, logo => { text => 'a', frob => 1 }) };
like($@, qr/unknown logo option 'frob'/, 'unknown logo key croaks');

done_testing;
