use strict;
use warnings;
use Test::More;
use QR::Code;

# The SVG serialiser against the matrix it serialises.

my $data = 'https://example.com/enrol?token=abcdef123456';

sub in_finder {
    my ($r, $c, $size) = @_;
    return ($r < 7 && $c < 7) || ($r < 7 && $c >= $size - 7)
        || ($r >= $size - 7 && $c < 7);
}

# parse the merged-run module path back into a grid
sub parse_runs {
    my ($d, $quiet) = @_;
    my %dark;
    while ($d =~ /M(\d+) (\d+)h(\d+)v1h-\d+z/g) {
        my ($x, $y, $w) = ($1, $2, $3);
        $dark{ ($y - $quiet) . ',' . ($x - $quiet + $_) } = 1 for 0 .. $w - 1;
    }
    return \%dark;
}

my ($mod, $fixed, $version, $mask, $size) = QR::Code->matrix($data);
my $svg = QR::Code->svg($data);

# document shape
my $span = $size + 8;
like($svg, qr/viewBox="0 0 $span $span"/, 'viewBox spans modules + 2*quiet');
like($svg, qr/width="@{[$span * 10]}" height="@{[$span * 10]}"/,
     'rendered size follows the span');
like($svg, qr/<rect width="$span" height="$span" fill="#ffffff"\/>/,
     'background rect covers the document');

# the module path agrees with the matrix, module for module
my @paths = $svg =~ /<path[^>]*d="([^"]*)"/g;
is(scalar @paths, 7, 'one module path and two paths per finder');

my $grid = parse_runs($paths[0], 4);
my ($missing, $extra, $dark_count) = (0, 0, 0);
for my $r (0 .. $size - 1) {
    for my $c (0 .. $size - 1) {
        next if in_finder($r, $c, $size);
        my $want = $mod->[$r][$c];
        $dark_count += $want;
        my $got = $grid->{"$r,$c"} ? 1 : 0;
        $missing++ if $want && !$got;
        $extra++   if !$want && $got;
    }
}
ok($dark_count > 50, "parsed a real symbol ($dark_count dark modules)");
is($missing, 0, 'every dark module outside the finders is in the path');
is($extra, 0, 'no module in the path that the matrix does not have');

# nothing from the finder zones leaks into the module path
my $leak = 0;
for my $key (keys %$grid) {
    my ($r, $c) = split /,/, $key;
    $leak++ if in_finder($r, $c, $size);
}
is($leak, 0, 'finder zones are carved out of the module path');

# quiet zone options
my $tight = QR::Code->svg($data, quiet => 0);
like($tight, qr/viewBox="0 0 $size $size"/, 'quiet 0 shrinks the viewBox');
my $wide = QR::Code->svg($data, quiet => 8);
my $wspan = $size + 16;
like($wide, qr/viewBox="0 0 $wspan $wspan"/, 'quiet 8 grows it');

# deterministic output
is(QR::Code->svg($data), $svg, 'same input, same document');

# info in list context
my (undef, $info) = QR::Code->svg($data);
is($info->{version}, $version, 'info version matches matrix');
is($info->{size}, $size, 'info size matches');
is($info->{ecc}, 'M', 'info carries the ECC letter');
ok(!exists $info->{logo}, 'no logo, no logo info');

# unknown options croak
eval { QR::Code->svg($data, colour => '#000') };
like($@, qr/unknown svg option 'colour'/, 'unknown svg option croaks');

done_testing;
