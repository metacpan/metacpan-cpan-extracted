package PDF::Builder::Resource::Font::SynFont;

use base 'PDF::Builder::Resource::Font';

use strict;
no warnings qw[ deprecated recursion uninitialized ];

our $VERSION = '3.017'; # VERSION
my $LAST_UPDATE = '3.017'; # manually update whenever code is changed

use Math::Trig;    # CAUTION: deg2rad(0) = deg2rad(360) = 0!
use Unicode::UCD 'charinfo';

use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;

=head1 NAME

PDF::Builder::Resource::Font::SynFont - Module for using synthetic Fonts.

=head1 SYNOPSIS

    #
    use PDF::Builder;
    #
    $pdf = PDF::Builder->new();
    $cft = $pdf->corefont('Times-Roman');  # ttfont, etc. also works
    $sft = $pdf->synfont($cft, -condense => .75);  # condense by 25%
    #

This works for I<corefonts>, I<PS fonts>, and I<TTF/OTF fonts>; but does not
work for I<CJK fonts> or I<bitmapped fonts>.
See also L<PDF::Builder::Docs/Synthetic Fonts>.

=head1 METHODS

=over 4

=cut

=item $font = PDF::Builder::Resource::Font::SynFont->new($pdf, $fontobj, %options)

Returns a synfont object.

=cut

=pod

Valid %options are:

I<-encode>
... changes the encoding of the font from its default.
See I<Perl's Encode> for the supported values. B<Warning:> only single byte
encodings are supported. Multibyte encodings such as UTF-8 are invalid.

I<-pdfname>
... changes the reference-name of the font from its default.
The reference-name is normally generated automatically and can be
retrieved via $pdfname=$font->name().

I<-condense>
... condense/expand factor (0.1-0.9 = condense, 1 = normal, 1.1+ = expand).
It's the multiplier for character widths vs. normal.

I<-slant>
... B<DEPRECATED>, will be removed. Use C<-condense> instead.

I<-oblique>
... italic angle (+/-) in degrees, where the character box is skewed. While 
it's unlikely that anyone will want to slant characters at +/-360 degrees, they 
should be aware that these will be treated as an angle of 0 degrees (deg2rad() 
wraps around). 0 degrees of italic slant (obliqueness) is the default.

I<-bold>
... embolding factor (0.1+, bold=1, heavy=2, ...). It is additional outline
B<thickness> (B<linewidth>), which expands the character outwards.

I<-space>
... additional charspacing in em (0-1000).

I<-caps>
... create synthetic small-caps. 0 = no, 1 = yes. These are capitals of 
lowercase letters, at 80% height and 88% width.

=back

=cut

sub new
{
    my ($class, $pdf, $font, @opts) = @_;

    my ($self, $data);
    my %opts = @opts;
    my $first = 1;
    my $last = 255;
    # TBD after January 2021 remove -slant
    my $cond = $opts{'-condense'} || $opts{'-slant'} || 1;
    my $oblique = $opts{'-oblique'} || 0;
    my $space = $opts{'-space'} || '0';
    my $bold = ($opts{'-bold'} || 0)*10; # convert to em
   #   -caps

    # 5 elements apparently not used anywhere
   #$self->{' cond'} = $cond;
   #$self->{' oblique'} = $oblique;
   #$self->{' bold'} = $bold;
   #$self->{' boldmove'} = 0.001;
   #$self->{' space'} = $space;
    # only available in TT fonts. besides, multibyte encodings not supported
    if (defined $opts{'-encode'}) {
        if ($opts{'-encode'} =~ m/^utf/i) {
	    die "Invalid multibyte encoding for synfont: $opts{'-encode'}\n";
	    # probably more encodings to check
        }
        $font->encodeByName($opts{'-encode'});
    }

    $class = ref $class if ref $class;
    $self = $class->SUPER::new($pdf,
        pdfkey()
        .('+' . $font->name())
        .($opts{'-caps'} ? '+Caps' : '')
        .($opts{'-pdfname'} ? '+'.$opts{'-pdfname'} : '')
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
        'missingwidth' => $font->missingwidth() * $cond,
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

    if (ref($font->fontbbox())) {
        $self->data()->{'fontbbox'} = [ @{$font->fontbbox()} ];
    } else {
        $self->data()->{'fontbbox'} = [ $font->fontbbox() ];
    }
    $self->data()->{'fontbbox'}->[0] *= $cond;
    $self->data()->{'fontbbox'}->[2] *= $cond;

    $self->{'Subtype'} = PDFName('Type3');
    $self->{'FirstChar'} = PDFNum($first);
    $self->{'LastChar'} = PDFNum($last);
    $self->{'FontMatrix'} = PDFArray(map { PDFNum($_) } ( 0.001, 0, 0, 0.001, 0, 0 ) );
    $self->{'FontBBox'} = PDFArray(map { PDFNum($_) } ( $self->fontbbox() ) );

    my $procs = PDFDict();
    $pdf->new_obj($procs);
    $self->{'CharProcs'} = $procs;

    $self->{'Resources'} = PDFDict();
    $self->{'Resources'}->{'ProcSet'} = PDFArray(map { PDFName($_) } qw[ PDF Text ImageB ImageC ImageI ]);
    my $xo = PDFDict();
    $self->{'Resources'}->{'Font'} = $xo;
    $self->{'Resources'}->{'Font'}->{'FSN'} = $font;
    foreach my $w ($first .. $last) {
        $self->data()->{'char'}->[$w] = $font->glyphByEnc($w);
        $self->data()->{'uni'}->[$w] = uniByName($self->data()->{'char'}->[$w]);
        $self->data()->{'u2e'}->{$self->data()->{'uni'}->[$w]} = $w;
    }

    if ($font->isa('PDF::Builder::Resource::CIDFont')) {
        $self->{'Encoding'} = PDFDict();
        $self->{'Encoding'}->{'Type'} = PDFName('Encoding');
        $self->{'Encoding'}->{'Differences'} = PDFArray();
        foreach my $w ($first .. $last) {
            if (defined $self->data()->{'char'}->[$w] && 
		$self->data()->{'char'}->[$w] ne '.notdef') {
                $self->{'Encoding'}->{'Differences'}->add_elements(PDFNum($w),PDFName($self->data()->{'char'}->[$w]));
            }
        }
    } else {
        $self->{'Encoding'} = $font->{'Encoding'};
    }

    my @widths = ();
    foreach my $w ($first .. $last) {
	# $w is the "standard encoding" (similar to Windows-1252) PDF 
	# single byte encoding. first 32 .notdef, 255 = U+00FF ydieresis
        if ($self->data()->{'char'}->[$w] eq '.notdef') {
            push @widths, $self->missingwidth();
            next;
        }
        my $char = PDFDict();

       #my $wth = int($font->width(chr($w)) * 1000 * $cond + 2 * $space);
        my $uni = $self->data()->{'uni'}->[$w];
	    my $wth = int($font->width(chr($uni)) * 1000 * $cond + 2*$space);

        $procs->{$font->glyphByEnc($w)} = $char;
       #$char->{'Filter'} = PDFArray(PDFName('FlateDecode'));
        $char->{' stream'} = $wth." 0 ".join(' ',map { int($_) } $self->fontbbox())." d1\n";
        $char->{' stream'} .= "BT\n";
        $char->{' stream'} .= join(' ', 1, 0, tan(deg2rad($oblique)), 1, 0, 0)." Tm\n" if $oblique;
        $char->{' stream'} .= "2 Tr ".($bold)." w\n" if $bold;
       #my $ci = charinfo($self->data()->{'uni'}->[$w]);
        my $ci = {};
  	if ($self->data()->{'uni'}->[$w] ne '') {
    	    $ci = charinfo($self->data()->{'uni'}->[$w]);
  	}
	
        # Small Caps
	#
        # Most Unicode characters simply don't appear in the synthetic
	# font, which is limited to 255 "standard" encoding points. -encode
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
        if ($opts{'-caps'}) {
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
        $char->{' stream'} .= " Tj\nET\n";
        push @widths, $wth;
        $self->data()->{'wx'}->{$font->glyphByEnc($w)} = $wth;
        $pdf->new_obj($char);
    } # loop through 255 standard encoding points

    $procs->{'.notdef'} = $procs->{$font->data()->{'char'}->[32]};
    $self->{'Widths'} = PDFArray(map { PDFNum($_) } @widths);
    $self->data()->{'e2n'} = $self->data()->{'char'};
    $self->data()->{'e2u'} = $self->data()->{'uni'};

    $self->data()->{'u2c'} = {};
    $self->data()->{'u2e'} = {};
    $self->data()->{'u2n'} = {};
    $self->data()->{'n2c'} = {};
    $self->data()->{'n2e'} = {};
    $self->data()->{'n2u'} = {};

    foreach my $n (reverse 0 .. 255) {
        $self->data()->{'n2c'}->{$self->data()->{'char'}->[$n] || '.notdef'} = 
	  $n unless defined $self->data()->{'n2c'}->{$self->data()->{'char'}->[$n] || '.notdef'};
        $self->data()->{'n2e'}->{$self->data()->{'e2n'}->[$n] || '.notdef'} =
	  $n unless defined $self->data()->{'n2e'}->{$self->data()->{'e2n'}->[$n] || '.notdef'};

        $self->data()->{'n2u'}->{$self->data()->{'e2n'}->[$n] || '.notdef'} =
	  $self->data()->{'e2u'}->[$n] unless defined $self->data()->{'n2u'}->{$self->data()->{'e2n'}->[$n] || '.notdef'};
        $self->data()->{'n2u'}->{$self->data()->{'char'}->[$n] || '.notdef'} =
	  $self->data()->{'uni'}->[$n] unless defined $self->data()->{'n2u'}->{$self->data()->{'char'}->[$n] || '.notdef'};

        $self->data()->{'u2c'}->{$self->data()->{'uni'}->[$n]} =
	  $n unless defined $self->data()->{'u2c'}->{$self->data()->{'uni'}->[$n]};
        $self->data()->{'u2e'}->{$self->data()->{'e2u'}->[$n]} =
	  $n unless defined $self->data()->{'u2e'}->{$self->data()->{'e2u'}->[$n]};

        $self->data()->{'u2n'}->{$self->data()->{'e2u'}->[$n]} =
	  ($self->data()->{'e2n'}->[$n] || '.notdef') unless defined $self->data()->{'u2n'}->{$self->data()->{'e2u'}->[$n]};
        $self->data()->{'u2n'}->{$self->data()->{'uni'}->[$n]} =
	  ($self->data()->{'char'}->[$n] || '.notdef') unless defined $self->data()->{'u2n'}->{$self->data()->{'uni'}->[$n]};
    }

    return $self;
}

1;
