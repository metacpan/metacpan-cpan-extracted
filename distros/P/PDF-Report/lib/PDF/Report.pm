package PDF::Report;
use strict;

=head1 NAME

PDF::Report - A wrapper written for PDF::API2

=head1 SYNOPSIS

	use PDF::Report;

    my $pdf = new PDF::Report(%opts);

=head1 DESCRIPTION

This is a wrapper for Alfred Reibenschuh's PDF::API2
Defines methods to create PDF reports

=head1 VERSION

 1.36

=cut

our $VERSION = "1.36";

use strict;
use PDF::API2;

### GLOBAL SECTION ############################################################
# Sane defaults
my %DEFAULTS;
$DEFAULTS{PageSize}='letter';
$DEFAULTS{PageOrientation}='Portrait';
$DEFAULTS{Compression}=1;
$DEFAULTS{PdfVersion}=3;
$DEFAULTS{marginX}=30;
$DEFAULTS{marginY}=30;
$DEFAULTS{font}="Helvetica";
$DEFAULTS{size}=12;

# Document info
my @parameterlist=qw(
        PageSize
        PageWidth
        PageHeight
        PageOrientation
        Compression
        PdfVersion
);
### END GLOBALS ###############################################################

### GLOBAL SUBS ###############################################################

=head1 METHODS

=head2 new

my $pdf = new PDF::Report(%opts);

	Creates a new pdf report object.
        If no %opts are specified the module
        will use the factory defaults.

B<Example:>

	my $pdf = new PDF::Report(PageSize => "letter",
                                  PageOrientation => "Landscape");

        my $pdf = new PDF::Report(File => $file);

%opts:

        PageSize - '4A', '2A', 'A0', 'A1', 'A2',
                   'A3', 'A4', 'A5', 'A6', '4B',
                   '2B', 'B0', 'B1', 'B2', 'B3',
                   'B4', 'B5', 'B6', 'LETTER',
                   'BROADSHEET', 'LEDGER', 'TABLOID',
                   'LEGAL', 'EXECUTIVE', '36X36'

	PageOrientation - 'Portrait', 'Landscape'

=cut

# Create a new PDF document
sub new {
  my $class    = shift;
  my %defaults = @_;

  foreach my $dflt (@parameterlist) {
    if (defined($defaults{$dflt})) {
      $DEFAULTS{$dflt} = $defaults{$dflt}; # Overridden from user
    }
  }

  my $pageWidth;
  my $pageHeight;
  my $x1;
  my $y1;
  if ( ref $DEFAULTS{PageSize} eq "ARRAY" ) {
    ($pageWidth, $pageHeight) = @{$DEFAULTS{PageSize}};
  }
  else {
    # Set the width and height of the page
    ($x1, $y1, $pageWidth, $pageHeight) =
    PDF::API2::Util::page_size($DEFAULTS{PageSize});
  }

  # Swap w and h if landscape
  if (lc($DEFAULTS{PageOrientation})=~/landscape/) {
    my $tempW = $pageWidth;
    $pageWidth = $pageHeight;
    $pageHeight = $tempW;
    $tempW = undef;
  }

  my $MARGINX = $DEFAULTS{marginX};
  my $MARGINY = $DEFAULTS{marginY};
  my ( $day, $month, $year )= ( localtime( time ) )[3..5];
  my $DATE=sprintf "%02d/%02d/%04d", ++$month, $day, 1900 + $year;

  # May not need alot of these, will review later
  my $self= { #pdf          => PDF::API2->new(),
              hPos         => undef,
              vPos         => undef,
              size         => 12,    # Default
              font         => undef, # the font object
              PageWidth    => $pageWidth,
              PageHeight   => $pageHeight,
              Xmargin      => $MARGINX,
              Ymargin      => $MARGINY,
              BodyWidth    => $pageWidth - $MARGINX * 2,
              BodyHeight   => $pageHeight - $MARGINY * 2,
              page         => undef, # the current page object
              page_nbr     => 1,
              align        => 'left',
              linewidth    => 1,
              linespacing  => 0,
              FtrFontName  => 'Helvetica-Bold',
              FtrFontSize  => 11,
              MARGIN_DEBUG => 0,
              PDF_API2_VERSION => $PDF::API2::VERSION,
              INFO => {
                Creator => "None",
                Producer => "None",
                CreationDate => $DATE,
                Title => "Untitled",
                Subject => "None",
                Author => "Auto-generated",
              },

              ########################################################
              # Cache for font object caching -- used by setFont() ###
              ########################################################
              __font_cache => {},
            DATE => $DATE,
            };

  if (defined $defaults{File} && length($defaults{File})) {
    $self->{pdf} = PDF::API2->open($defaults{File})
                     or die "$defaults{File} not found: $!\n";
  } else {
    $self->{pdf} = PDF::API2->new();
  }

  # Default fonts
  $self->{font} = $self->{pdf}->corefont('Helvetica'); # Default font object
  #$self->{font}->encode('latin1');

  # Set the users options
  foreach my $key (keys %defaults) {
    $self->{$key}=$defaults{$key};
  }

  bless $self, $class;

  return $self;
}

=head2 newpage

$pdf->newpage($nopage);

Creates a new blank page.  Pass $nopage = 1 to toggle page numbering.

=cut

sub newpage {
  my $self = shift;
  my $no_page_number = shift;

  # make a new page
  $self->{page} = $self->{pdf}->page;
  $self->{page}->mediabox($self->{PageWidth}, $self->{PageHeight});

  # Handle the page numbering if this page is to be numbered
  my $total = $self->pages;
  push(@{$self->{no_page_num}}, $no_page_number);

  $self->{page_nbr}++;
  return(0);
}

=head2 openpage

$pdf->openpage($index);

If no index is specified, this will open the last page of the document.

=cut


sub openpage {
  my $self = shift;
  my $index = shift;
  my $totpgs = $self->{pdf}->pages;

  $index = $totpgs if (!defined $index or
                       $index =~ /[^\d]/ or
                       $index > $totpgs);

  $self->{page} = $self->{pdf}->openpage($index);
}

=head2 importpage

Import page from another PDF document, see PDF::API2

=cut

sub importpage {
  my $self = shift;
  my $sourcepdf = shift;
  my $sourceindex = shift;
  my $targetindex = shift;  # can be a page object

#  my $source = $self->{pdf}->open($sourcepdf);

  $self->{page} = $self->{pdf}->importpage($sourcepdf, $sourceindex,
                                           $targetindex);
}

=head2 clonepage

Clone page within document, see PDF::API2

=cut


sub clonepage {
  my $self = shift;
  my $sourceindex = shift;
  my $targetindex = shift;

  $self->{page} = $self->{pdf}->clonepage($sourceindex, $targetindex);

}

=head2 getPageDimensions

($pagewidth, $pageheight) = $pdf->getPageDimensions();

Returns the width and height of the page according to what page size chosen
in "new".

=cut

sub getPageDimensions {
  my $self = shift;

   return($self->{PageWidth}, $self->{PageHeight});
}

=head2 addRawText

$pdf->addRawText($text, $x, $y, $color, $underline, $indent, $rotate);

Add $text at position $x, $y with $color, $underline, $indent and/or $rotate.

=cut

# This positions string $text at $x, $y
sub addRawText {
  my ( $self, $text, $x, $y, $color, $underline, $indent, $rotate ) = @_;

  $color = undef if defined $color && !length($color);
  $underline = undef if defined $underline && !length($underline);
  $indent = undef if defined $indent && !length($indent);

  my $txt = $self->{page}->text;
#  $txt->font($self->{font}, $self->{size});
#  $txt->transform_rel(-translate => [$x, $y], -rotate => $rotate);
#  $txt->text($text, -color=>[$color], -underline=>$underline,
#                          -indent=>$indent);

  $txt->textlabel($x, $y, $self->{font}, $self->{size}, $text,
                  -rotate => $rotate,
                  -color => $color, -underline=>$underline, -indent=>$indent);

}

=pod

PDF::API2 Removes all space between every word in the string you pass
and then rejoins each word with one space.  If you want to use a string with
more than one space between words for formatting purposes, you can either use
the hack below or change PDF::API2 (that's what I did ;).  The code below may
or may not work according to what font you are using.  I used 2 \xA0 per space
because that worked for the Helvetica font I was using.

B<To use a fixed width string with more than one space between words, you can do something like:>

    sub replaceSpace {
      my $text = shift;
      my $nbsp = "\xA0";
      my $new = '';
      my @words = split(/ /, $text);
      foreach my $word (@words) {
        if (length($word)) {
          $new.=$word . ' ';
        } else {
          $new.=$nbsp . $nbsp;
        }
      }
      chop($new);
      return $new;
    }

=head2 setAddTextPos

$pdf->setAddTextPos($hPos, $vPos);

Set the position on the page.  Used by the addText function.

=cut

sub setAddTextPos {
  my ($self, $hPos, $vPos) = @_;
  $self->{hPos}=$hPos;
  $self->{vPos}=$vPos;
}

=head2 getAddTextPos

($hPos, $vPos) = $pdf->getAddTextPos();

Return the (x, y) value of the text position.

=cut

sub getAddTextPos {
  my ($self) = @_;
  return($self->{hPos}, $self->{vPos});
}

=head2 setAlign

$pdf->setAlign($align);

Set the justification of the text.  Used by the addText function.

=cut

sub setAlign {
  my $self = shift;
  my $align = lc(shift);

  if ($align=~m/^left$|^right$|^center$/) {
    $self->{align}=$align;
    $self->{hPos}=undef;        # Clear addText()'s tracking of hPos
  }
}

=head2 getAlign

$align = $pdf->getAlign();

Returns the text justification.

=cut

sub getAlign {
  my $self= shift @_;
  return($self->{align});
}

=head2 wrapText

$newtext = $pdf->wrapText($text, $width);

This is a helper function called by addText, which can be called by itself.
wrapText() wraps $text within $width.

=cut

sub wrapText {
  my $self = shift;
  my $text = shift;
  my $width = shift;

  $text = '' if !length($text);

  return $text if ($text =~ /\n/);  # We don't wrap text with carriage returns
  return $text unless defined $width;  # If no width was specified, return text

  my $txt = $self->{page}->text;
  $txt->font($self->{font}, $self->{size});

  my $ThisTextWidth=$txt->advancewidth($text);
  return $text if ( $ThisTextWidth <= $width);

  my $widSpace = $txt->advancewidth('t');  # 't' closest width to a space

  my $currentWidth = 0;
  my $newText = "";
  foreach ( split / /, $text ) {
    my $strWidth = $txt->advancewidth($_);
    if ( ( $currentWidth + $strWidth ) > $width ) {
      $currentWidth = $strWidth + $widSpace;
      $newText .= "\n$_ ";
    } else {
      $currentWidth += $strWidth + $widSpace;
      $newText .= "$_ ";
    }
  }

  return $newText;
}

=head2 addText

$pdf->addText($text, $hPos, $textWidth, $textHeight);

Takes $text and prints it to the current page at $hPos.  You may just want
to pass this function $text if the text is "pre-wrapped" and setAddTextPos
has been called previously.  Pass a $hPos to change the position the text
will be printed on the page.  Pass a  $textWidth and addText will wrap the
text for you.  $textHeight controls the row height.

=cut

sub addText {
  my ( $self, $text, $hPos, $textWidth, $textHeight )= @_;

  my $txt = $self->{page}->text;
  $txt->font($self->{font}, $self->{size});

  # Push the margin on for align=left (need to work on align=right)
  if ( ($hPos=~/^[0-9]+([.][0-9]+)?$/) && ($self->{align}=~ /^left$/i) ) {
    $self->{hPos}=$hPos + $self->{Xmargin};
  }

  # Establish a proper $self->{hPos} if we don't have one already
  if ($self->{hPos} !~ /^[0-9]+([.][0-9]+)?$/) {
    if ($self->{align}=~ /^left$/i) {
      $self->{hPos} = $self->{Xmargin};
    } elsif ($self->{align}=~ /^right$/i) {
      $self->{hPos} = $self->{PageWidth} - $self->{Xmargin};
    } elsif ($self->{align}=~ /^center$/i) {
      $self->{hPos} = int($self->{PageWidth} / 2);
    }
  }

  # If the user did not give us a $textWidth, use the distance
  # from $hPos to the right margin as the $textWidth for align=left,
  # use the distance from $hPos back to the left margin for align=right
  if ( ($textWidth !~ /^[0-9]+$/) && ($self->{align}=~ /^left$/i) ) {
    $textWidth = $self->{BodyWidth} - $self->{hPos} + $self->{Xmargin};
  } elsif ( ($textWidth !~ /^[0-9]+$/) && ($self->{align}=~ /^right$/i) ) {
    $textWidth = $self->{hPos} + $self->{Xmargin};
  } elsif ( ($textWidth !~ /^[0-9]+$/) && ($self->{align}=~ /^center$/i) ) {
    my $textWidthL=$self->{BodyWidth} - $self->{hPos} + $self->{Xmargin};
    my $textWidthR=$self->{hPos} + $self->{Xmargin};
    $textWidth = $textWidthL;
    if ($textWidthR < $textWidth) { $textWidth = $textWidthR; }
    $textWidth = $textWidth * 2;
  }

  # If $self->{vPos} is not set calculate it (on first text add)
  if ( (!defined $self->{vPos} ) || ($self->{vPos} == 0) ) {
    $self->{vPos} = $self->{PageHeight} - $self->{Ymargin} - $self->{size};
  }

  # If the text has no carrige returns we may need to wrap it for the user
  if ( $text !~ /\n/ ) {
    $text = $self->wrapText($text, $textWidth);
  }

  if ( $text !~ /\n/ ) {
    # Determine the width of this text
    my $thistextWidth = $txt->advancewidth($text);

    # If align ne 'left' (the default) then we need to recalc the xPos
    # for this call to addRawText()  -- needs attention
    my $xPos=$self->{hPos};
    if ($self->{align}=~ /^right$/i) {
      $xPos=$self->{hPos} - $thistextWidth;
    } elsif ($self->{align}=~ /^center$/i) {
      $xPos=$self->{hPos} - $thistextWidth / 2;
    }
    $self->addRawText($text,$xPos,$self->{vPos});

    $thistextWidth = -1 * $thistextWidth if ($self->{align}=~ /^right$/i);
    $thistextWidth = -1 * $thistextWidth / 2 if ($self->{align}=~ /^center$/i);
    $self->{hPos} += $thistextWidth;
  } else {
    $text=~ s/\n/\0\n/g;                # This copes w/strings of only "\n"
    my @lines= split /\n/, $text;
    foreach ( @lines ) {
      $text= $_;
      $text=~ s/\0//;
      if (length( $text )) {
        $self->addRawText($text, $self->{hPos}, $self->{vPos});
      }
      if (($self->{vPos} - $self->{size}) < $self->{Ymargin}) {
        $self->{vPos} = $self->{PageHeight} - $self->{Ymargin} - $self->{size};
        $self->newpage;
      } else {
        $textHeight = $self->{size} unless $textHeight;
        $self->{vPos} -= $self->{size} - $self->{linespacing};
      }
    }
  }
}

=head2 addParagraph

$pdf->addParagraph($text, $hPos, $vPos, $width, $height, $indent, $lead);

Add $text at ($hPos, $vPos) within $width and $height, with $indent.
$indent is the number of spaces at the beginning of the first line.

=cut

sub addParagraph {
  my ( $self, $text, $hPos, $vPos, $width, $height, $indent, $lead, $align ) = @_;

  $align ||= 'justified';
  my $txt = $self->{page}->text;
  $txt->font($self->{font}, $self->{size});

#  $txt->paragraph($text, -x => $hPos, -y => $vPos, -w => $width,
#                  -h => $height, -flindent => $indent, -lead => $lead, -rel => 1);

#  0.40.x
  $txt->lead($lead); # Line spacing
  $txt->translate($hPos,$vPos);
  $txt->paragraph($text, $width, $height, -align => $align);

  ($self->{hPos},$self->{vPos}) = $txt->textpos;
}

# Backwards compatibility for that pesky typo
sub addParagragh {
  my ( $self, $text, $hPos, $vPos, $width, $height, $indent, $lead ) = @_;

  $self->addParagraph($text, $hPos, $vPos, $width, $height, $indent, $lead);
}

=head2 centerString

$pdf->centerString($a, $b, $yPos, $text);

Centers $text between points $a and $b at position $yPos.  Be careful how much
text you try to jam between those points, this function shrinks the text till
it fits!

=cut

sub centerString {
  my $self = shift;
  my $PointBegin = shift;
  my $PointEnd = shift;
  my $YPos = shift;
  my $String = shift;

  my $OldTextSize = $self->getSize;
  my $TextSize = $OldTextSize;

  my $Area = $PointEnd - $PointBegin;

  my $StringWidth;
  while (($StringWidth = $self->getStringWidth($String)) > $Area) {
    $self->setSize(--$TextSize);  ### DECREASE THE FONTSIZE TO MAKE IT FIT
  }

  my $Offset = ($Area - $StringWidth) / 2;
  $self->addRawText("$String",$PointBegin+$Offset,$YPos);
  $self->setSize($OldTextSize);
}

=head2 setRowHeight

=cut

sub setRowHeight {
  my $self = shift;
  my $size = shift; # the fontsize

  return (int($size * 1.20));
}

=head2 getStringWidth

$pdf->getStringWidth($String);

Returns the width of $String according to the current font and fontsize being
used.

=cut

# replaces silly $pdf->{pdf}->calcTextWidth calls
sub getStringWidth {
  my $self = shift;
  my $String = shift;

  my $txt = $self->{page}->text;
  $txt->font($self->{font}, $self->{size});
  return $txt->advancewidth($String);
}

=head2 addImg

$pdf->addImg($file, $x, $y);

Add image $file to the current page at position ($x, $y).

=cut

sub addImg {
  my ( $self, $file, $x, $y ) = @_;

  $self->addImgScaled($file, $x, $y, 1);
}

=head2 addImgScaled

$pdf->addImgScaled($file, $x, $y, $scale);

Add image $file to the current page at position ($x, $y) scaled to $scale.

=cut

sub addImgScaled {
  my ( $self, $file, $x, $y, $scale ) = @_;

  my %type = (jpeg => "jpeg",
              jpg  => "jpeg",
              tif  => "tiff",
              tiff => "tiff",
              pnm  => "pnm",
              gif  => "gif",
              png  => "png",
  );

  $file =~ /\.(\w+)$/;
  my $ext = lc($1);

  my $sub = "image_$type{$ext}";
  my $img = $self->{pdf}->$sub($file);
  my $gfx = $self->{page}->gfx;

  $gfx->image($img, $x, $y, $scale);
}

=head2 setGfxLineWidth

$pdf->setGfxLineWidth($width);

Set the line width drawn on the page.

=cut

sub setGfxLineWidth {
  my ( $self, $width ) = @_;

  $self->{linewidth} = $width;
}

=head2 getGfxLineWidth

$width = $pdf->getGfxLineWidth();

Returns the current line width.

=cut

sub getGfxLineWidth {
  my $self = shift;

  return $self->{linewidth};
}

=head2 drawLine

$pdf->drawLine($x1, $y1, $x2, $y2);

Draw a line on the current page starting at ($x1, $y1) and ending
at ($x2, $y2).

=cut

sub drawLine {
  my ( $self, $x1, $y1, $x2, $y2 ) = @_;

  my $gfx = $self->{page}->gfx;
  $gfx->move($x1, $y1);
  $gfx->linewidth($self->{linewidth});
  $gfx->line($x2, $y2);
  $gfx->stroke;
}

=head2 drawRect

$pdf->drawRect($x1, $y1, $x2, $y2);

Draw a rectangle on the current page.  Top left corner is represented by
($x1, $y1) and the bottom right corner is ($x2, $y2).

=cut

sub drawRect {
  my ( $self, $x1, $y1, $x2, $y2 ) = @_;

  my $gfx = $self->{page}->gfx;
  $gfx->linewidth($self->{linewidth});
  $gfx->rectxy($x1, $y1, $x2, $y2);
  $gfx->stroke;
}

=head2 shadeRect

$pdf->shadeRect($x1, $y1, $x2, $y2, $color);

Shade a rectangle with $color.  Top left corner is ($x1, $y1) and the bottom
right corner is ($x2, $y2).

=over 4

=item B<Defined color-names are:>

aliceblue, antiquewhite, aqua, aquamarine, azure,
beige, bisque, black, blanchedalmond, blue,
blueviolet, brown, burlywood, cadetblue, chartreuse,
chocolate, coral, cornflowerblue, cornsilk, crimson,
cyan, darkblue, darkcyan, darkgoldenrod, darkgray,
darkgreen, darkgrey, darkkhaki, darkmagenta,
darkolivegreen, darkorange, darkorchid, darkred,
darksalmon, darkseagreen, darkslateblue, darkslategray,
darkslategrey, darkturquoise, darkviolet, deeppink,
deepskyblue, dimgray, dimgrey, dodgerblue, firebrick,
floralwhite, forestgreen, fuchsia, gainsboro, ghostwhite,
gold, goldenrod, gray, grey, green, greenyellow,
honeydew, hotpink, indianred, indigo, ivory, khaki,
lavender, lavenderblush, lawngreen, lemonchiffon,
lightblue, lightcoral, lightcyan, lightgoldenrodyellow,
lightgray, lightgreen, lightgrey, lightpink, lightsalmon,
lightseagreen, lightskyblue, lightslategray,
lightslategrey, lightsteelblue, lightyellow, lime,
limegreen, linen, magenta, maroon, mediumaquamarine,
mediumblue, mediumorchid, mediumpurple, mediumseagreen,
mediumslateblue, mediumspringgreen, mediumturquoise,
mediumvioletred, midnightblue, mintcream, mistyrose,
moccasin, navajowhite, navy, oldlace, olive, olivedrab,
orange, orangered, orchid, palegoldenrod, palegreen,
paleturquoise, palevioletred, papayawhip, peachpuff,
peru, pink, plum, powderblue, purple, red, rosybrown,
royalblue, saddlebrown, salmon, sandybrown, seagreen,
seashell, sienna, silver, skyblue, slateblue, slategray,
slategrey, snow, springgreen, steelblue, tan, teal,
thistle, tomato, turquoise, violet, wheat, white,
whitesmoke, yellow, yellowgreen

or the rgb-hex-notation:

	#rgb, #rrggbb, #rrrgggbbb and #rrrrggggbbbb

or the cmyk-hex-notation:

        %cmyk, %ccmmyykk, %cccmmmyyykkk and %ccccmmmmyyyykkkk

and additionally the hsv-hex-notation:

        !hsv, !hhssvv, !hhhsssvvv and !hhhhssssvvvv

=back

=cut

sub shadeRect {
  my ( $self, $x1, $y1, $x2, $y2, $color ) = @_;

  my $gfx = $self->{page}->gfx;

  $gfx->fillcolor($color);
  $gfx->rectxy($x1, $y1, $x2, $y2);
  $gfx->fill;
}

=head2 drawPieGraph

$pdf->drawPieGraph($x, $y, $size, $rData, $rLabels);

Method to create a piegraph using a reference to an array of values.
It also takes a reference to an array for labels for each data value.  A
legend with all the colors and labels will appear if $rLabels is passed. $x and
$y are the coordinates for the center of the pie and $size is the radius.

=cut

sub drawPieGraph {
  my $self  = shift;
  my $x     = shift;
  my $y     = shift;
  my $size  = shift;
  my $rData = shift;
  my $rLabels = shift;

  my $circ = 360;
  my $a = 0;
  my $b = 0;
  my @colors = &getcolors();
  my $lastclr = $#colors;
  my $gfx = $self->{page}->gfx;

  # Set up the colors we'll use
  my @clr;
  foreach my $elem ( 0 .. $#$rData ) {
#    push(@clr, $colors[int(rand($#colors))]);
     push(@clr, $colors[$elem]);
  }

  # Add up the numbers
  my $total;
  foreach my $elem ( 0 .. $#$rData ) {
    $total+=$rData->[$elem];
  }
  # Get the percentages
  my @perc;
  foreach my $elem ( 0 .. $#$rData ) {
    $perc[$elem] = $rData->[$elem] / $total;
  }

  # Draw a pie
  my $cnt = 0;
  foreach my $pct (@perc) {
    $b+=$circ * $pct;
    $b = $circ if $b > $circ;
    $gfx->fillcolor($clr[$cnt++]);
    $gfx->pie($x, $y, $size, $size, $a, $b);
    $gfx->fill;
    $a = $b;
  }

  # Do we print labels?
  if (scalar(@{ $rLabels })) {
    my $oldfont = $self->getFont();
    my $oldsize = $self->getSize();
    my $fontsize = 12;
    $self->setFont("Times-roman");
    $self->setSize($fontsize);
    my $colorblocksize = 10;
    my $maxsize = 0;
    for (0 .. $#$rLabels) {
      $maxsize = $self->getStringWidth($rLabels->[$_])
                   if $self->getStringWidth($rLabels->[$_]) > $maxsize;
    }
    my $top = $y + ((($#perc + 1) * $fontsize) / 2);
    my $left = $x + $size + 8;
    $self->drawRect($left, $top,
                    $x + $size + 8 + $colorblocksize + $maxsize + 3,
                    $y - ((($#perc + 1) * $fontsize) / 2));
    my $pos = $top - 1;
    $cnt = 0;
    foreach my $nbr (0 .. $#perc) {
      $self->shadeRect($left+1, $pos, $left+1+$colorblocksize,
                       $pos-$colorblocksize, $clr[$cnt++]);
      $self->addRawText($rLabels->[$nbr], $left+$colorblocksize+3,
                        $pos-$colorblocksize);
      $pos-=$fontsize;
    }
  }
}

=head2 getcolors

Returns list of available colours

=cut

sub getcolors {
  my @cols=qw(
        red yellow blue green aqua bisque black
        blueviolet brown burlywood cadetblue chartreuse
        chocolate coral cornflowerblue cornsilk crimson
        cyan darkblue darkcyan darkgoldenrod darkgray
        darkgreen darkgrey darkkhaki darkmagenta
        darkolivegreen darkorange darkorchid darkred
        darksalmon darkseagreen darkslateblue darkslategray
        darkslategrey darkturquoise darkviolet deeppink
        deepskyblue dimgrey dodgerblue firebrick
        floralwhite forestgreen fuchsia gainsboro ghostwhite
        gold goldenrod gray greenyellow
        honeydew hotpink indianred indigo ivory khaki
        lavender lavenderblush lawngreen lemonchiffon
        lightblue lightcoral lightcyan lightgoldenrodyellow
        lightgray lightgreen lightgrey lightpink lightsalmon
        lightseagreen lightskyblue lightslategray
        lightslategrey lightsteelblue lightyellow lime
        limegreen linen magenta maroon mediumaquamarine
        mediumblue mediumorchid mediumpurple mediumseagreen
        mediumslateblue mediumspringgreen mediumturquoise
        mediumvioletred midnightblue mintcream mistyrose
        moccasin navajowhite navy oldlace olivedrab
        orange orangered orchid palegoldenrod palegreen
        paleturquoise palevioletred papayawhip peachpuff
        peru pink plum powderblue purple rosybrown
        royalblue saddlebrown salmon sandybrown seagreen
        seashell sienna silver skyblue slateblue slategray
        slategrey snow springgreen steelblue tan teal
        thistle tomato turquoise violet wheat white
        whitesmoke yellowgreen);

  return @cols;
}

=head2 drawBarcode

$pdf->drawBarcode($x, $y, $scale, $frame, $type, $code, $extn, $umzn,
                        $lmzn, $zone, $quzn, $spcr, $ofwt, $fnsz, $text);

This is really not that complicated, trust me! ;) I am pretty unfamiliar with
barcode lingo and types so if I get any of this wrong, lemme know!
This is a very flexible way to draw a barcode on your PDF document.
$x and $y represent the center of the barcode's position on the document.
$scale is the size of the entire barcode 1 being 1:1, which is all you'll
need most likely.  $type is the type of barcode which can be codabar, 2of5int,
3of9, code128, or ean13.  $code is the alpha-numeric code which the barcode
will represent.  $extn is the
extension to the $code, where applicable.  $umzn is the upper mending zone and
$lmzn is the lower mending zone. $zone is the the zone or height of the bars.
$quzn is the quiet zone or the space between the frame and the barcode.  $spcr
is what to put between each number/character in the text.  $ofwt is the
overflow width.  $fnsz is the fontsize used for the text.  $text is optional
text beneathe the barcode.

=cut

sub drawBarcode {
  my $self = shift;
  my $x    = shift;  # x center of barcode image
  my $y    = shift;  # y center of barcode image
  my $scale = shift; # scale of barcode image
  my $frame = shift; # width of the frame around the quiet zone
#  my $font = shift;
  my $type = shift; # type of barcode
  my $code = shift; # the code
  my $extn = shift; # code extension
  my $umzn = shift; # upper mending zone
  my $lmzn = shift; # lower mending zone
  my $zone = shift; # height of the bars
  my $quzn = shift; # zone between barcode and frame
  my $spcr = shift; # space between numbers
  my $ofwt = shift; # overflow
  my $fnsz = shift; # fontsize
  my $text = shift; # alt text

  my $page = $self->{page};
  my $gfx  = $page->gfx;

  my $bSub = "xo_$type";
  my $bar = $self->{pdf}->$bSub(
                           -font => $self->{font},
                           -type => $type,
                           -code => $code,
                           -quzn => $quzn,
                           -umzn => $umzn,
                           -lmzn => $lmzn,
                           -zone => $zone,
                           -quzn => $quzn,
                           -spcr => $spcr,
                           -ofwt => $ofwt,
                           -fnsz => $fnsz,
                           -text => $text
                          );

#  $gfx->barcode($bar, $x, $y, $scale, $frame);
  $gfx->save;
  $gfx->linecap(0);
  $gfx->transform( -translate => [$x, $y]);
  $gfx->fillcolor('#ffffff');
  $gfx->linewidth(0.1);
  $gfx->fill;
  $gfx->formimage($bar,0,0,$scale);
  $gfx->restore;
}

=head2 setFont

$pdf->setFont($font);

Creates a new font object of type $font to be used in the page.

=cut

sub setFont {
  my ( $self, $font, $size )= @_;

  if (exists $self->{__font_cache}->{$font}) {
    $self->{font} = $self->{__font_cache}->{$font};
  }
  else {
    $self->{font} = $self->{pdf}->corefont($font);
    $self->{__font_cache}->{$font} = $self->{font};
  }

  $self->{fontname} = $font;
}

=head2 getFont

$fontname = $pdf->getFont();

Returns the font name currently being used.

=cut

sub getFont {
  my $self = shift;

  return $self->{fontname};
}

=head2 setSize

$pdf->setSize($size);

Sets the fontsize to $size.  Called before setFont().

=cut

sub setSize {
  my ( $self, $size ) = @_;

  $self->{size} = $size;
}

=head2 getSize

$fontsize = $pdf->getSize();

Returns the font size currently being used.

=cut

sub getSize {
  my $self = shift;

  return $self->{size};
}

=head2 pages

$pages = $pdf->pages();

The number of pages in the document.

=cut

sub pages {
  my $self = shift;

  return $self->{pdf}->pages;
}

=head2 setInfo

$pdf->setInfo(%infohash);

Sets the info structure of the document.  Valid keys for %infohash:
Creator, Producer, CreationDate, Title, Subject, Author, etc.

=cut

sub setInfo {
  my ($self, %info) = @_;

  # Over-ride or define %INFO values
  foreach my $key (keys %{$self->{INFO}}) {
      next unless (exists($info{$key}) && defined($info{$key}));
      if (length($info{$key}) and ($info{$key} ne ${$self->{INFO}}{$key})) {
          ${$self->{INFO}}{$key} = $info{$key};
      }
  }
  my @orig_keys = keys(%{$self->{INFO}});
  foreach my $key (keys %info) {
    if (! grep /$key/, @orig_keys) {
      ${$self->{INFO}}{$key} = $info{$key};
    }
  }
}

=head2 getInfo

%infohash = $pdf->getInfo();

Gets meta-data from the info structure of the document.
Valid keys for %infohash: Creator, Producer, CreationDate,
Title, Subject, Author, etc.

=cut

sub getInfo {
  my $self = shift;

  my %info = $self->{pdf}->info();
  return %info;
}

=head2 saveAs

Saves the document to a file.

  # Save the document as "file.pdf"
  my $fileName = "file.pdf";
  $pdf->saveAs($fileName);

=cut

sub saveAs {
  my $self = shift;
  my $fileName = shift;

  $self->{pdf}->info(%{$self->{INFO}});
  $self->{pdf}->saveas($fileName);
  $self->{pdf}->end();
}

=head2 Finish

Returns the PDF document as text.  Pass your own custom routine to do things
on the footer of the page.  Pass 'roman' for Roman Numeral page numbering.

	# Hand the document to the web browser
	print "Content-type: application/pdf\n\n";
	print $pdf->Finish();

=cut

sub Finish {
  my $self = shift;
  my $callback = shift;

  my $total = $self->{page_nbr} - 1;

  # Call the callback if one was given to us
  if (ref($callback) eq 'CODE') {
    &$callback($self, $total);
  # This will print a footer if no $callback is passed for backwards
  # compatibility
  } elsif (defined $callback && $callback !~ /none/i) {
    &gen_page_footer($self, $total, $callback);
  }

  $self->{pdf}->info(%{$self->{INFO}});
  my $out = $self->{pdf}->stringify;

  return $out;
}

=head2 getPDFAPI2Object

Object method returns underlying PDF::API2 object

=cut

sub getPDFAPI2Object {
    my $self = shift;
    return $self->{pdf};
}

### PRIVATE SUBS ##############################################################

sub gen_page_footer {
  my $self = shift;
  my $total = shift;
  my $type = shift;

  for (my $i = 1; $i <= $total; $i++) {
    next if ( $self->{no_page_num}->[$i - 1] );
    my $page = $self->{pdf}->openpage($i);
    my $txtobj = $page->text;
    my $txt;
    my $font;
    if ($type eq 'roman') {
      require Text::Roman;
      $font = $self->{pdf}->corefont("Times-roman");
      $txt = Text::Roman::int2roman($i). " of " .
             Text::Roman::int2roman($total);
    } else {
      $font = $self->{pdf}->corefont("Helvetica");
      $txt = "Page $i of $total";
    }
    my $size = 10;
    $txtobj->font($font, $size);
    $txtobj->translate($self->{Xmargin}, 8);
    $txtobj->text($txt);
    $size = $self->getStringWidth($self->{DATE});
    $txtobj->translate($self->{PageWidth} - $self->{Xmargin} - $size, 8);
    $txtobj->text($self->{DATE});
  }
}

=head1 AUTHOR EMERITUS

Andrew Orr

=head1 MAINTAINER

Aaron TEEJAY Trevena

=head1 BUGS

Please report any bugs or feature requests to C<bug-calendar-model at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PDF-Report>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PDF::Report


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PDF-Report>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PDF-Report>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PDF-Report>

=item *  METACPAN

L<https://metacpan.org/module/PDF::Report/>

=item * GITHUB

L<https://github.com/hashbangperl/perl-pdf-report>

=back

=head1 SEE ALSO

=over 4

=item PDF::API2

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2008-2010 Andy Orr

Copyright 2013 Aaron Trevena

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
