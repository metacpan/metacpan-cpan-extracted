package PDF::Builder::Resource::Font::CoreFont;

use base 'PDF::Builder::Resource::Font';

use strict;
use warnings;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.028'; # manually update whenever code is changed

use File::Basename;
use List::Util qw(any);
use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;

our $fonts;
our $alias;
our $subs;

=head1 NAME

PDF::Builder::Resource::Font::CoreFont - Module for using the 14 standard PDF built-in Fonts (plus 15 Windows Fonts)

Inherits from L<PDF::Builder::Resource::Font>

=head1 SYNOPSIS

    #
    use PDF::Builder;
    #
    my $pdf = PDF::Builder->new();
    my $cft = $pdf->font('Times-Roman');
   #my $cft = $pdf->corefont('Times-Roman');
    #
    my $page = $pdf->page();
    my $text = $page->text();
    $text->font($cft, 20);
    $text->translate(200, 700);
    $text->text("Hello, World!");

=head1 METHODS

=head2 new

    $font = PDF::Builder::Resource::Font::CoreFont->new($pdf, $fontname, %options)

=over

Returns a corefont object.

=back

=head2 Supported typefaces

=head3 Standard PDF types

See examples/020_corefonts for a list of each font's glyphs.

=over

=item * Helvetica, Helvetica-Oblique, Helvetica-Bold, Helvetia-BoldOblique

Sans-serif, may have Arial substituted on some systems (e.g., Windows).

=item * Courier, Courier-Oblique, Courier-Bold, Courier-BoldOblique

Fixed pitch, may have Courier New substituted on some systems (e.g., Windows).

=item * Times-Roman, Times-Italic, Times-Bold, Times-BoldItalic

Serif, may have Times New Roman substituted on some systems (e.g., Windows).

=item * Symbol, ZapfDingbats

Various symbols, including the Greek alphabet (in Symbol).

=back

=head3 Primarily Windows typefaces

See examples/022_truefonts /Windows/Fonts/<name>.ttf 
for a list of each font's glyphs. examples/020_corefonts can also be used.

=over

=item * Georgia, Georgia-Italic, Georgia-Bold, Georgia-BoldItalic

Serif proportional.

=item * Trebuchet, Trebuchet-Italic, Trebuchet-Bold, Trebuchet-BoldItalic

Sans-serif proportional with simple strokes.

=item * Verdana, Verdana-Italic, Verdana-Bold, Verdana-BoldItalic

Sans-serif proportional with simple strokes.

=item * BankGothic, BankGothic-Italic, BankGothic-Bold, BankGothic-BoldItalic

Sans-serif proportional with simple strokes.
Free versions of Bank Gothic are often only medium weight Roman (BankGothic),
and this is all that usually comes with Windows.

=item * Webdings, Wingdings

Various symbols, in the vein of Zapf Dingbats.

=back

Keep in mind that only font metrics (widths) are provided with PDF::Builder;
the fonts themselves are provided by the reader's machine (often packaged
with the operating system, or obtained separately by the user). To use a
specific font may require you to obtain one or more files from some source.

If a font (typeface and variant) is not available on a given reader's
machine, a substitution I<may> be automatically made. For example, Helvetica is
usually not shipped with Windows machines, and Arial might be substituted.
For most characters, the glyph widths will be the same, but this can not be 
guaranteed!

PDF::Builder currently uses the [typeface].pm files to map glyph names to
code points (single byte encodings only) and to look up the glyph widths for
character positioning. There is no guarantee that a given font file includes
all the desired glyphs, nor that the widths will be absolutely the same, even
in different releases of the same font.

=head2 Options

=over

=item encode

Changes the encoding of the font from its default. Notice that the encoding
(I<not> the entire font's glyph list) is shown in a PDF object (record), listing
256 glyphs associated with this encoding (I<and> that are available in this 
font). 

See I<Perl's Encode> for the supported values. B<Warning:> only single byte 
encodings are permitted. Multibyte encodings such as 'utf8' are forbidden.

=item dokern

Enables kerning if data is available.

C<kerning> is an older name for this option, and is still available as
an B<alternative> to C<dokern>.

=item pdfname

Changes the reference-name of the font from its default.
The reference-name is normally generated automatically and can be
retrieved via $pdfname=$font->name().

=item metrics

If given, it is expected to be an anonymous hash of font file data. This is
to be used instead of looking up the I<$fontname>.pm file for width and other
data. You may need to use this option if your installed font happens to be
out of sync with the PDF::Builder built-in core font metrics file (e.g.,
I<helveticabold.pm>).

=back

=cut

# PDF standard 14 core fonts
my @standard_fonts = qw(
    Courier Courier-Oblique Courier-Bold Courier-BoldOblique
    Helvetica Helvetica-Oblique Helvetica-Bold Helvetica-BoldOblique
    Times-Roman Times-Italic Times-Bold Times-BoldItalic
    Symbol ZapfDingbats
);

# Windows extension of 15 core fonts
my @windows_fonts = qw(
    BankGothic
    Georgia Georgia-Italic Georgia-Bold Georgia-BoldItalic
    Trebuchet Trebuchet-Italic Trebuchet-Bold Trebuchet-BoldItalic
    Verdana Verdana-Italic Verdana-Bold Verdana-BoldItalic
    Webdings Wingdings
);

# Windows Fonts with Type1 equivalence
$alias = {
    'arial'                     => 'helvetica',
    'arialitalic'               => 'helveticaoblique',
    'arialbold'                 => 'helveticabold',
    'arialbolditalic'           => 'helveticaboldoblique',

    'times'                     => 'timesroman',
    'timesnewromanbolditalic'   => 'timesbolditalic',
    'timesnewromanbold'         => 'timesbold',
    'timesnewromanitalic'       => 'timesitalic',
    'timesnewroman'             => 'timesroman',

    'couriernewbolditalic'      => 'courierboldoblique',
    'couriernewbold'            => 'courierbold',
    'couriernewitalic'          => 'courieroblique',
    'couriernew'                => 'courier',
};

sub _look_for_font {
    my $name = shift;

    ## return %{$fonts->{$name}} if defined $fonts->{$name};
    eval "require PDF::Builder::Resource::Font::CoreFont::$name; "; ## no critic
    unless($@) {
        my $class = "PDF::Builder::Resource::Font::CoreFont::$name";
        my $font = _deep_copy($class->data());
        $font->{'uni'} ||= [];
        foreach my $n (0..255) {
	    unless (defined $fonts->{'uni'}->[$n]) {
                $font->{'uni'}->[$n] = uniByName($font->{'char'}->[$n]);
            }
        }
        return %$font;
    } else {
        die "requested core font '$name' not installed ";
    }
}

#
# Deep copy something, thanks to Randal L. Schwartz
# Changed to deal w/ CODE refs, in which case it doesn't try to deep copy
#
sub _deep_copy {
    my $this = shift;

    if      (not ref $this) {
        return $this;
    } elsif (ref($this) eq "ARRAY") {
        return [ map { _deep_copy($_) } @$this];   ## no critic
    } elsif (ref($this) eq "HASH") {
        return +{ map { $_ => _deep_copy($this->{$_}) } keys %$this };
    } elsif (ref($this) eq "CODE") {
        # Can't deep copy code refs
        return $this;
    } else {
        die "what type is $_? Unable to copy a ".ref($this);
    }
}

sub new {
    my ($class, $pdf, $name, @opts) = @_;

    my ($self, $data);
    my %opts = ();
    my $is_standard = is_standard($name);

    if (-f $name) {
        eval "require '$name'; "; ## no critic
        $name = basename($name,'.pm');
    }
    my $lookname = lc($name);
    $lookname =~ s/[^a-z0-9]+//gi; # e.g., Times-Roman to timesroman
    %opts = @opts if (scalar @opts)%2 == 0;
    # copy dashed name options to preferred undashed names
    if (defined $opts{'-encode'} && !defined $opts{'encode'}) { $opts{'encode'} = delete($opts{'-encode'}); }
    if (defined $opts{'-metrics'} && !defined $opts{'metrics'}) { $opts{'metrics'} = delete($opts{'-metrics'}); }
    if (defined $opts{'-dokern'} && !defined $opts{'dokern'}) { $opts{'dokern'} = delete($opts{'-dokern'}); }
    if (defined $opts{'-kerning'} && !defined $opts{'kerning'}) { $opts{'kerning'} = delete($opts{'-dokern'}); }
    if (defined $opts{'-pdfname'} && !defined $opts{'pdfname'}) { $opts{'pdfname'} = delete($opts{'-pdfname'}); }

    $opts{'encode'} //= 'latin1';
    $lookname = $alias->{$lookname} if $alias->{$lookname};

    if (defined $subs->{$lookname}) {
        $data = {_look_for_font($subs->{$lookname}->{'-alias'})};
        foreach my $k (keys %{$subs->{$lookname}}) {
            next if $k =~ /^\-/;
            $data->{$k} = $subs->{$lookname}->{$k};
        }
    } else {
        unless (defined $opts{'metrics'}) {
            $data = {_look_for_font($lookname)};
        } else {
            $data = {%{$opts{'metrics'}}};
        }
    }

    die "Undefined Core Font '$name($lookname)'" unless $data->{'fontname'};

    # we have data now here so we need to check if
    # there is a -ttfile or -afmfile/-pfmfile/-pfbfile
    # and proxy the call to the relevant modules
    #
    #if (defined $data->{'-ttfile'} && $data->{'-ttfile'} = _look_for_fontfile($data->{'-ttfile'})) {
    #    return PDF::Builder::Resource::CIDFont::TrueType->new($pdf, $data->{'-ttfile'}, @opts);
    #} elsif (defined $data->{'-pfbfile'} && $data->{'-pfbfile'} = _look_for_fontfile($data->{'-pfbfile'})) {
    #    $data->{'-afmfile'} = _look_for_fontfile($data->{'-afmfile'});
    #    return PDF::Builder::Resource::Font::Postscript->new($pdf, $data->{'-pfbfile'}, $data->{'-afmfile'}, @opts));
    #} elsif (defined $data->{'-gfx'}) { # to be written and tested in 'Maki' first!
    #    return PDF::Builder::Resource::Font::gFont->new($pdf, $data, @opts);
    #}

    $class = ref($class) if ref($class);
#   $self = $class->SUPER::new($pdf, $data->{'apiname'}.pdfkey().'~'.time());
    $self = $class->SUPER::new($pdf, $data->{'apiname'}.pdfkey());
    $pdf->new_obj($self) unless $self->is_obj($pdf);
    $self->{' data'} = $data;
    $self->{'-dokern'} = 1 if $opts{'dokern'};

    $self->{'Subtype'} = PDFName($self->data()->{'type'});
    $self->{'BaseFont'} = PDFName($self->fontname());
    if ($opts{'pdfname'}) {
        $self->name($opts{'pdfname'});
    }

    unless ($self->data()->{'iscore'}) {
        $self->{'FontDescriptor'} = $self->descrByData();
    }

    if ($opts{'encode'} =~ m/^utf/i) {
	die "Invalid multibyte encoding for corefont: $opts{'encode'}\n";
	# probably more encodings to check
    }
    $self->encodeByData($opts{'encode'});

    # The standard non-symbolic fonts use unmodified WinAnsiEncoding.
    if ($is_standard and not $self->issymbol() and not $opts{'encode'}) {
        $self->{'Encoding'} = PDFName('WinAnsiEncoding');
        delete $self->{'FirstChar'};
        delete $self->{'LastChar'};
        delete $self->{'Widths'};
    }

    return $self;
}

=head2 is_standard

    $bool = $class->is_standard($name)

    $bool = $class->is_standard($name, $win_flag)

=over

Returns true if C<$name> is an exact, case-sensitive match for one of the
standard font names shown above.
If C<$win_flag> is given, and is true (1), check against not only the basic
14 fonts, but also against the additional 15 Windows core font extensions.

=back

=cut

sub is_standard {
    # depending on whether it's called as a method or as a local
    # subroutine, it will or will not have a blessed object as
    # first argument
    my $self = shift;
    my $name;
    if ($self =~ /^PDF::Builder/) {
        $name = shift;
    } else {
	$name = $self;
    }
    my $win_flag = 0;
    if (@_) { $win_flag = $_[0]; }

    if ($win_flag) {
	return any { $_ eq $name } (@standard_fonts, @windows_fonts);
    } else {
	return any { $_ eq $name } @standard_fonts;
    }
}

=head2 names

    my @font_names = PDF::Builder::Resource::Font::CoreFont->names($flag);

    my $array_ref  = PDF::Builder::Resource::Font::CoreFont->names($flag);

Returns an array or a reference to an array containing the names of the built-in
core (standard) fonts.

If called with an optional C<$flag> of "true" value (1), 
the additional 15 Windows core fonts are included.

=cut

sub names {
    my $self = shift;
    # need to revise if ever called as direct subroutine in CoreFont.pm
    my $Win_ext = 0;
    if (@_) {
	$Win_ext = $_[0];
    }
    
    if ($Win_ext) {
        return wantarray() ? (@standard_fonts,@windows_fonts) : 
	                    [(@standard_fonts,@windows_fonts)];
    } else {
        return wantarray() ? @standard_fonts : [@standard_fonts];
    }
}

# removed from PDF::API2
=head2 loadallfonts

    PDF::Builder::Resource::Font::CoreFont->loadallfonts($flag)

=over

"Requires in" all fonts available as corefonts, including Windows extensions
if the optional C<$flag> is given and is "true" (1).

B<Warning:> "dies" if any requested font is not found!

=back

=cut

sub loadallfonts {
    my $self = shift;
    # need to revise if ever called as local sub in CoreFont.pm
    my $Win_ext = 0;
    if (@_) {
	$Win_ext = $_[0];
    }

    foreach my $f (@standard_fonts) {
        _look_for_font($f);
    }
    if ($Win_ext) {
        foreach my $f (@windows_fonts) {
            _look_for_font($f);
        }
    }
    return;
}

# not yet supported
#    andalemono
#    arialrounded
#    impact
#    ozhandicraft

BEGIN
{

    # substitutes via synfont() for missing BankGothic variants
    $subs = {
         'bankgothicbold' => {
             'apiname'       => 'Bg2',
             '-alias'        => 'bankgothic',
             'fontname'      => 'BankGothicMediumBT,Bold',
             'flags'         => 32+262144,
         },
         'bankgothicbolditalic' => {
             'apiname'       => 'Bg3',
             '-alias'        => 'bankgothic',
             'fontname'      => 'BankGothicMediumBT,BoldItalic',
             'italicangle'   => -15,
             'flags'         => 96+262144,
         },
         'bankgothicitalic' => {
             'apiname'       => 'Bg4',
             '-alias'        => 'bankgothic',
             'fontname'      => 'BankGothicMediumBT,Italic',
             'italicangle'   => -15,
             'flags'         => 96,
         },
        #  'impactitalic'      => {
        #            'apiname' => 'Imp2',
        #            '-alias'  => 'impact',
        #            'fontname'  => 'Impact,Italic',
        #            'italicangle' => -12,
        #          },
        #  'ozhandicraftbold'    => {
        #            'apiname' => 'Oz2',
        #            '-alias'  => 'ozhandicraft',
        #            'fontname'  => 'OzHandicraftBT,Bold',
        #            'italicangle' => 0,
        #            'flags' => 32+262144,
        #          },
        #  'ozhandicraftitalic'    => {
        #            'apiname' => 'Oz3',
        #            '-alias'  => 'ozhandicraft',
        #            'fontname'  => 'OzHandicraftBT,Italic',
        #            'italicangle' => -15,
        #            'flags' => 96,
        #          },
        #  'ozhandicraftbolditalic'  => {
        #            'apiname' => 'Oz4',
        #            '-alias'  => 'ozhandicraft',
        #            'fontname'  => 'OzHandicraftBT,BoldItalic',
        #            'italicangle' => -15,
        #            'flags' => 96+262144,
        #          },
        #  'arialroundeditalic'  => {
        #            'apiname' => 'ArRo2',
        #            '-alias'  => 'arialrounded',
        #            'fontname'  => 'ArialRoundedMTBold,Italic',
        #            'italicangle' => -15,
        #            'flags' => 96+262144,
        #          },
        #  'arialitalic'  => {
        #            'apiname' => 'Ar2',
        #            '-alias'  => 'arial',
        #            'fontname'  => 'Arial,Italic',
        #            'italicangle' => -15,
        #            'flags' => 96,
        #          },
        #  'arialbolditalic'  => {
        #            'apiname' => 'Ar3',
        #            '-alias'  => 'arial',
        #            'fontname'  => 'Arial,BoldItalic',
        #            'italicangle' => -15,
        #            'flags' => 96+262144,
        #          },
        #  'arialbold'  => {
        #            'apiname' => 'Ar4',
        #            '-alias'  => 'arial',
        #            'fontname'  => 'Arial,Bold',
        #            'flags' => 32+262144,
        #          },
    };

    $fonts = { };

}

1;

__END__

=head1 AUTHOR

Alfred Reibenschuh

=cut


