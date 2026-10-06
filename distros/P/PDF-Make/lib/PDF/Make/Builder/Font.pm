package PDF::Make::Builder::Font;
use strict;
use warnings;
use Object::Proto;
use PDF::Make::Page qw(:fonts);
use PDF::Make::Font ();
use Font::Metrics ();

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Font',
        'colour:Str:default(#000)',
        'size:Num:default(9)',
        'family:Str:default(Helvetica)',
        'bold:Bool:default(0)',
        'italic:Bool:default(0)',
        'line_height:Num',
        'loaded:HashRef:default({})',
        'registry:HashRef:default({})',
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

# Cache for Font::Metrics objects (exact per-glyph metrics via Font::Metrics XS)
my %_fm_cache;

# A family registered by Builder::load_ttf, or undef for a Standard 14 family.
# The entry is the hashref the Builder owns: { font, path, obj, pages }, shared
# by reference with every font cloned from this one, so a page recorded here is
# a page the Builder will attach the embedded font to when it finalises.
sub _ttf {
    my ($self) = @_;
    my $reg = registry $self;
    return undef unless $reg;
    return $reg->{ family $self };
}

sub is_ttf { return defined $_[0]->_ttf ? 1 : 0 }

sub _xs_font {
    my ($self, $variant) = @_;
    my $ttf = $self->_ttf;
    return $ttf->{font} if $ttf;
    $variant //= $self->_default_variant;
    my $fam = family $self;
    my $key = "${fam}_${variant}";
    return $_fm_cache{$key} if $_fm_cache{$key};
    my $basefont = $BASEFONT{$key};
    return undef unless $basefont;
    $_fm_cache{$key} = Font::Metrics->new(name => $basefont);
    return $_fm_cache{$key};
}

# The show operator this font's text needs, and the operand to give it.
#
# A loaded TTF is embedded as a Type0 font with Identity-H encoding, so its
# operand is two bytes of glyph id per character and goes in a hex string.
# encode_utf8 also marks each glyph used, which is what the subsetter embeds,
# so this must run for every string actually drawn.
sub show_op { return $_[0]->is_ttf ? 'Tj_hex' : 'Tj' }

sub encode {
    my ($self, $text) = @_;
    my $ttf = $self->_ttf;
    return $text unless $ttf;
    return '' unless defined $text;
    my $utf8 = $text;
    utf8::upgrade($utf8);   # SvPV then always hands XS UTF-8, never Latin-1
    return $ttf->{font}->encode_utf8($utf8);
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

# The leading a set of overrides gets when it is resolved against $base.
# Returns undef to mean "let effective_line_height take the size", which is
# not the same as returning the base's leading.
#
# A size override has to bring its own line height with it. Taking the base
# font's - which is what every caller here used to do - gave a 20pt run a
# 9pt slot: the baseline sits one font size below the cursor, the cursor
# advances by the slot, and the next block is drawn through the text above
# it. That is the <text size="20"> collision.
#
# An explicit line_height always wins. Otherwise a size override with no
# leading of its own scales the base's explicitly-set leading by the size
# ratio - the unitless-line-height rule - and where the base never set one,
# undef leaves the new size to speak for itself.
sub resolve_line_height {
    my ($class, $base, $overrides) = @_;
    return $overrides->{line_height} if defined $overrides->{line_height};
    return $base->effective_line_height unless defined $overrides->{size};

    my $base_lh   = $base->line_height;
    my $base_size = $base->size;
    return undef unless defined $base_lh && $base_lh > 0 && $base_size;
    return $base_lh * ($overrides->{size} / $base_size);
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
    my $fam = family $self;
    # One file is one face, so a loaded TTF has no bold/italic variants to
    # name - asking for bold on it gets the face as supplied.
    return "F_${fam}" if $self->is_ttf;
    $variant //= $self->_default_variant;
    return "F_${fam}_${variant}";
}

sub ensure_loaded {
    my ($self, $xs_page, $variant) = @_;
    my $fam = family $self;

    # An embedded font cannot be attached to the page yet: its object number
    # is only known once the document is written, because subsetting depends
    # on every glyph drawn with it. Record the page and let the Builder
    # attach it in _finalise.
    if (my $ttf = $self->_ttf) {
        my $res_name = "F_${fam}";
        push @{ $ttf->{pages} }, $xs_page
            unless grep { $_ == $xs_page } @{ $ttf->{pages} };
        return $res_name;
    }

    $variant //= $self->_default_variant;
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
