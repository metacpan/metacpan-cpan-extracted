# -*- indent-tabs-mode: nil -*-

package Term::ANSIColor::Concise::Transform;

our $VERSION = "3.02";

use v5.14;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT      = qw();
our @EXPORT_OK   = qw(transform $mod_re);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

use Data::Dumper;
use List::Util qw(min max any);

use aliased;
my $Color = alias 'Term::ANSIColor::Concise::' . ($ENV{TAC_COLOR_PACKAGE} || 'ColorObject');
sub Color { $Color }

sub adjust {
    my($v, $amnt, $mark, $base) = @_;
    if    ($mark->{'-'}) { $v - $amnt }
    elsif ($mark->{'+'}) { $v + $amnt }
    elsif ($mark->{'='}) { $amnt }
    elsif ($mark->{'*'}) { $v * $amnt / 100 }
    elsif ($mark->{'%'}) { ($v + $amnt) % ($base || 100) }
}

our $mod_re = qr/(?<m>[-+=*%])(?<c>[A-Za-z])(?<abs>\d*)/x;

sub transform {
    my($mods, @rgb24) = @_;
    my $color = Color->rgb(@rgb24);
    while ($mods =~ /(?<mod>$mod_re)/xg) {
        my($mod, $m, $c, $abs) = ($+{mod}, $+{m}//'', $+{c}, $+{abs}//0);
        my $com  = { map { $_ => 1 } $c =~ /./g };
        my $mark = { map { $_ => 1 } $m =~ /./g };
        $color = do {
            # Lightness
            if ($com->{l}) {
                my($h, $s, $l) = $color->hsl;
                Color->hsl($h, $s, adjust($l, $abs, $mark));
            }
            # Luminance
            elsif ($com->{y}) {
                $color->luminance(adjust($color->luminance, $abs, $mark));
            }
            # Saturation
            elsif ($com->{s}) {
                my($h, $s, $l) = $color->hsl;
                Color->hsl($h, adjust($s, $abs, $mark), $l);
            }
            # Inverse
            elsif ($com->{i}) {
                Color->rgb(map { 255 - $_ } $color->rgb);
            }
            # Luminance Grayscale
            elsif ($com->{g}) {
                my($h, $s, $l) = $color->hsl;
                my $y = $color->luminance;
                my $g = int($y * 255 / 100);
                Color->rgb($g, $g, $g)
            }
            # Lightness Grayscale
            elsif ($com->{G}) {
                $color->greyscale;
            }
            # Rotate Hue
            elsif ($com->{r} and $color->can('lch')) {
                my $dig = $com->{c} ? 180 : $abs;
                $dig = -$dig if $mark->{'-'};
                my($l, $c, $h) = $color->lch;
                Color->lch($l, $c, ($h + $dig) % 360);
            }
            # Hue Shift / Complement
            elsif ($com->{h} || $com->{c} || $com->{r}) {
                my($h, $s, $l) = $color->hsl;
                my $dig = $com->{c} ? 180 : $abs;
                $dig = -$dig if $mark->{'-'};
                my $c = Color->hsl(($h + $dig) % 360, $s, $l);
                $com->{r} ? $c->luminance($color->luminance)
                          : $c;
            }
            else {
                die "$mod: Invalid color adjustment parameter.\n";
            }
        };
    }
    $color->rgb;
}

1;
