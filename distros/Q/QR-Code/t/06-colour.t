use strict;
use warnings;
use Test::More;
use QR::Code;

# Colour is luminance: the parsing forms, and the checks that keep a
# styled symbol on the right side of a binarizer.

my $data = 'colour rules';

# --- forms -----------------------------------------------------------------

{
    my $svg = QR::Code->svg($data, style => { dark => '#123' });
    like($svg, qr/fill="#112233"/, '#rgb expands to #rrggbb');

    $svg = QR::Code->svg($data, style => { dark => '#102A43' });
    like($svg, qr/fill="#102a43"/, 'uppercase hex normalises to lower');

    $svg = QR::Code->svg($data, style => { dark => '#102a43ff' });
    like($svg, qr/fill="#102a43"/, 'full alpha is accepted and dropped');
}

# --- rejections, each naming its subject -----------------------------------

my @croaks = (
    [{ dark => 'red' },
     qr/style dark 'red' is not a hex colour/,
     'a named colour croaks naming the value'],
    [{ dark => '#12' },
     qr/style dark '#12' is not a hex colour/,
     'wrong length croaks'],
    [{ dark => '#00000080' },
     qr/style dark '#00000080' is translucent \(alpha 0\.50\)/,
     'translucent dark croaks with the alpha'],
    [{ dark => '#ffffff', light => '#000000' },
     qr/inverted colours: dark #ffffff \(luminance 1\.000\) is not darker/,
     'inversion croaks with both luminances'],
    [{ dark => '#cccccc' },
     qr/contrast too low: dark #cccccc \(luminance 0\.604\).*floor is 0\.40/,
     'a small gap croaks with the arithmetic'],
    [{ finder_dark => '#dddddd' },
     qr/contrast too low: finder_dark #dddddd/,
     'finder_dark faces the same check'],
    [{ light => 'transparent' },
     qr/style light 'transparent' is not a hex colour/,
     'only the literal none skips the ground'],
    [{ gradient => { stops => ['#000000', '#eeeeee'] } },
     qr/contrast too low: gradient stop 2 #eeeeee/,
     'the worst gradient stop gates, and is named'],
    [{ gradient => { stops => ['#0000o0', '#000000'] } },
     qr/gradient stop 1 '#0000o0' is not a hex colour/,
     'a malformed stop is named too'],
);

for my $case (@croaks) {
    my ($style, $re, $name) = @$case;
    eval { QR::Code->svg($data, style => $style) };
    like($@, $re, $name);
}

# --- the boundary sits where the message says ------------------------------

{
    # #bbbbbb leaves a gap of ~0.48 against white and passes; #cccccc
    # leaves ~0.40 and fails: the floor is real, not decorative
    my $svg = eval { QR::Code->svg($data, style => { dark => '#bbbbbb' }) };
    ok($svg && !$@, 'a gap just above the floor renders');
    eval { QR::Code->svg($data, style => { dark => '#cccccc' }) };
    ok($@, 'a gap just below it does not');
}

# --- transparent ground opts out, explicitly -------------------------------

{
    my $svg = eval { QR::Code->svg($data,
        style => { light => 'none', dark => '#eeeeee' }) };
    ok($svg && !$@,
       'light none skips the contrast check; the caller owns the ground');
}

done_testing;
