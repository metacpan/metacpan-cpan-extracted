package PDF::Make::Builder::Font;
use strict;
use warnings;
use Object::Proto;
use PDF::Make::Page qw(:fonts);
use PDF::Make::Font ();

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Font',
        'colour:Str:default(#000)',
        'size:Num:default(9)',
        'family:Str:default(Helvetica)',
        'bold:Bool:default(0)',
        'italic:Bool:default(0)',
        'line_height:Num',
        'loaded:HashRef:default({})',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Font');
}

# Standard 14 font family mapping: family => { variant => page constant }
my %STD14 = (
    Times => {
        normal      => TIMES_ROMAN,
        bold        => TIMES_BOLD,
        italic      => TIMES_ITALIC,
        bolditalic  => TIMES_BOLDITALIC,
    },
    Helvetica => {
        normal      => HELVETICA,
        bold        => HELVETICA_BOLD,
        italic      => HELVETICA_OBLIQUE,
        bolditalic  => HELVETICA_BOLDOBLIQUE,
    },
    Courier => {
        normal      => COURIER,
        bold        => COURIER_BOLD,
        italic      => COURIER_OBLIQUE,
        bolditalic  => COURIER_BOLDOBLIQUE,
    },
    Symbol      => { normal => SYMBOL },
    ZapfDingbats => { normal => ZAPFDINGBATS },
);

# Map family+variant to PDF BaseFont name for XS Font
my %BASEFONT = (
    'Times_normal'           => 'Times-Roman',
    'Times_bold'             => 'Times-Bold',
    'Times_italic'           => 'Times-Italic',
    'Times_bolditalic'       => 'Times-BoldItalic',
    'Helvetica_normal'       => 'Helvetica',
    'Helvetica_bold'         => 'Helvetica-Bold',
    'Helvetica_italic'       => 'Helvetica-Oblique',
    'Helvetica_bolditalic'   => 'Helvetica-BoldOblique',
    'Courier_normal'         => 'Courier',
    'Courier_bold'           => 'Courier-Bold',
    'Courier_italic'         => 'Courier-Oblique',
    'Courier_bolditalic'     => 'Courier-BoldOblique',
    'Symbol_normal'          => 'Symbol',
    'ZapfDingbats_normal'    => 'ZapfDingbats',
);

# Cache for PDF::Make::Font XS objects (exact per-glyph metrics)
my %_xs_font_cache;

sub _xs_font {
    my ($self, $variant) = @_;
    $variant //= $self->_default_variant;
    my $fam = family $self;
    my $key = "${fam}_${variant}";
    return $_xs_font_cache{$key} if $_xs_font_cache{$key};
    my $basefont = $BASEFONT{$key};
    return undef unless $basefont;
    $_xs_font_cache{$key} = PDF::Make::Font->standard14($basefont);
    return $_xs_font_cache{$key};
}

sub _default_variant {
    my ($self) = @_;
    return 'bolditalic' if bold($self) && italic($self);
    return 'bold'       if bold($self);
    return 'italic'     if italic($self);
    return 'normal';
}

sub effective_line_height {
    my ($self) = @_;
    my $lh = line_height $self;
    return defined $lh && $lh > 0 ? $lh : size $self;
}

sub measure_text {
    my ($self, $text) = @_;
    my $xs = $self->_xs_font;
    return $xs->string_width($text, size $self) if $xs;
    # Fallback for unknown fonts
    return length($text) * 0.52 * (size $self);
}

sub measure_word {
    my ($self, $word) = @_;
    my $xs = $self->_xs_font;
    return $xs->string_width($word, size $self) if $xs;
    return length($word) * 0.52 * (size $self);
}

sub space_width {
    my ($self) = @_;
    my $xs = $self->_xs_font;
    return $xs->string_width(' ', size $self) if $xs;
    return 0.28 * (size $self);
}

sub hex_to_rgb {
    my ($self, $hex) = @_;
    $hex =~ s/^#//;
    my ($r, $g, $b);
    if (length($hex) == 3) {
        ($r, $g, $b) = map { hex($_.$_) / 255.0 } split //, $hex;
    } elsif (length($hex) == 6) {
        $r = hex(substr($hex, 0, 2)) / 255.0;
        $g = hex(substr($hex, 2, 2)) / 255.0;
        $b = hex(substr($hex, 4, 2)) / 255.0;
    } else {
        return (0, 0, 0);
    }
    return ($r, $g, $b);
}

sub resource_name {
    my ($self, $variant) = @_;
    $variant //= $self->_default_variant;
    my $fam = family $self;
    return "F_${fam}_${variant}";
}

sub ensure_loaded {
    my ($self, $xs_page, $variant) = @_;
    $variant //= $self->_default_variant;
    my $fam = family $self;
    my $key = "${fam}_${variant}";
    my $res_name = "F_${key}";

    # Cache is per-page (keyed by page pointer address) to handle overflow
    my $page_id = "$xs_page";  # stringified ref = unique per page
    my $ld = loaded $self;
    return $res_name if $ld->{"${key}_${page_id}"};

    my $family_map = $STD14{$fam};
    die "PDF::Make::Builder::Font: unknown font family '$fam'" unless $family_map;
    my $font_id = $family_map->{$variant};
    die "PDF::Make::Builder::Font: unknown variant '$variant' for '$fam'" unless defined $font_id;

    $xs_page->add_std14_font($res_name, $font_id);
    $ld->{"${key}_${page_id}"} = 1;
    loaded $self, $ld;
    return $res_name;
}

sub families { return keys %STD14 }

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Font - Font registry and metrics for PDF::Make

=head1 SYNOPSIS

    my $font = PDF::Make::Builder::Font->new(
        family => 'Helvetica',
        size   => 12,
        colour => '#333',
    );

    my $res = $font->ensure_loaded($xs_page);
    my $w   = $font->measure_text('Hello World');  # exact width

=head1 DESCRIPTION

Manages PDF Standard 14 font loading, resource naming, and text metrics.
Uses the C-level per-glyph width tables (via L<PDF::Make::Font>) for exact
text measurement. All 14 standard fonts with 4 variants each are supported.

=head1 PROPERTIES

=over 4

=item B<colour> (Str, default C<'#000'>) - Text colour as hex string.

=item B<size> (Num, default 9) - Font size in points.

=item B<family> (Str, default C<'Helvetica'>) - Font family: Times,
Helvetica, Courier, Symbol, ZapfDingbats.

=item B<line_height> (Num) - Explicit line height. Defaults to C<size>.

=back

=head1 METHODS

=over 4

=item B<measure_text($text)>

Returns the exact width of C<$text> in points using per-glyph width tables.

=item B<measure_word($word)>

Returns the exact width of C<$word> in points.

=item B<space_width()>

Returns the exact width of a space character in points.

=item B<ensure_loaded($xs_page, $variant)>

Registers the font on the page and returns the resource name.
C<$variant>: 'normal', 'bold', 'italic', 'bolditalic'.

=item B<resource_name($variant)>

Returns the resource name string without loading.

=item B<hex_to_rgb($hex)>

Converts hex colour to C<($r, $g, $b)> triple (0..1).

=item B<effective_line_height()>

Returns C<line_height> if set, otherwise C<size>.

=item B<families()>

Class method. Returns available font family names.

=back

=head1 SEE ALSO

L<PDF::Make::Font>, L<PDF::Make::Builder>, L<PDF::Make::Builder::Text>

=cut
