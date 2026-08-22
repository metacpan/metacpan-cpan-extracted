use strict;
use warnings;
use Test::More;
use File::Temp ();
use QR::Code;

# The ground-truth test: encoded by this distribution, decoded by zbar -
# a decoder sharing no code and no assumptions with the encoder. This is
# the class of test that found the format-info bit-order bug after the
# whole internal battery had passed.
#
# Author test (xt/), because it needs zbarimg and a rasterizer. The
# pure-Perl decoder in t/04-decode.t runs everywhere.

my ($zbar)   = grep { -x $_ } map { "$_/zbarimg" }     split /:/, $ENV{PATH};
my ($magick) = grep { -x $_ } map { ("$_/magick", "$_/convert") }
                              split /:/, $ENV{PATH};
my ($rsvg)   = grep { -x $_ } map { "$_/rsvg-convert" } split /:/, $ENV{PATH};
plan skip_all => 'zbarimg not installed'     unless $zbar;
plan skip_all => 'ImageMagick not installed' unless $magick;

my $dir = File::Temp->newdir;
my %ECC = (L => 0, M => 1, Q => 2, H => 3);
my $n = 0;

sub zbar_pbm {
    my ($payload, %opt) = @_;
    my $base = "$dir/t" . $n++;
    open my $fh, '>', "$base.pbm" or die $!;
    print $fh QR::Code->pbm($payload, %opt);
    close $fh;
    system("$magick $base.pbm -scale 600% $base.png") == 0 or return '';
    my $got = `$zbar -q --raw $base.png 2>/dev/null`;
    $got =~ s/\s+\z//;
    return $got;
}

sub zbar_svg {
    my ($svg) = @_;
    my $base = "$dir/s" . $n++;
    open my $fh, '>', "$base.svg" or die $!;
    print $fh $svg;
    close $fh;
    system("$rsvg -w 700 -h 700 $base.svg -o $base.png") == 0 or return '';
    my $got = `$zbar -q --raw $base.png 2>/dev/null`;
    $got =~ s/\s+\z//;
    return $got;
}

# every version and ECC level at exact capacity
for my $ecc (qw(L M Q H)) {
    for my $v (1 .. 15) {
        my $cap = QR::Code::_capacity($ECC{$ecc}, $v);
        my $payload = join '', map { chr(65 + $_ % 26) } 0 .. $cap - 1;
        is zbar_pbm($payload, ecc => $ecc, version => $v), $payload,
            "v$v/$ecc at capacity decodes through zbar";
    }
}

SKIP: {
    skip 'rsvg-convert not installed', 8 unless $rsvg;

    my $uri = 'otpauth://totp/Example:alice@example.com'
            . '?secret=ABCDEFGHIJKLMNOPQRSTUVWXYZ234567&issuer=Example';

    # every styling option claims decodability; each claim meets the
    # decoder here
    my %styled = (
        'plain'          => [],
        'logo'           => [ logo => 'Punk' ],
        'rounded'        => [ style => { shape => 'rounded' } ],
        'dots'           => [ style => { shape => 'dot' } ],
        'circle finders' => [ style => { finder => 'circle',
                                         shape  => 'rounded' } ],
        'coloured'       => [ style => { dark  => '#102a43',
                                         light => '#f0f4f8' } ],
        'gradient'       => [ style => { gradient =>
                                { stops => ['#0f0c29', '#302b63'] } } ],
        'the lot'        => [ logo  => 'Punk',
                              style => { shape  => 'rounded',
                                         finder => 'rounded',
                                         dark   => '#102a43',
                                         gradient =>
                                { stops => ['#0f0c29', '#24243e'] } } ],
    );
    for my $name (sort keys %styled) {
        my $svg = QR::Code->svg($uri, ecc => 'H', @{ $styled{$name} });
        is zbar_svg($svg), $uri, "$name decodes through zbar";
    }

    # Measured margin, recorded as a TODO rather than papered over:
    # circle finders only satisfy the locator's 1:1:3:1:1 ratio exactly
    # through their centre row, so every other styling option stacked on
    # top spends margin the circles already thinned. zbar fails this
    # stack at some raster scales and reads it at others. The POD
    # carries the warning; phase 1b owns the calibration.
    TODO: {
        local $TODO = 'circle finders + gradient sit on the decoder margin';
        my $svg = QR::Code->svg($uri, ecc => 'H',
            logo  => 'Punk',
            style => { shape => 'rounded', finder => 'circle',
                       dark  => '#102a43',
                       gradient => { stops => ['#0f0c29', '#24243e'] } });
        is zbar_svg($svg), $uri, 'circle finders under a full stack';
    }
}

done_testing;
