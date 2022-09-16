package PDF::Builder::Resource::Font::SynFont;

use base 'PDF::Builder::Resource::Font';

use strict;
use warnings;

our $VERSION = '3.024'; # VERSION
our $LAST_UPDATE = '3.024'; # manually update whenever code is changed

use Math::Trig;    # CAUTION: deg2rad(0) = deg2rad(360) = 0!
use Unicode::UCD 'charinfo';

use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;

# for noncompatible options, consider '-entry_point' = 'synfont' or 
# 'synthetic_font' to be picked up and processed correctly per entry point
 
=head1 NAME

PDF::Builder::Resource::Font::SynFont - Module for creating temporary synthetic Fonts.

=head1 SYNOPSIS

This module permits you to create a "new" font (loaded temporarily, but not 
permanently stored) based on an existing font, where you can modify certain 
attributes in the original font, such as: 

    * slant/obliqueness 
    * extra weight/boldness (by drawing glyph outlines at various line 
      thicknesses, rather than just filling enclosed areas)
    * condense/expand (narrower or wider characters)
    * extra space between characters
    * small caps (synthesized, not using any provided with a font)
    * change the encoding

    $pdf = PDF::Builder->new();
    $cft = $pdf->font('Times-Roman');  # corefont, ttfont, etc. also works
    $sft = $pdf->synfont($cft, 'condense' => .75);  # condense by 25%

This works for I<corefonts>, I<PS fonts>, and I<TTF/OTF fonts>; but does not
work for I<CJK fonts> or I<bitmapped fonts>.
See also L<PDF::Builder::Docs/Synthetic Fonts>.

B<Alternate name:> C<synthetic_font>

This is for compatibility with recent changes to PDF::API2.

=head1 METHODS

=over

=item $font = PDF::Builder::Resource::Font::SynFont->new($pdf, $fontobj, %opts)

Returns a synfont object. C<$fontobj> is a normal font object read in from
a file, and C<$font> is the modified output.

Valid options %opts are:

=over

=item I<encode>

Changes the encoding of the font from its default.
See I<Perl's Encode> for the supported values. B<Warning:> only single byte
encodings are supported. Multibyte encodings such as UTF-8 are invalid.

=item I<pdfname>

Changes the reference-name of the font from its default.
The reference-name is normally generated automatically and can be
retrieved via $pdfname=$font->name().

B<Alternate name:> C<name> (for PDF::API2 compatibility)

=item I<condense>

Condense/expand factor (0.1-0.9 = condense, 1 = normal, 1.1+ = expand).
It's the multiplier for character widths vs. normal.

B<Alternate names:> C<hscale> and C<slant> (for PDF::API2 compatibility) 

The I<slant> option is a deprecated name in both PDF::Builder and PDF::API2.
Its value is the same as I<condense> value (1 = normal, unchanged scale).
For the I<hscale> option, the value is percentage (%), with 100 being normal,
and other values 100 times the I<condense> value. 
B<Use only one (at most) of these three option names.>

=item I<oblique>

Italic angle (+/-) in degrees, where the character box is skewed. While 
it's unlikely that anyone will want to slant characters at +/-360 degrees, they 
should be aware that these will be treated as an angle of 0 degrees (deg2rad() 
wraps around). 0 degrees of italic slant (obliqueness) is the default.

B<Alternate name:> C<angle> (for PDF::API2 compatibility)

B<Use only one (at most) of these two option names.>

=item I<bold>

Embolding factor (0.1+, bold=1, heavy=2, ...). It is additional outline
B<thickness> (B<linewidth>), which expands the character (glyph) outwards (as
well as shrinking unfilled enclosed areas such as bowls and counters). 
Normally, the glyph's outline is not drawn (it is only filled); this adds
a thick outline. The units are in 1/100ths of a text unit.

If used with the C<synthetic_font> alternate entry name, the unit is 1/1000th
of a text unit, so you will need a value 10 times larger than with the 
C<synfont> entry to get the same effect

=item I<space>

Additional charspacing in thousandths of an em.

=item I<caps>

Create synthetic small-caps. 0 = no, 1 = yes. These are capitals of 
lowercase letters, at 80% height and 88% width. Note that this is guaranteed
to cover ASCII lowercase letters only -- single byte encoded accented 
characters I<usually> work, but we can make no promises on accented characters 
in general, as well as ligatures!

B<Alternate name:> C<smallcaps> (for PDF::API2 compatibility) 

B<Use only one (at most) of these two option names.>

=back

=back

=cut

sub new {
    my ($class, $pdf, $font, %opts) = @_;
    # copy dashed named options to preferred undashed names
    if (defined $opts{'-encode'} && !defined $opts{'encode'}) { $opts{'encode'} = delete($opts{'-encode'}); }
    if (defined $opts{'-pdfname'} && !defined $opts{'pdfname'}) { $opts{'pdfname'} = delete($opts{'-pdfname'}); }
        if (defined $opts{'-name'} && !defined $opts{'name'}) { $opts{'name'} = delete($opts{'-name'}); }
    if (defined $opts{'-condense'} && !defined $opts{'condense'}) { $opts{'condense'} = delete($opts{'-condense'}); }
        if (defined $opts{'-slant'} && !defined $opts{'slant'}) { $opts{'slant'} = delete($opts{'-slant'}); }
        if (defined $opts{'-hscale'} && !defined $opts{'hscale'}) { $opts{'hscale'} = delete($opts{'-hscale'}); }
    if (defined $opts{'-oblique'} && !defined $opts{'oblique'}) { $opts{'oblique'} = delete($opts{'-oblique'}); }
        if (defined $opts{'-angle'} && !defined $opts{'angle'}) { $opts{'angle'} = delete($opts{'-angle'}); }
    if (defined $opts{'-bold'} && !defined $opts{'bold'}) { $opts{'bold'} = delete($opts{'-bold'}); }
    if (defined $opts{'-space'} && !defined $opts{'space'}) { $opts{'space'} = delete($opts{'-space'}); }
    if (defined $opts{'-caps'} && !defined $opts{'caps'}) { $opts{'caps'} = delete($opts{'-caps'}); }
        if (defined $opts{'-smallcaps'} && !defined $opts{'smallcaps'}) { $opts{'smallcaps'} = delete($opts{'-smallcaps'}); }

    my $entry = "synfont";  # synfont or synthetic_font
    if (defined $opts{'-entry_point'}) { $entry = $opts{'-entry_point'}; }

    # deal with simple aliases
    if (defined $opts{'slant'} && !defined $opts{'condense'}) { $opts{'condense'} = delete($opts{'slant'}); }
    if (defined $opts{'angle'} && !defined $opts{'oblique'}) { $opts{'oblique'} = delete($opts{'angle'}); }
    if (defined $opts{'smallcaps'} && !defined $opts{'caps'}) { $opts{'caps'} = delete($opts{'smallcaps'}); }
    if (defined $opts{'name'} && !defined $opts{'pdfname'}) { $opts{'pdfname'} = delete($opts{'name'}); }
    # deal with semi-aliases
    if (defined $opts{'hscale'} && !defined $opts{'condense'}) { $opts{'condense'} = delete($opts{'hscale'})/100; }
    # deal with entry point differences
    if (defined $opts{'bold'} && $entry eq 'synthetic_font') { $opts{'bold'} /= 10; }

    my ($self);
    my $first = 1;
    my $last = 255;
    my $cond = $opts{'condense'} || 1;
    my $oblique = $opts{'oblique'} || 0;
    my $space = $opts{'space'} || '0';
    my $bold = ($opts{'bold'} || 0)*10; # convert to em
   #   caps

    # 5 elements apparently not used anywhere
   #$self->{' cond'} = $cond;
   #$self->{' oblique'} = $oblique;
   #$self->{' bold'} = $bold;
   #$self->{' boldmove'} = 0.001;
   #$self->{' space'} = $space;
    # only available in TT fonts. besides, multibyte encodings not supported
    if (defined $opts{'encode'}) {
        if ($opts{'encode'} =~ m/^utf/i) {
	    die "Invalid multibyte encoding for synfont: $opts{'encode'}\n";
	    # TBD probably more multibyte encodings to check
        }
        $font->encodeByName($opts{'encode'});
    }

    $class = ref $class if ref $class;
    $self = $class->SUPER::new($pdf,
   #    pdfkey()
   #    .('+' . $font->name())
   #    .($opts{'caps'} ? '+Caps' : '')
   #    .($opts{'pdfname'} ? '+'.$opts{'pdfname'} : '')
        $opts{'pdfname'}? $opts{'pdfname'}: 'Syn' . $font->name() . pdfkey()
    );
    $pdf->new_obj($self) unless $self->is_obj($pdf);
    $self->{' font'} = $font;
    $self->{' data'} = {
        'type' => 'Type3',
        'ascender' => $font->ascender(),
        'capheight' => $font->capheight(),
        'descender' => $font->descender(),
        'iscore' => '0',
        'isfixedpitch' => $font->isfixedpitch(),
        'italicangle' => $font->italicangle() + $oblique,
        'missingwidth' => ($font->missingwidth()||300) * $cond,
        'underlineposition' => $font->underlineposition(),
        'underlinethickness' => $font->underlinethickness(),
        'xheight' => $font->xheight(),
        'firstchar' => $first,
        'lastchar' => $last,
        'char' => [ '.notdef' ],
        'uni' => [ 0 ],
        'u2e' => { 0 => 0 },
        'fontbbox' => '',
        'wx' => { 'space' => '600' },
    };

    my $data = $self->data();
    if (ref($font->fontbbox())) {
        $data->{'fontbbox'} = [ @{$font->fontbbox()} ];
    } else {
        $data->{'fontbbox'} = [ $font->fontbbox() ];
    }
    $data->{'fontbbox'}->[0] *= $cond;
    $data->{'fontbbox'}->[2] *= $cond;

    $self->{'Subtype'} = PDFName('Type3');
    $self->{'FirstChar'} = PDFNum($first);
    $self->{'LastChar'} = PDFNum($last);
    $self->{'FontMatrix'} = PDFArray(map { PDFNum($_) } (0.001, 0, 0, 0.001, 0, 0));
    $self->{'FontBBox'} = PDFArray(map { PDFNum($_) } $self->fontbbox());

    my $procs = PDFDict();
    $pdf->new_obj($procs);
    $self->{'CharProcs'} = $procs;

    $self->{'Resources'} = PDFDict();
    $self->{'Resources'}->{'ProcSet'} = PDFArray(map { PDFName($_) } 
	                                qw(PDF Text ImageB ImageC ImageI));
    my $xo = PDFDict();
    $self->{'Resources'}->{'Font'} = $xo;
    $self->{'Resources'}->{'Font'}->{'FSN'} = $font;
    foreach my $w ($first .. $last) {
        $data->{'char'}->[$w] = $font->glyphByEnc($w);
	# possible non-standard name... use $w as Unicode value
        $data->{'uni'}->[$w] = (uniByName($data->{'char'}->[$w])) || $w;
	if (defined $data->{'uni'}->[$w]) {
            $data->{'u2e'}->{$data->{'uni'}->[$w]} = $w;
	}
    }

    if ($font->isa('PDF::Builder::Resource::CIDFont')) {
        $self->{'Encoding'} = PDFDict();
        $self->{'Encoding'}->{'Type'} = PDFName('Encoding');
        $self->{'Encoding'}->{'Differences'} = PDFArray();
        foreach my $w ($first .. $last) {
	    my $char = $data->{'char'}->[$w];
            if (defined $char && $char ne '.notdef') {
                $self->{'Encoding'}->{'Differences'}->add_elements(PDFNum($w),
			                                       PDFName($char));
            }
        }
    } else {
        $self->{'Encoding'} = $font->{'Encoding'};
    }

    my @widths;
    foreach my $w ($first .. $last) {
	# $w is the "standard encoding" (similar to Windows-1252) PDF 
	# single byte encoding. first 32 .notdef, 255 = U+00FF ydieresis
        if ($data->{'char'}->[$w] eq '.notdef') {
            push @widths, $self->missingwidth();
            next;
        }
        my $char = PDFDict();

       #my $wth = int($font->width(chr($w)) * 1000 * $cond + 2 * $space);
        my $uni = $data->{'uni'}->[$w];
	my $wth = int($font->width(chr($uni)) * 1000 * $cond + 2*$space);

        $procs->{$font->glyphByEnc($w)} = $char;
       #$char->{'Filter'} = PDFArray(PDFName('FlateDecode'));
        $char->{' stream'} = $wth." 0 ".join(' ',map { int($_) } $self->fontbbox())." d1\n";
        $char->{' stream'} .= "BT\n";
        $char->{' stream'} .= join(' ', (1, 0, tan(deg2rad($oblique)), 1, 0, 0))." Tm\n" if $oblique;
        $char->{' stream'} .= "2 Tr $bold w\n" if $bold;
       #my $ci = charinfo($data->{'uni'}->[$w]);
        my $ci = {};
  	if ($data->{'uni'}->[$w] ne '') {
    	    $ci = charinfo($data->{'uni'}->[$w]);
  	}
	
        # Small Caps
	#
        # Most Unicode characters simply don't appear in the synthetic
	# font, which is limited to 255 "standard" encoding points. encode
	# still will be single byte.
	#
	# SynFont seems to have trouble with some accented characters, even
	# though 'upper' is correct and they are in the standard encoding,
	# particularly if the string is decoded to UTF-8. Keep in mind that 
	# synfont() only creates a 255 character "standard" encoding font, so 
	# you need to apply it to each "plane" of the original font.
	#
	# Some single characters (eszett within the standard encoding, long s
	# outside it) don't have 'upper' defined and are left as-is (or
	# skipped entirely, if outside the encoding) unless first replaced by
	# ASCII lowercase ('ss' and 's' respectively). While we're at it,
	# replace certain Unicode ligatures with ASCII equivalents so they
	# will be small-capped correctly instead of ignored. Don't forget to 
	# set proper width for multi-letter replacements.
	#
	my $hasUpper = 0; # if no small caps, still need to output something
        if ($opts{'caps'}) {
	    # not all characters have an 'upper' equivalent code point. Some
	    # have U+0000 (dummy entry).
	    my $ch;
	    my $multiChar = 0;
	    $hasUpper = 1 if defined $ci->{'upper'} && $ci->{'upper'};
	    
	    if ($hasUpper) {
	        # standard upper case character and width spec'd by font
                $ch = $self->encByUni(hex($ci->{'upper'}));
                $wth = int($font->width(chr($ch)) * 800 * $cond * 1.1 + 2* $space);
	    }
	    # let's handle some special cases where !$hasUpper
	    # ($hasUpper set to 1)
	    # only characters to be substituted here, unless there is something
	    # in other encodings to deal with
	    # TBD it does not seem to be possible on non-base planes (plane 1+)
	    #     to access ASCII letters to build a substitute for ligatures
	    #     (e.g., replace U+FB01 fi ligature with F+I)
	    if      ($uni == 0xDF) {  # eszett (German sharp s)
	        $hasUpper = 1;
	        $multiChar = 1;
	        # actually, some fonts have a U+1E9E uppercase Eszett, but
	        # since that won't be in any single byte encoding, we use SS
	        $wth = 2*(int($font->width('S') * 800 * $cond*1.1 + 2*$space));
		$ch = $font->text('S').$font->text('S');
            } elsif ($uni == 0x0131) {  # dotless i
		# standard encoding doesn't see Unicode point
	        $hasUpper = 1;
	        $multiChar = 1;
	        $wth = int($font->width('I') * 800 * $cond*1.1 + 2*$space);
		$ch = $font->text('I');
            } elsif ($uni == 0x0237) {  # dotless j
		# standard encoding doesn't see Unicode point
	        $hasUpper = 1;
	        $multiChar = 1;
	        $wth = int($font->width('J') * 800 * $cond*1.1 + 2*$space);
		$ch = $font->text('J');
            }

	    if ($hasUpper) {
	        # this is a lowercase letter, etc. that has an uppercase version
	        # 80% height x 88% (110% aspect ratio @ 80% font size) width.
		# slightly wider to thicken stems and make look better.
		# $ch and $wth already set, either default or special case
                $char->{' stream'} .= "/FSN 800 Tf\n";
                $char->{' stream'} .= ($cond * 110)." Tz\n";
                $char->{' stream'} .= " [ -$space ] TJ\n" if $space;
		if ($multiChar) {
		    $ch =~ s/><//g;
		    $ch =~ s/\)\(//g;
                    $char->{' stream'} .= "$ch";
		} else {
                    $char->{' stream'} .= $font->text(chr($ch));
		}
	        # uc chr($uni) supposed to be always equivalent to 
	        # chr hex($ci->{'upper'}), according to "futuramedium"
	        # HOWEVER, uc doesn't seem to know what to do with non-ASCII chars
	        #$wth = int($font->width(uc chr($uni)) * 800 * $cond * 1.1 + 2* $space);
	        #$char->{' stream'} .= $font->text(uc chr($uni));
                #$wth = int($font->width(chr(hex($ci->{'upper'}))) * 800 * $cond * 1.1 + 2* $space);
                #$char->{' stream'} .= $font->text(chr(hex($ci->{'upper'})));
            } # else fall through to standard handling below
	} # small caps requested

	if (!$hasUpper) {
	    # Applies to all not small-caps too!
	    # does not have an uppercase ('upper') equivalent, so
	    # output at standard height and aspect ratio
            $char->{' stream'} .= "/FSN 1000 Tf\n";
            $char->{' stream'} .= ($cond * 100)." Tz\n" if $cond != 1;
            $char->{' stream'} .= " [ -$space ] TJ\n" if $space;
           #$char->{' stream'} .= $font->text(chr($w));
            $char->{' stream'} .= $font->text(chr($uni));
        }

	# finale... all modifications to font have been done
        $char->{' stream'} .= " Tj\nET ";
        push @widths, $wth;
        $data->{'wx'}->{$font->glyphByEnc($w)} = $wth;
        $pdf->new_obj($char);
    } # loop through 255 standard encoding points

#  the array as 0 elements at this point! 'space' (among others) IS defined,
#  so copy that, but TBD what kind of fallback if no such element exists?
#   $procs->{'.notdef'} = $procs->{$font->data()->{'char'}->[32]};
    $procs->{'.notdef'} = $procs->{'space'};

    $self->{'Widths'} = PDFArray(map { PDFNum($_) } @widths);
    $data->{'e2n'} = $data->{'char'};
    $data->{'e2u'} = $data->{'uni'};

    $data->{'u2c'} = {};
    $data->{'u2e'} = {};
    $data->{'u2n'} = {};
    $data->{'n2c'} = {};
    $data->{'n2e'} = {};
    $data->{'n2u'} = {};

    foreach my $n (reverse 0 .. 255) {
        $data->{'n2c'}->{$data->{'char'}->[$n] // '.notdef'} //= $n;
        $data->{'n2e'}->{$data->{'e2n'}->[$n] // '.notdef'} //= $n;

        $data->{'n2u'}->{$data->{'e2n'}->[$n] // '.notdef'} //= $data->{'e2u'}->[$n];
        $data->{'n2u'}->{$data->{'char'}->[$n] // '.notdef'} //= $data->{'uni'}->[$n];

 	if (defined $data->{'uni'}->[$n]) {
            $data->{'u2c'}->{$data->{'uni'}->[$n]} //= $n
	}
	if (defined $data->{'e2u'}->[$n]) {
            $data->{'u2e'}->{$data->{'e2u'}->[$n]} //= $n;
	    my $value = $data->{'e2n'}->[$n] // '.notdef';
            $data->{'u2n'}->{$data->{'e2u'}->[$n]} //= $value;
	}
 	if (defined $data->{'uni'}->[$n]) {
	    my $value = $data->{'char'}->[$n] // '.notdef';
            $data->{'u2n'}->{$data->{'uni'}->[$n]} //= $value;
	}
    }

    return $self;
}

1;
