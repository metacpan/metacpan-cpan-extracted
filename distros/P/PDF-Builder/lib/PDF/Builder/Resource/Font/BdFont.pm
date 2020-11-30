package PDF::Builder::Resource::Font::BdFont;

use base 'PDF::Builder::Resource::Font';

use strict;
no warnings qw[ deprecated recursion uninitialized ];

our $VERSION = '3.020'; # VERSION
my $LAST_UPDATE = '3.017'; # manually update whenever code is changed

use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;

our $BmpNum = 0;

=head1 NAME

PDF::Builder::Resource::Font::BdFont - Module for using bitmapped Fonts.

=head1 SYNOPSIS

    #
    use PDF::Builder;
    #
    $pdf = PDF::Builder->new();
    $sft = $pdf->bdfont($file);
    #

This creates a bitmapped font from a .bdf (bitmap distribution font) file.
The default is to use square elements, and the style can be changed to use
filled dots (looking more like a dot-matrix printer). The font will be 
embedded in the PDF file.

Bitmapped fonts are quite rough, low resolution, and difficult to read, so 
unless you're a sadist who wants to force readers back to the good old days of 
dot-matrix printers and bitmapped X terminals, try to limit the use of such a
font to decorative or novelty effects, such as chapter titles and major 
headings. Have mercy on your readers and use a real font (TrueType, etc.) 
for body text!

=head1 METHODS

=over 4

=cut

=item $font = PDF::Builder::Resource::Font::BdFont->new($pdf, $font, %options)

=item $font = PDF::Builder::Resource::Font::BdFont->new($pdf, $font)

Returns a BmpFont object.

=cut

#I<-encode>
#... changes the encoding of the font from its default.
#See I<Perl's Encode> for the supported values.
#
=pod

Valid %options are:

I<-pdfname> ... changes the reference-name of the font from its default.
The reference-name is normally generated automatically and can be
retrieved via C<$pdfname=$font->name()>.

I<-style> ... a value of 'block' (default) assembles a character from
contiguous square blocks. A value of 'dot' assembles a character from 
overlapping filled circles, in the style of a dot matrix printer.

=cut
# -style => 'image' doesn't seem to want to work (see examples/024_bdffonts
# for code). it's not clear whether a 1000 x 1000 pixel bitmap needs to be
# generated, to be scaled down to the text size. if so, that's very wasteful.

sub new {
    my ($class, $pdf, $file, %opts) = @_;

    my ($self, $data);
    my $dot_ratio = 1.2;  # diameter of a dot (dot style) relative to
                          # a block's side. note that if exceeds 1.0, max
			  # extents of dot will actually slightly exceed
			  # extents of block. TBD might need to have different
			  # calculations of max extents for block and dot.

    $class = ref $class if ref $class;
    $self = $class->SUPER::new($pdf, sprintf('%s+Bdf%02i', pdfkey(), ++$BmpNum));
    $pdf->new_obj($self) unless $self->is_obj($pdf);

    # Adobe bitmap distribution format
    $self->{' data'} = $self->readBDF($file);

    # character coordinate units for block and dots styles (cell sizes)
    my ($csizeH, $csizeV);
    # at this point we need to find the actual cell bounds (after adding
    # in right and up offsets), in order to define 1000 units vertical
    # $self->{' data'}->{'FONTBOUNDINGBOX'} is a string
    my ($minX, $minY, $maxX, $maxY); # for final 'fontbbox' numbers
    $minX = $minY =  10000;
    $maxX = $maxY = -10000;
    foreach my $w (@{$self->data()->{'char2'}}) {
        my @bbx = @{$w->{'BBX'}};
        my $LLx = $bbx[2];
        my $LLy = $bbx[3];
        my $URx = $bbx[0]+$bbx[2];
        my $URy = $bbx[1]+$bbx[3];
        if ($LLx < $minX) { $minX = $LLx; }
        if ($LLx > $maxX) { $maxX = $LLx; }
        if ($URx < $minX) { $minX = $URx; }
        if ($URx > $maxX) { $maxX = $URx; }
        if ($LLy < $minY) { $minY = $LLy; }
        if ($LLy > $maxY) { $maxY = $LLy; }
        if ($URy < $minY) { $minY = $URy; }
        if ($URy > $maxY) { $maxY = $URy; }
    }
    # for now, same cell dimensions in X and Y
    $csizeH = $csizeV = int(0.5 + 1000/($maxY + 1));

    my $first = 0; # we'll always do the full single byte encoding
    my $last = 255;
    $opts{'-style'} = 'block' unless defined $opts{'-style'};

    $self->{'Subtype'} = PDFName('Type3');
    $self->{'FirstChar'} = PDFNum($first);
    $self->{'LastChar'} = PDFNum($last);
    # define glyph drawings on 1000x1000 grid, divide by 1000, multiply by 
    #  font size in points
    $self->{'FontMatrix'} = PDFArray(map { PDFNum($_) } (0.001, 0, 0, 0.001, 0, 0) );
    if (defined $self->{' data'}->{'FONT'}) {
        $self->{'Comment'} = PDFString("FontName=" . $self->{' data'}->{'FONT'}, 'x');
    }

    my $xo = PDFDict();
    $self->{'Encoding'} = $xo;
    $xo->{'Type'} = PDFName('Encoding');
    $xo->{'BaseEncoding'} = PDFName('WinAnsiEncoding');
    # assign .notdef "char" to anything not found in the .bdf file
    $xo->{'Differences'} = PDFArray(PDFNum($first), (map { PDFName($_ || '.notdef') } @{$self->data()->{'char'}}));

    my $procs = PDFDict();
    $pdf->new_obj($procs);
    $self->{'CharProcs'} = $procs;

    $self->{'Resources'} = PDFDict();
    $self->{'Resources'}->{'ProcSet'} = PDFArray(map { PDFName($_) } qw(PDF Text ImageB ImageC ImageI));
    foreach my $w ($first .. $last) {
        $self->data()->{'uni'}->[$w] = uniByName($self->data()->{'char'}->[$w]);
        $self->data()->{'u2e'}->{$self->data()->{'uni'}->[$w]} = $w;
    }
    my @widths = ();
    foreach my $w (@{$self->data()->{'char2'}}) {
        # some .bdf files have a grid that is 10000 wide, not 1000. want to
        #  end up with a fraction (typically less than 1.0) of font size
        #  after scaling in FontMatrix (/1000).
        if ($self->data()->{'wx'}->{$w->{'NAME'}} > 2500) {
            $self->data()->{'wx'}->{$w->{'NAME'}} /= 10;
        }
        if ($self->data()->{'wx'}->{$w->{'NAME'}} == 0) {
            $self->data()->{'wx'}->{$w->{'NAME'}} = $self->{'missingwidth'} || 100;
        }
        $widths[$w->{'ENCODING'}] = $self->data()->{'wx'}->{$w->{'NAME'}};
        my @bbx = @{ $w->{'BBX'} };
        my @BBX = @bbx;
        # if no pattern (e.g., space) give a 0000 pattern to avoid pack problem
        $w->{'hex'} = '0000' if !defined $w->{'hex'};

        my $char = PDFDict();
        # [0] width 1000*fraction wide (approx) = aspect ratio
        # [1] 0 y +/- move to next character?
        # [2..3] lower left extent of glyph, can be to left of origin point
        # [4..5] upper right extent of glyph + trailing space
        #  make sure width is at least 105% of max x
        if ($widths[$w->{'ENCODING'}] < 1.05*($bbx[0]+$bbx[2])*$csizeH) {
            $widths[$w->{'ENCODING'}] = int(0.5 + 1.05*($bbx[0]+$bbx[2])*$csizeH);
        }
        my $LLx = int($bbx[2]*$csizeH + 0.5);
        my $LLy = int($bbx[3]*$csizeV + 0.5);
        my $URx = int(($bbx[0]+$bbx[2])*$csizeH + 0.5);
        my $URy = int(($bbx[1]+$bbx[3])*$csizeV + 0.5);
        $char->{' stream'} = $widths[$w->{'ENCODING'}] . " 0 $LLx $LLy $URx $URy d1\n"; 
        $char->{'Comment'} = PDFString("N='" . $w->{'NAME'} . "' C=" . $w->{'ENCODING'}, 'x');
        $procs->{$w->{'NAME'}} = $char;
        @bbx = map { $_ * 1000 / $self->data()->{'upm'} } @bbx;

        # Reader will save graphics state (q) and restore (Q) around each
        # glyph's drawing commands
        if ($opts{'-style'} eq 'image') {
            # note that each character presented as an image
            # CAUTION: using this image code for a font doesn't seem to work
            # well. block and dot look quite nice, so for now, use one of those.
            my $stream = pack('H*', $w->{'hex'});
            my $y = $BBX[1]; # vertical dimension of character (pixels)

            if ($y == 0) {
                $char->{' stream'} .= " ";
            } else {
                my $x = 8 * length($stream) / $y; 
                my $img = qq|BI\n/Interpolate false/Decode [1 0]/H $y/W $x/BPC 1/CS/G\nID $stream\nEI|;
                $procs->{$self->data()->{'char'}->[$w]} = $char;
                # BBX.0 is character width in pixels, BBX.1 is height in pixels
                # BBX.2 is offset to right in pixels, BBX.3 is offset up in pixels
                $char->{' stream'} .= "q $BBX[0] 0 0 $BBX[1] $BBX[2] $BBX[3] cm\n$img\nQ";
            }
            # entered as Type 3 font character
            # n 0 obj << /Length nn >> stream
            # width 0 d0   # mils
            # q xsize 0 0 ysize xoffset yoffset cm
            # BI
            # /Interpolate false/Decode[1 0]/H pixh/W pixw/BPC 1/CS/G
            # ID binary_data stream
            # EI
            # Q
            # endstream endobj
	     
        } else {
	    # common code for dot and block styles
            if ($BBX[1] == 0) {
                # empty character, such as a space
                $char->{' stream'} .= " ";
            } else {
                my @dots = (); # rows of pixels [0] at bottom (min y), 
                               # each row is array of pixels across
                # BBX[1] is number of chunks in 'hex', each 2, 4, 6 nybbles
                #   (not sure if can exceed 8 pixels across...)
                # BBX[0] is width in pixels (8 to a byte) across 'hex'
                my $bytesPerRow = int(($BBX[0]+7)/8); # 2 nybbles each
                for (my $row=0; $row<$BBX[1]; $row++) {
                    unshift @dots, [ split //, substr(unpack('B*', pack('H*', substr($w->{'hex'}, $row*2, $bytesPerRow*2))), 0, $BBX[0]) ];
                }
                # dots[r][c] is 1 if want pixel there (0,0 at bottom/left)

                for (my $row=0; $row<$BBX[1]; $row++) {
                    for (my $col=0; $col<$BBX[0]; $col++) {
                        if (!$dots[$row][$col]) { next; }

                        if ($opts{'-style'} eq 'block') {
                            # TBD merge neighbors to form larger rectangles
                            $char->{' stream'} .= int(($col+$BBX[2])*$csizeH+0.5).' '.
                                                  int(($row+$BBX[3])*$csizeV+0.5).' '.
                                                  int($csizeH+0.5).' '.
                                                  int($csizeV+0.5).' '.
                                                  're f ';
                        } else {
                            # dots
                            $char->{' stream'} .= filled_circle(
                                ($col+$BBX[2]+0.5)*$csizeH,  # Xc
                                ($row+$BBX[3]+0.5)*$csizeV,  # Yc
                                $csizeH*$dot_ratio/2 );      # r
                        }
                    }
                    $char->{' stream'} .= "\n";
                }
            }
        } # block and dot styles

        $pdf->new_obj($char);
        # .notdef is treated as a space
        $procs->{'.notdef'} = $procs->{$self->data()->{'char'}->[32]};
        delete $procs->{''};
    } # loop through all defined characters in BDF file

    # correct global fontbbox and output after seeing all glyph 'd1' LL UR limits
    my @fbb = ( $self->fontbbox() );
    $fbb[0] = $minX*$csizeH; 
    $fbb[1] = $minY*$csizeV; 
    $fbb[2] = $maxX*$csizeH; 
    $fbb[3] = $maxY*$csizeV;
    $self->{'FontBBox'} = PDFArray(map { PDFNum($_) } @fbb );

    $self->{'Widths'} = PDFArray(map { PDFNum($widths[$_] || $self->{' data'}->{'missingwidth'} || 100) } ($first .. $last));
    $self->data()->{'e2n'} = $self->data()->{'char'};
    $self->data()->{'e2u'} = $self->data()->{'uni'};

    $self->data()->{'u2c'} = {};
    $self->data()->{'u2e'} = {};
    $self->data()->{'u2n'} = {};
    $self->data()->{'n2c'} = {};
    $self->data()->{'n2e'} = {};
    $self->data()->{'n2u'} = {};

    foreach my $n (reverse 0 .. 255) {
        $self->data()->{'n2c'}->{$self->data()->{'char'}->[$n] || '.notdef'} = $n unless defined $self->data()->{'n2c'}->{$self->data()->{'char'}->[$n] || '.notdef'};
        $self->data()->{'n2e'}->{$self->data()->{'e2n'}->[$n] || '.notdef'} = $n unless defined $self->data()->{'n2e'}->{$self->data()->{'e2n'}->[$n] || '.notdef'};

        $self->data()->{'n2u'}->{$self->data()->{'e2n'}->[$n] || '.notdef'} = $self->data()->{'e2u'}->[$n] unless defined $self->data()->{'n2u'}->{$self->data()->{'e2n'}->[$n] || '.notdef'};
        $self->data()->{'n2u'}->{$self->data()->{'char'}->[$n] || '.notdef'} = $self->data()->{'uni'}->[$n] unless defined $self->data()->{'n2u'}->{$self->data()->{'char'}->[$n] || '.notdef'};

        $self->data()->{'u2c'}->{$self->data()->{'uni'}->[$n]} = $n unless defined $self->data()->{'u2c'}->{$self->data()->{'uni'}->[$n]};
        $self->data()->{'u2e'}->{$self->data()->{'e2u'}->[$n]} = $n unless defined $self->data()->{'u2e'}->{$self->data()->{'e2u'}->[$n]};

        $self->data()->{'u2n'}->{$self->data()->{'e2u'}->[$n]} = ($self->data()->{'e2n'}->[$n] || '.notdef') unless(defined $self->data()->{'u2n'}->{$self->data()->{'e2u'}->[$n]});
        $self->data()->{'u2n'}->{$self->data()->{'uni'}->[$n]}=($self->data()->{'char'}->[$n] || '.notdef') unless(defined $self->data()->{'u2n'}->{$self->data()->{'uni'}->[$n]});
    }

    return $self;
}

sub readBDF {
    my ($self, $file) = @_;
    my $data = {};
    $data->{'char'} = [];
    $data->{'char2'} = [];
    $data->{'wx'} = {};

    if (! -e $file) {
	die "BDF file='$file' not found.";
    }
    open(my $afmf, "<", $file) or die "Can't open the BDF file for $file";
    local($/, $_) = ("\n", undef);  # ensure correct $INPUT_RECORD_SEPARATOR
    while ($_ = <$afmf>) {
        chomp($_);
        if (/^STARTCHAR/ .. /^ENDCHAR/) {
            if (/^STARTCHAR\s+(\S+)/) {
                my $name = $1;
                $name =~ s|^(\d+.*)$|X_$1|;
                push @{$data->{'char2'}}, {'NAME' => $name};
            } elsif (/^BITMAP/ .. /^ENDCHAR/) {
                next if(/^BITMAP/);
                if (/^ENDCHAR/) {
                    $data->{'char2'}->[-1]->{'NAME'} ||= 'E_'.$data->{'char2'}->[-1]->{'ENCODING'};
                    $data->{'char'}->[$data->{'char2'}->[-1]->{'ENCODING'}] = $data->{'char2'}->[-1]->{'NAME'};
                    ($data->{'wx'}->{$data->{'char2'}->[-1]->{'NAME'}}) = split(/\s+/, $data->{'char2'}->[-1]->{'SWIDTH'});
                    $data->{'char2'}->[-1]->{'BBX'} = [split(/\s+/, $data->{'char2'}->[-1]->{'BBX'})];
                } else {
                    $data->{'char2'}->[-1]->{'hex'} .= $_;
                }
            } else {
                m|^(\S+)\s+(.+)$|;
                $data->{'char2'}->[-1]->{uc($1)} .= $2;
            }
        ## } elsif (/^STARTPROPERTIES/ .. /^ENDPROPERTIES/) {
        } else {
                m|^(\S+)\s+(.+)$|;
                $data->{uc($1)} .= $2;
        }
    }
    close($afmf);
    unless (exists $data->{'wx'}->{'.notdef'}) {
        $data->{'wx'}->{'.notdef'} = $data->{'missingwidth'} || 100;
        $data->{'bbox'}{'.notdef'} = [0, 0, 0, 0];
    }

    $data->{'fontname'} = "BdfF+" . pdfkey();
    $data->{'apiname'} = $data->{'fontname'};
    $data->{'flags'} = 34;
    # initial value of fontbbox is FONTBOUNDINGBOX entry, e.g., 6 13 0 -3
    #  equals 6 columns, 13 rows, 0 min right offset, -3 min up offset
    $data->{'fontbbox'} = [split(/\s+/, $data->{'FONTBOUNDINGBOX'})];
    # upm e.g., 15 (if not set, rows-min up offset 13-(-3) = 16)
    # I don't think this is screen px, but count of vertical elements in glyph
    $data->{'upm'} = $data->{'PIXEL_SIZE'} || ($data->{'fontbbox'}->[1] - $data->{'fontbbox'}->[3]);
    # not sure what this is trying to do. 1000/vertical cell count would be
    #  vertical (and horizontal) cell size, within 1000 grid? multiply cell
    #  locations by cell size to get grid locations?
    @{$data->{'fontbbox'}} = map { int($_*1000/$data->{'upm'}) } @{$data->{'fontbbox'}};
    # at this point, fontbbox is scaled cols/rows and min right/up. what goes
    #  in /FontBBox should be LL UR scaled values (including offsets)

    foreach my $n (0 .. 255) {
        $data->{'char'}->[$n] ||= '.notdef';
    }

    $data->{'uni'} ||= [];
    foreach my $n (0 .. 255) {
        $data->{'uni'}->[$n] = uniByName($data->{'char'}->[$n] || '.notdef') || 0;
    }
    $data->{'ascender'} = $data->{'RAW_ASCENT'}
        || int($data->{'FONT_ASCENT'} * 1000 / $data->{'upm'});
    $data->{'descender'} = $data->{'RAW_DESCENT'}
        || int($data->{'FONT_DESCENT'} * 1000 / $data->{'upm'});

    $data->{'type'} = 'Type3';
    $data->{'capheight'} = 1000;
    $data->{'iscore'} = 0;
    $data->{'issymbol'} = 0;
    $data->{'isfixedpitch'} = 0;
    $data->{'italicangle'} = 0;
    $data->{'missingwidth'} = $data->{'AVERAGE_WIDTH'}
        || int($data->{'FONT_AVERAGE_WIDTH'} * 1000 / $data->{'upm'})
        || $data->{'RAW_AVERAGE_WIDTH'}
        || 500;
    $data->{'underlineposition'} = -200;
    $data->{'underlinethickness'} = 10;
    $data->{'xheight'} = $data->{'RAW_XHEIGHT'}
        || int($data->{'FONT_XHEIGHT'} * 1000 / $data->{'upm'})
        || int($data->{'ascender'} / 2);
    $data->{'firstchar'} = 0;
    $data->{'lastchar'} = 255;

    delete $data->{'wx'}->{''};

    return $data;
}

# draw a filled circle centered at $Xc,$Yc, of radius $r
# returns string of PDF primitives
sub filled_circle {
    # this algorithm from stackoverflow by Marius (questions/1960786)
    my ($Xc, $Yc, $r) = @_;
    my $out = '';  # output string

    # line thickness 2 x radius
    $out .= " " . (2*$r) . " w";
    # line cap round
    $out .= " 1 J";
    # draw 0-length line at center
    $out .= " $Xc $Yc m $Xc $Yc l";
    # stroke line
    $out .= " S";

    return $out;
} # end filled_circle()

1;

__END__

=back

=head1 AUTHOR

alfred reibenschuh

=cut
