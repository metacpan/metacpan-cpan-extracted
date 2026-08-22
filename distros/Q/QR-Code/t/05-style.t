use strict;
use warnings;
use Test::More;
use QR::Code;

# Shapes, finders and gradients - and that none of them disturb the
# modules a decoder samples.

my $data = 'styled symbols still have to scan';

sub in_finder {
    my ($r, $c, $size) = @_;
    return ($r < 7 && $c < 7) || ($r < 7 && $c >= $size - 7)
        || ($r >= $size - 7 && $c < 7);
}

sub dark_outside_finders {
    my ($mod, $size) = @_;
    my $n = 0;
    for my $r (0 .. $size - 1) {
        for my $c (0 .. $size - 1) {
            $n++ if $mod->[$r][$c] && !in_finder($r, $c, $size);
        }
    }
    return $n;
}

my ($mod, undef, undef, undef, $size) = QR::Code->matrix($data);
my $darks = dark_outside_finders($mod, $size);

sub paths { return [ $_[0] =~ /<path[^>]*d="([^"]*)"/g ] }

# --- square is the baseline ------------------------------------------------

is(QR::Code->svg($data, style => { shape => 'square' }),
   QR::Code->svg($data),
   'explicit square is byte-identical to the default');

like(QR::Code->svg($data), qr/<path shape-rendering="crispEdges"/,
     'square modules render crisp');

# --- dots ------------------------------------------------------------------

{
    my $svg = QR::Code->svg($data, style => { shape => 'dot' });
    my $p = paths($svg);
    my $subpaths = () = $p->[0] =~ /M/g;
    is($subpaths, $darks, 'one dot per dark module outside the finders');
    like($p->[0], qr/a0\.5 0\.5 0 1 0/, 'default radius is 0.5, touching');
    # The MODULE path must not be crisp; the square finder still is,
    # legitimately. Square-module paths are the ones whose runs end v1,
    # so that is the shape the assertion excludes.
    unlike($svg, qr/crispEdges[^>]*d="M[\d. ]+h\d+v1/,
           'curved modules are not forced crisp');
    unlike($p->[0], qr/crispEdges/, 'the module path itself is not crisp');

    my $small = QR::Code->svg($data,
        style => { shape => 'dot', radius => 0.4 });
    like(paths($small)->[0], qr/a0\.4 0\.4 /, 'radius option honoured');

    # the floor is the measured one: 0.30 still beats the square
    # baseline under blur, 0.25 falls below it
    ok(eval { QR::Code->svg($data,
              style => { shape => 'dot', radius => 0.3 }) },
       'radius 0.30 sits on the calibrated floor and renders');
    eval { QR::Code->svg($data, style => { shape => 'dot', radius => 0.25 }) };
    like($@, qr/below the floor of 0\.30/, 'radius below the floor croaks');
    eval { QR::Code->svg($data, style => { shape => 'dot', radius => 0.6 }) };
    like($@, qr/overlaps neighbouring modules/, 'radius over 0.5 croaks');
}

# --- rounded ---------------------------------------------------------------

{
    my $svg = QR::Code->svg($data, style => { shape => 'rounded' });
    my $p = paths($svg);
    my $subpaths = () = $p->[0] =~ /z/g;
    is($subpaths, $darks, 'one subpath per dark module');
    like($p->[0], qr/a0\.3 0\.3 0 0 1/, 'corners curve at the default 0.3');

    # a timing-pattern module is isolated horizontally and vertically
    # inside the track, so at least one cell must round all four corners;
    # a cell inside a solid run must emit none
    my @cells = $p->[0] =~ /M[^M]+/g;
    my ($four, $zero) = (0, 0);
    for my $cell (@cells) {
        my $arcs = () = $cell =~ /a0\.3/g;
        $four++ if $arcs == 4;
        $zero++ if $arcs == 0;
    }
    ok($four > 0, "isolated modules round every corner ($four of them)");
    ok($zero > 0, "run interiors stay square ($zero of them)");

    eval { QR::Code->svg($data,
                         style => { shape => 'rounded', radius => 0.7 }) };
    like($@, qr/exceeds half a module/, 'silly corner radius croaks');
}

# --- finders ---------------------------------------------------------------

{
    my $svg = QR::Code->svg($data);
    my @f = $svg =~ /<path[^>]*fill-rule="evenodd"[^>]*>/g;
    is(scalar @f, 3, 'three finder rings, one per corner');

    my $circle = QR::Code->svg($data, style => { finder => 'circle' });
    my $cf = paths($circle);
    # ring paths are 1,3,5 after the module path; each is two circles
    my $arcs = () = $cf->[1] =~ /a3\.5 3\.5|a2\.5 2\.5/g;
    is($arcs, 4, 'circle ring is two concentric circles');
    like($cf->[2], qr/a1\.5 1\.5/, 'circle pupil');

    my $rounded = QR::Code->svg($data, style => { finder => 'rounded' });
    like(paths($rounded)->[1], qr/a2\.1 2\.1/, 'rounded ring corners');

    # the module shape does not leak into the finders: dot modules,
    # square finders
    my $mixed = QR::Code->svg($data, style => { shape => 'dot' });
    my $mf = paths($mixed);
    unlike($mf->[1], qr/a0\.5/, 'finders are never dotted');
    like($mf->[1], qr/M\d+ \d+h7v7h-7z/, 'finder ring stays solid');
}

# --- colours reach the right elements --------------------------------------

{
    my $svg = QR::Code->svg($data, style => {
        dark => '#102a43', light => '#f0f4f8', finder_dark => '#7c1d1d',
    });
    like($svg, qr/<rect width="\d+" height="\d+" fill="#f0f4f8"\/>/,
         'background takes light');
    like($svg, qr/<path shape-rendering="crispEdges" fill="#102a43" d="M/,
         'modules take dark');
    my @finder_fills = $svg =~ /fill-rule="evenodd" fill="(#[0-9a-f]{6})"/g;
    is_deeply(\@finder_fills, ['#7c1d1d', '#7c1d1d', '#7c1d1d'],
              'finders take finder_dark');
}

# --- transparent ground ----------------------------------------------------

{
    my $svg = QR::Code->svg($data, style => { light => 'none' });
    unlike($svg, qr/<rect/, 'light none draws no background rect');

    my ($lsvg) = QR::Code->svg($data,
        style => { light => 'none' }, logo => 'QR', version => 10);
    my @rects = $lsvg =~ /<rect[^>]*fill="([^"]+)"/g;
    is_deeply(\@rects, ['#ffffff'],
              'the logo knockout stays an opaque pad');
}

# --- the knockout follows light --------------------------------------------

{
    my ($svg) = QR::Code->svg($data,
        style => { light => '#e6f0ff' }, logo => 'QR', version => 10);
    my @rects = $svg =~ /<rect[^>]*fill="([^"]+)"\/>/g;
    is_deeply(\@rects, ['#e6f0ff', '#e6f0ff'],
              'background and knockout both take light');
    like($svg, qr/<text[^>]*fill="#000000">/, 'text logo takes dark');
}

# --- gradients -------------------------------------------------------------

{
    my $svg = QR::Code->svg($data, style => {
        gradient => { angle => 45, stops => ['#5e60ce', '#1048e3'] },
    });
    like($svg, qr/<linearGradient id="qg"/, 'linear gradient defined');
    like($svg,
         qr/<stop offset="0\.0000" stop-color="#5e60ce"\/><stop offset="1\.0000" stop-color="#1048e3"\/>/,
         'stops in order');
    like($svg, qr/fill="url\(#qg\)" d="M/, 'modules take the gradient');
    my @finder_fills = $svg =~ /fill-rule="evenodd" fill="([^"]+)"/g;
    is_deeply(\@finder_fills, ['#000000', '#000000', '#000000'],
              'finders keep their flat colour');

    my $rad = QR::Code->svg($data, style => {
        gradient => { type => 'radial', stops => ['#5e60ce', '#1048e3'] },
    });
    like($rad, qr/<radialGradient id="qg"/, 'radial variant');

    my $three = QR::Code->svg($data, style => {
        gradient => { stops => ['#5e60ce', '#303030', '#1048e3'] },
    });
    like($three, qr/offset="0\.5000" stop-color="#303030"/,
         'middle stops space evenly');
}

# --- style validation ------------------------------------------------------

eval { QR::Code->svg($data, style => { shape => 'star' }) };
like($@, qr/style shape must be square, rounded or dot, not 'star'/,
     'unknown shape croaks');
eval { QR::Code->svg($data, style => { finder => 'triangle' }) };
like($@, qr/style finder must be square, rounded or circle/,
     'unknown finder croaks');
eval { QR::Code->svg($data, style => { glow => 1 }) };
like($@, qr/unknown style option 'glow'/, 'unknown style key croaks');
eval { QR::Code->svg($data, style => { gradient => { type => 'conic',
       stops => ['#000', '#111'] } }) };
like($@, qr/gradient type must be linear or radial/, 'bad type croaks');
eval { QR::Code->svg($data, style => { gradient => { stops => ['#000'] } }) };
like($@, qr/at least two stops/, 'one stop croaks');
eval { QR::Code->svg($data, style => { gradient =>
       { stops => [('#000') x 9] } }) };
like($@, qr/at most 8 stops/, 'nine stops croak');

done_testing;
