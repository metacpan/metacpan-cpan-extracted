# -*- Perl -*-
# TextBlock.pm
# An object that may be used to construct a block of text in PostScript
#
package PostScript::TextBlock;
use strict;
use PostScript::Metrics;

use vars qw($VERSION);
$VERSION = '0.06';

# The valid text block attribute names
#
my @paramnames = ( 'text', 'font', 'size', 'leading');

# The default attribute values
#
my %defaults = (
                text    => '',
                font    => 'CharterBT-Roman',
                size    => 12,
                leading => 16
               );
sub new {
    # The constructor method
    #
    my $proto = shift;                   # allow use as a class or object method
    my $class = ref($proto) || $proto;   # see perltoot man page

    # A text block consists of a list of 'elements',
    # (not to be confused with the PostScript::Elements object)
    #
    my $self = [];

    return  bless($self,$class);
}

sub addText {
    # Add an element of text to the TextBlock
    #
    my $self = shift;
    my %params = @_;
    $params{'text'} =~ s/(\(|\))/\\$1/g;    # escape parentheses

    # Use the default values if an attribute is not given
    #
    foreach (@paramnames) {
        $params{$_} = $defaults{$_} unless ($params{$_});
    }
    push @$self, { %params };
}

sub numElements {
    # Returns the number of elements in the TextBlock
    #
    my $self = shift;
    return $#{@$self}+1;
}

sub Write {
	# The Write() method takes four parameters: w, h, x , and y,
	# where w and h are the width and height of the block (in points),
	# and x and y specify the upper left corner of the TextBlock (in the
	# PostScript coordinate system). This method returns a string containing
	# the PostScript code that generated the block, and a TextBlock object
	# the contains the portion that doesn't fit within the given bounds.
	#
	my $self = shift;
	my ($w, $h, $x, $y) = @_;

	my ($x1, $y1) = ($x, $y);
	my $returnval = "";
	my @remainder = ();
	my ($maxlead, $wcount, $linebuffer) = (0, 0, "");
	my ($line, $word, @words);
	my $wordwidth;
	$returnval .= "0 setgray\n";

	my $element = {};
	my $index = 0;
	$element = $self->[$index];

	my $maxindex = $self->numElements;
	my $firstindex = 0;

	ELEMENT:  while (($index < $maxindex) && ($y1 >= ($y-$h))) {
		$wcount = 0;
		($line, $word) = (undef, undef);
		@words = ();
		$linebuffer = "";
		$maxlead = 0;
		$firstindex = $index;

		# Loop until a complete line is formed, or
		# until we run out of elements
		#
		LINE: while (($index < $maxindex) && $wcount<=$w) {
			$linebuffer .= "/$element->{font} findfont\n";
			$linebuffer .= "$element->{size} scalefont setfont\n";

			# Calculate the maximum leading on this line
			#
			$maxlead = $element->{leading} if ($element->{leading} > $maxlead);

			@words = split /( +|\t|\n)/, $element->{text};
			while (@words) {
				$word = shift @words;
				$wordwidth = PostScript::Metrics::stringwidth($word,
																$element->{font},
																$element->{size});

				# If the word is longer than the line, break by character.
				# Note that we could still have the problem of a single
				# character not fitting the width, which we will leave
				# as an exercise for the reader.
				#
				if ($wordwidth > $w) {
                    unshift @words, split //, $word;
                    $word = shift @words;
                    $wordwidth = PostScript::Metrics::stringwidth($word,
                                                                $element->{font},
                                                                $element->{size});
				}
				$wcount += $wordwidth;

				# If we've gone over, push the word back on
				# for later processing.
				#
			        if ( ($wcount>$w) || ($word =~ s/\n//) ) {
                                     if ($word =~ /^ /) { $word =~ s/^[ ]+//; }
                                           unshift @words, $word;
                                           last LINE;
                                   }	
				$line .= $word;
			}
			$index++;
			$element = $self->[$index];
		}

		# Show the line
		#
		if (defined($line)) {
			$linebuffer .= "($line) show\n";
		}

		# Subtract the maximum leading from the current coordinate
		#
		$y1 -= $maxlead;

		# If this line doesn't fit, put the elements making up the line
		# back on for later processing...
		#
		if ($y1 < ($y-$h)) {
			for (my $i=$firstindex; $i < $maxindex; $i++) {
				push @remainder, $self->[$i];
			}
			last ELEMENT;
		} else {
			# Put any remaining words back for later processing
			#
			if (@words) {
				$element->{text} = join '', @words;
			} else {
				$index++;
				$element = $self->[$index];
			}
			$returnval .= "0 setgray $x1 $y1 moveto\n";
			$returnval .= $linebuffer;
		}
	}
	return ($returnval, bless([@remainder], 'PostScript::TextBlock'));
}


sub FitToRegion {
	# The FitToRegion() method takes four parameters: w, h, x , and y,
	# where w and h are the width and height of the block (in points),
	# and x and y specify the upper left corner of the TextBlock (in the
	# PostScript coordinate system). This method returns a string containing
	# the PostScript code that generated the block, and a TextBlock object
	# the contains the portion that doesn't fit within the given bounds.
	#
	my $self = shift;
	my ($w, $h, $x, $y, $minimum_font_size) = @_;

	my ($x1, $y1) = ($x, $y);
	my $returnval = "";
	my @remainder = ();
	my ($maxlead, $wcount, $linebuffer) = (0, 0, "");
	my ($line, $word, @words);
	my $wordwidth;
	$returnval .= "0 setgray\n";

	my $element = {};
	my $index = 0;

	$element = $self->[$index];

	my %original_element = {};
	foreach (keys %$element) {
		$original_element{$_} = $self->[$index]->{$_};
	} # foreach

	my $maxindex = $self->numElements;
	my $firstindex = 0;

	ELEMENT:  while (($index < $maxindex) && ($y1 >= ($y-$h))) {
		$wcount = 0;
		($line, $word) = (undef, undef);
		@words = ();
		$linebuffer = "";
		$maxlead = 0;
		$firstindex = $index;

		# Loop until a complete line is formed, or
		# until we run out of elements
		#
		LINE: while (($index < $maxindex) && $wcount<=$w) {
			$linebuffer .= "/$element->{font} findfont\n";
			$linebuffer .= "$element->{size} scalefont setfont\n";

			# Calculate the maximum leading on this line
			#
			$maxlead = $element->{leading} if ($element->{leading} > $maxlead);

			@words = split /( +|\t|\n)/, $element->{text};
			while (@words) {
				$word = shift @words;
				$wordwidth = PostScript::Metrics::stringwidth($word,
																$element->{font},
																$element->{size});

				# If the word is longer than the line, break by character.
				# Note that we could still have the problem of a single
				# character not fitting the width, which we will leave
				# as an exercise for the reader.
				#
#				if ($wordwidth > $w) {
#                    unshift @words, split //, $word;
#                    $word = shift @words;
#                    $wordwidth = PostScript::Metrics::stringwidth($word,
#                                                                $element->{font},
#                                                                $element->{size});
#				} # if
				$wcount += $wordwidth;

				# If we've gone over, push the word back on
				# for later processing.
				#
				if (($wcount > $w) || ($word =~ s/\n//)) {
					unshift @words, $word;
					last LINE;
				} # if
				$line .= $word;
			} # while
			$index++;
			$element = $self->[$index];
		} # while

		# Show the line
		#
		if (defined($line)) {
			$linebuffer .= "($line) show\n";
		}

		# Subtract the maximum leading from the current coordinate
		#
		$y1 -= $maxlead;

		# If this line doesn't fit, put the elements making up the line
		# back on for later processing...
		#
		if ($y1 < ($y-$h)) {
			for (my $i=$firstindex; $i < $maxindex; $i++) {
				push @remainder, $self->[$i];
			}
			last ELEMENT;
		} else {
			# Put any remaining words back for later processing
			#
			if (@words) {
				$element->{text} = join '', @words;
			} else {
				$index++;
				$element = $self->[$index];
			} # if
			$returnval .= "0 setgray $x1 $y1 moveto\n";
			$returnval .= $linebuffer;
		} # else
	} # while

	if (@remainder and ($original_element{size} - 1 >= $minimum_font_size)) {
		--$original_element{size};
		if ($original_element{leading}) {
			--$original_element{leading};
		} # if
		$self->[0] = { %original_element };
		($returnval, @remainder) = &FitToRegion($self, $w, $h, $x, $y, $minimum_font_size);
	} # if

	return ($returnval, bless([@remainder], 'PostScript::TextBlock'));
#	return $returnval;
} # FitToRegion
1;      # All Perl modules should return true


__END__

=head1 NAME

PostScript::TextBlock - An object that may be used to construct a block of
                text in PostScript.

=head1 SYNOPSIS

    use PostScript::TextBlock;
    my $tb = new PostScript::TextBlock;
    $tb->addText( text => "Hullaballo in Hoosick Falls.\n",
                  font => 'CenturySchL-Ital',
                  size => 24,
                  leading => 26
                 );
    $tb->addText( text => "by Charba Gaspee.\n",
                  font => 'URWGothicL-Demi',
                  size => 12,
                  leading => 14
                 );
    print 'There are '.$tb->numElements.' elements in this object.';
    open OUT, '>psoutput.ps';
    my ($code, $remainder) = $tb->Write(572, 752, 20, 772);
    print OUT $code;

=head1 DESCRIPTION


The PostScript::TextBlock module implements four methods:

=over 3

=item new() - Create a New PostScript::TextBlock object

This method instantiates a new object of class PostScript::TextBlock.

=item addText( text=>$text,
               [ font=>$font ],
               [ size=>$size ],
               [ leading=>$leading ] )

The addText() method will add a new 'text element' to the TextBlock object. A
'text element' can be thought of as a section of text that has the same
characteristics, i.e. all the characters are the same font, size and leading.
this representation allows you to include text rendered in multiple fonts at
multiple sizes within the same text block by including them as separate
elements.

This method takes up to four attributes (note that the '[]' brackets above
indicate that a parameter is optional, not an array reference):

text
The text attribute is required, though nothing bad will happen if you leave it
out. This is simply the text to be rendered in the text block. Line breaks may
be inserted by including a newline "\n".

font
The font attribute is a string indicating the name of the font to be used to
render this element. The PS package uses an internal description of the Font
Metrics of various fonts that is contained in the PostScript::Metrics module. As of
this writing, the PostScript::Metrics module supports the following fonts (basically,
the default GhostScript fonts that have AFM files):

NimbusSanL-ReguCond	  URWGothicL-Book
CenturySchL-Bold          CharterBT-Italic
URWBookmanL-Ligh          CharterBT-BoldItalic
NimbusRomNo9L-ReguItal    URWBookmanL-DemiBoldItal
CharterBT-Roman           NimbusMonL-ReguObli
NimbusSanL-ReguCondItal   CenturySchL-Ital
CenturySchL-BoldItal      URWPalladioL-Roma
URWBookmanL-LighItal      CharterBT-Bold
NimbusSanL-BoldCond       NimbusMonL-BoldObli
NimbusSanL-BoldCondItal   URWGothicL-DemiObli
NimbusSanL-Regu           URWPalladioL-Bold
NimbusMonL-Regu           NimbusSanL-ReguItal
URWGothicL-BookObli       URWPalladioL-Ital

You can get a list of the currently supported fonts with the following:

    use PostScript::Metrics;
    @okfonts = PostScript::Metrics->listFonts();

=over 10

NOTE: The font must be available to the PostScript interpreter that is used
to render the page described by the program. If the interpreter cannot load
the font, it will ususally attempt to substitute a similar font. If a font is
substituted with a font with different metrics, lines of text may overrun the
right margin of the text block. You have been warned.

=over 3

It is very easy to create stylesheets for a document:

    # Define the styles
    #
    %body = ( font => 'URWGothicL-DemiObli', size => 12, leading => 16 );
    %head1 = ( font => 'NimbusSanL-BoldCond', size => 24, leading => 36 );
    %head2 = ( font => 'NimbusSanL-BoldCond', size => 18, leading => 30 );

    # Use them where appropriate
    #
    $tb->addText(text => "Chapter 10\n", %head1);
    $tb->addText(text => "Spokane Sam and His Spongepants\n", %head2);
    $tb->addText(text => "It was a dark and stormy night and Spokane Sam\'s
    Spongepants were thirsty...", %body);


=item numElements()

Returns the number of elements in the text block object. An 'element' is
created each time the addText() method is called.

=item Write( $width, $height, $xoffset, $yoffset )

The Write() method will generate the PostScript code that will render the text
on a page when passed to a PostScript interpreter such as Ghostscript. The
four parameters are expressed in points (1/72 inch) and indicate the width and
height of the box within which the text should be printed, and the x and y
offset of the upper left corner of this box.

Important: PostScript defines the orgin (0,0) as the lower left corner of
the page! This *will* mess you up.

Standard page sizes in points are:

     Paper Size                      Width, Height (in points)
     .........................       .........................
     Letter                          612, 792
     Legal                           612, 1008
     Ledger                          1224, 792
     Tabloid                         792, 1224
     A0                              2384, 3370
     A1                              1684, 2384
     A2                              1191, 1684
     A3                              842, 1191
     A4                              595, 842
     A5                              420, 595
     A6                              297, 420
     A7                              210, 297
     A8                              148, 210
     A9                              105, 148
     B0                              2920, 4127
     B1                              2064, 2920
     B2                              1460, 2064
     B3                              1032, 1460
     B4                              729, 1032
     B5                              516, 729
     B6                              363, 516
     B7                              258, 363
     B8                              181, 258
     B9                              127, 181
     B10                             91, 127
     #10 Envelope                    297, 684
     C5 Envelope                     461, 648
     DL Envelope                     312, 624
     Folio                           595, 935
     Executive                       522, 756

The write() method returns two values: a string consisting of the PostScript
code (suitable for printing to a file), and a TextBlock object containing the
elements (and partial elements) that did not fit within the specified area,
if any. If the entire text block fits with the area, the remainder will be
undef. The remainder can be used to layout multiple pages and columns, etc. in
a similar manner to most modern desktop publishing programs. In general, the
write() method should be called as in the following, which writes the
PostScript code to a file called 'psoutput.ps':

    open OUT, '>psoutput.ps';
    my ($code, $remainder) = $tb->Write(572, 752, 20, 772);
    print OUT $code;

To print an entire text block that spans multiple pages, you could do
something like this:

(add enough text to the text block first..)

    open OUT, '>psoutput.ps';
    my $pages = 1;

    # Create the first page
    #
    my ($code, $remainder) = $tb->Write(572, 752, 20, 772);
    print OUT "%%Page:$pages\n";      # this is required by the Adobe
                                      # Document Structuring Conventions
    print OUT $code;
    print OUT "showpage\n";

    # Print the rest of the pages, if any
    #
    while ($remainder->numElements) {
        $pages++;
        print OUT "%%Page:$pages\n";
        ($code, $remainder) = $remainder->Write(572, 752, 20, 772);
        print OUT $code;
        print OUT "showpage\n";
    }

However, if you use the PostScript::Document module to construct generic
multi-page PostScript documents, you don't have to worry about this.

=head1 A NOTE ABOUT FONT METRICS

The write() method uses the module PostScript::Metrics to determine the width of
each character; widths vary from font to font and character to character.
If you were writing a stright PostScript program, you would let the PostScript
interpreter do this for you, but in the case of this program, we need to know
the width of each character in a font within the Perl script. The PostScript::Metrics
module contains the font metrics (i.e., a list containing the width of each
character in the font) for a bunch of fonts that are listed above under the
description of the addText() method. This set started with the metrics for all
of the default fonts with AFM files that came with GhostScript. It is slowly
growing as more fonts are mapped. To add support for a new font, you must
create the array with the metrics for that font and add it to the PostScript::Metrics
module. For a font with an AFM file, the AFM file can be parsed with Gisle
Aas' Font::AFM module, available on CPAN.

Please send all PostScript::Metrics patches to the author at shawn@as220.org.

=head1 TODO

* better compliance with Adobe's Document Structuring Conventions
* more font metrics descriptions
* make font loading code smarter and more efficient for the interpreter
* support a larger character set
* it would be nice to add more functions, e.g. Clone()
* how about settable defaults?

=head1 AUTHOR

Copyright 1998, 1999 Shawn Wallace. All rights reserved.

Contact the author: shawn@as220.org
http://www.as220.org/shawn

Portions of code contributed by Dan Smeltz.

This is free software. You may use, modify, and
redistribute this package under the same terms as Perl itself.

PostScript is a trademark of Adobe Systems.

=cut

