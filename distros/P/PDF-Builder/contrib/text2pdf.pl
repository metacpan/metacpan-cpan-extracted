#!/usr/bin/perl
#
# RCS Comments.
# $Author: hank $
# $Date: 2013/08/14 20:26:56 $
# $RCSfile: text2pdf.pl,v $
#
# Revision: by Phil M Perry  June 2018
#   make Perl::Critic happy over handling of bareword filehandles and loop
#     iterator declarations
# Revision: by Phil M Perry  March 2017
#   cleanup: remove deprecated and commented-out old stuff
#   diagnostic/debug print statements under "debug" control --debug
#   restructured command line parameter handling, and input is now positional
#     with multiple file names or globs on command line
#   add named paper size --PGpaper=name
#   allow dimensions to have units (default units unchanged)
#   .PAGE=minsize;  if more space left, don't paginate
#   --tabs="t1 t2 t3...tn"  default 9 17 25 33...  tab stops
#   wrap lines that don't fit, so they don't just run off right side
#   page numbering, file name each page
#   consider --duplex to swap left and right on even numbered pages
#            --header='l|c|r' and --footer='l|c|r' with &f = basename file,
#                   &F = full file, &p = page number, etc.
#            right-justified text (have left and centered)
#
# $Revision: 1.6 $   hankivy
# $Source: /home/hank/bin/RCS/text2pdf.pl,v $
# $Header: /home/hank/bin/RCS/text2pdf.pl,v 1.6 2013/08/14 20:26:56 hank Exp $
# $Id: text2pdf.pl,v 1.6 2013/08/14 20:26:56 hank Exp $
# $Log: text2pdf.pl,v $
# Revision 1.6  2013/08/14 20:26:56  hank
# Improved documentation.
# Removed, or commented out deprecated code.
#
# Revision 1.5  2013/07/20 02:30:41  hank
# Add font name, font size, as parameters to the command line.
# Add tests to validate the new parameters.
#
# Revision 1.4  2013/06/11 03:42:28  hank
# Add debug switch for status messages.
#
# Revision 1.3  2013/06/10 23:05:28  hank
# Added centering.
#
# Revision 1.2  2013/06/08 03:54:23  hank
# Add changing fonts, sizes, and pictures.
#
# Revision 1.1  2013/05/30 20:31:54  hank
# Initial revision
#
#
#
# txt2pdf.pl from mcollins@fcnetwork.com
#
# MC's Q&D text to PDF converter.
#
# FYI,
#
# I wrote a simple text file to PDF converter that uses PDF::Builder::Lite.
# It isn't full-featured by any stretch but it does illustrate one of the
# many uses of this cool module.  I'm submitting it here for your perusal.
# If you think of any useful things to add to it please let me know.
# Fredo, please feel free to include it in the contributed items if you
# would like.
#
# Thanks!  (Sorry about the long comments that wrap around to the next
# line...)
# 
# -MC
#
use strict;
use warnings;

our $VERSION = '3.024'; # VERSION
our $LAST_UPDATE = '3.021'; # manually update whenever code is changed

use PDF::Builder;
use PDF::Builder::Util;
use Getopt::Long;
use File::Basename;
use diagnostics;

$|++;                   	# turn off buffering on output.

# variables from the command line (set by flags)
my $CLdestpath;           	# destination path
  my $DEFdestpath = './';       #   default = current working directory
my $CLleft;             	# left margin/starting point
  my $DEFleft = 72;             #   default = 72pt from page left
my $CLright;             	# right margin
  my $DEFright = 72;            #   default = 72pt from page right
my $CLtop;              	# top margin/starting point
  my $DEFtop = 36;              #   default = 36pt from page top  
my $CLbottom;              	# bottom margin/starting point
  my $DEFbottom = 36;           #   default = 36pt from page bottom
my $CLPGpaper;			# media (paper) by name
				#   no default (so can set H and W)
my $CLPGwidth; 			# Page width in inches
  my $DEFPGwidth = 612;         #   default = US letter 8.5in
my $CLPGheight;			# Page height in inches
  my $DEFPGheight = 792;        #   default = US letter 11in
my $CLlandscape;          	# landscape cmd line flag
my $CLportrait;          	# portrait cmd line flag
my $CLFontType;      		# Font Type, C=Core, TT=TrueType
  my $DEFFontType = 'C';        #   default = core fonts
my $CLFontName;     		# cmd line fontname
  my $DEFFontName = 'Courier';	#  default font Courier (fixed pitch)
my $CLfontsize;               	# font size
  my $DEFfontsize = 7;          #   default = 7pt
my $CLspacing;              	# text spacing ($pdf->textlead)
  				#   default = 115% of font size
my $CLtabs; 			# tab expansion definition
  my $DEFtabs = '9 17';		#   default = at 9, 17, 25, 33,...

my $pdf;              	# main PDF document object
my $page;             	# current page being processed
my $text;             	# current page's text object
my $font;             	# current font being used
my ($hdrftr, $contline);	# some special fixed fonts
my $pointscount;        # how many points have been processed on this page.
			#   Starts with zero at the top of the page.
my $PGpaper;		# media (paper) size by NAME
my $PGheight;		# Physical sheet height in points.
my $PGwidth;		# Physical sheet height in points.
my ($left, $right, $top, $bottom);  # margins in points
my ($LineStart, $LineBottom);
my ($gfx, $txt, $gfx_border);
our ($pageNum,$filename); 

# other variables
my @FILES;            	# list of input files, in case of glob
my @INFILES;		# command line list of files and globs
my $destpath;           # destination path
my $outfile;          	# output path & file
my $help;               # Flag for displaying help

my $FontTypeStr;     	# C means Core, TT means TrueType.
my $FontNameStr;        # font name
my $fontsize;     	# font size
my $spacing;        	# spacing
my $CenterTextMode = 0; # Center the text.
my @tabs;		# any tab definitions

my $debug = 0;  	# no debug prints by default

if ($#ARGV < 0) {
	usage();
	exit(1);
}

# NOTE: A point is 1/72 inch (Adobe/PostScript Big Point).  
# Other environments use other slightly different values.
# any dimension may specify units (e.g., .5in), default units shown
# get those cmd line args!
my $opts_okay = GetOptions(
	'h'             => \$help,
	'help'          => \$help,		# Can use -h or --help
	'debug'		=> \$debug,		# print out diagnostic info
	'left=s'        => \$CLleft,		# Left Margin - points
	'right=s'       => \$CLright,		# Right Margin - points
	'top=s'         => \$CLtop,		# Top Margin - points
	'bottom=s'      => \$CLbottom,		# Bottom Margin - points
	'PGpaper=s'	=> \$CLPGpaper,		# named media (paper) size
	'PGwidth=s'	=> \$CLPGwidth,		# Page Width - inches
	'PGheight=s'	=> \$CLPGheight, 	# Page Height - inches
	'fontname=s'	=> \$CLFontName, 	# font name
	'fonttype=s'	=> \$CLFontType, 	# font type, C=Core, TT=TrueType
	'fontsize=s'    => \$CLfontsize, 	# Nominal height of characters - points
	'spacing=s'     => \$CLspacing, 	# Spacing between successive lines - points
	'l'             => \$CLlandscape,	# orientation
	'p'             => \$CLportrait,	# default orientation
	'tabs=s'	=> \$CLtabs,            # tabs layout
	'dir=s'         => \$CLdestpath
);
# positional parameters on command line:
# currently only one or more input names should be left
if ( 0 == @ARGV ) {
	warn "Expecting at least one positional parameter on command line: input file name or pattern\n";
	@INFILES = ();
	usage();
	exit(1);
} else {
	@INFILES = @ARGV;
}

# if help, then display usage
if ( !$opts_okay || $help ) { usage(); exit(0); }

# convert explicit units to desired units, or set defaults
if ( defined($CLleft) ) { $left = str2dim($CLleft, 'f[0,*)', 'pt'); }
  else { $left = $DEFleft; }
if ( defined($CLright) ) { $right = str2dim($CLright, 'f[0,*)', 'pt'); }
  else { $right = $DEFright; }
if ( defined($CLtop) ) { $top = str2dim($CLtop, 'f[0,*)', 'pt'); }
  else { $top = $DEFtop; }
if ( defined($CLbottom) ) { $bottom = str2dim($CLbottom, 'f[0,*)', 'pt'); }
  else { $bottom = $DEFbottom; }
if ( defined($CLPGwidth) ) { $PGwidth = str2dim($CLPGwidth, 'f(0,*)', 'in'); }
  else { $PGwidth = $DEFPGwidth; } 
if ( defined($CLPGheight) ) { $PGheight = str2dim($CLPGheight, 'f(0,*)', 'in'); }
  else { $PGheight = $DEFPGheight; }
if ( defined($CLfontsize) ) { $fontsize = str2dim($CLfontsize, 'f[3,100)', 'pt'); }
  else { $fontsize = $DEFfontsize; }
if ( defined($CLspacing) ) { $spacing = str2dim($CLspacing, 'f[4,115)', 'pt'); }
  else { $spacing = $fontsize * 1.15; }
if ( !defined($CLFontType) ) { $CLFontType = 'C'; }
if ( defined($CLFontName) ) { $FontNameStr = $CLFontName; }
  else { $FontNameStr = $DEFFontName; }
# CLPGpaper may remain empty if user wants to give height and width
if ( defined($CLPGpaper) ) { $PGpaper = $CLPGpaper; }
if ( !defined($CLdestpath) ) { $destpath = $DEFdestpath; } 
if ( !defined($CLlandscape) ) { $CLportrait = 1; }  # set default orientation
if ( defined($CLtabs) ) { @tabs = tabDef($CLtabs); }
  else { @tabs = tabDef($DEFtabs); }

# Check for filename vs. filespec(glob) * or ?
# build up final @FILES from @INFILES
@FILES = ();
foreach my $infile (@INFILES) {
	if ( $infile =~ m/\*|\?/ ) {
		# it's a glob that may expand to 1 or more files
		my @globList = ();
		print "Found glob spec '$infile', checking...\n" if $debug;
		@globList = glob($infile);
		if ( ! @globList ) {
			warn "File pattern '$infile' matches no files!\n";
		}
		if ($debug) {
			print "Found file";
			if ( $#globList > 0 ) { print "s"; }      # Be nice, use plural
			print ":\n";
			foreach ( @globList ) { print "$_\n"; }
		}
		push( @FILES, @globList );

	} else {
		# it's a filename that must exist
		if ( ! -f $infile ) {
			die "Could not locate file '$infile', exiting...\n";
		}
		push( @FILES, $infile );  # single file name
	}
} # loop through command line list of files and patterns

# remove duplicates
my %seen=();   # from StackOverflow 7651
@FILES = grep { ! $seen{$_} ++ } @FILES;
# check for no files given (found)
if (0 == @FILES) {
	die "Please specify at least one file name or glob on command line\n";
}

# Validate remaining cmd line args

if ($CLlandscape && $CLportrait) {
	die "ERROR: Had both portrait and landscape options on command line.\n";
}

# gave media name to override any page width and height?
# if named media not found, will return US Letter dimensions
if ( defined($CLPGpaper) ) {
	my @PaperSize = page_size($PGpaper);
	$PGwidth  = $PaperSize[2];
	$PGheight = $PaperSize[3];
}
# if landscape and height > width, rotate (swap height and width)
if ( $CLlandscape ) {
	if ($PGheight > $PGwidth) {
		my $t = $PGheight;
		$PGheight = $PGwidth;
		$PGwidth = $t;
	}
}
# if portrait and height < width, rotate (swap height and width)
if ( $CLportrait ) {
	if ($PGheight < $PGwidth) {
		my $t = $PGheight;
		$PGheight = $PGwidth;
		$PGwidth = $t;
	}
}

print "Page Width is $PGwidth.\n" if $debug;
print "Page Height is $PGheight.\n" if $debug;

### Validate Left and Right margins.
print "Left margin is $left.\n" if $debug;
print "Right margin is $right.\n" if $debug;
# The left and right margins need to leave some space to print.
# Some space is arbitrarily set at 1/8 inch, or 9 points.
die "ERROR: Left margin, right margin, and page width leave too little space to print.\n" 
	if ( $PGwidth <= ($left +$right + 9));

### Validate Top and Bottom margins.
print "Top Margin is $top.\n" if $debug;
print "Bottom Margin is $bottom.\n" if $debug;
# The top and bottom margins need to leave some space to print.
# Some space is arbitrarily set at 1/8 inch, or 9 points.
die "ERROR: top margin, bottom margin, and page height leave too little space to print.\n" 
	if ( $PGheight <= ($top +$bottom + 9));

my $PDFtop = $PGheight - $top;
my $PDFbottom = $bottom;

# Validate and set font type, font, font size, and spacing.
if ($fontsize <= 3) {
	die "ERROR: Font size $fontsize on command line is less than 3.\n";
}
if ($spacing < $fontsize) {
	die "ERROR: Line spacing $spacing on command line is less than font size.\n";
}
if ($CLFontType eq "C" || $CLFontType eq "TT") {
	$FontTypeStr = $CLFontType;
} else {
	die "ERROR: Font Type '$CLFontType' on command line is invalid.\n";
}

# Set max, min spacing
if ( $spacing > 720 ) { $spacing = 720;	}         # why would anyone want this much spacing?
if ( $spacing < 1   ) { $spacing = 1; 	}         # That's awfully crammed together...

foreach my $file ( @FILES ) {
  	print "Processing $file...\n";   # always output
	$pageNum = 0; $filename = $file;
  	my ($name,$dir,$suf) = fileparse($file,qr/\.[^.]*/);

	# set output file name (always .pdf, remove .txt or .txt2pdf)
  	if ( $suf =~ m/txt2pdf|txt/) {
  		# replace .txt or .txt2pdf with .pdf
    		$outfile = $destpath . $name . '.pdf';
  	} else {
  		# just append .pdf to end of filename
  		$outfile = $destpath . $name . $suf . '.pdf';
  	}

	$pdf = PDF::Builder->new(-file => $outfile);

	setfonts();	# Set the fonts.
	newpage();      # create first page in PDF document
	my $maxLineWidth = $PGwidth - $left - $right; # pts of line length

	print "Page Length data LineBottom $LineBottom - spacing $spacing - bottom $bottom \n" if $debug;
	my $minSpace;
	open (my $FILEIN, '<', "$file") or die "$file - $!\n"; ## no critic (RequireBriefOpen)
	while(<$FILEIN>) {
		# chomp is insufficient when dealing with EOL from different systems
    		# this little regex will make things a bit easier
    		s/(\r)|(\n)//g;

		if (m/^\.PAGE\s*=\s*([^;]+);/) {
			$minSpace = str2dim($1, 'f[0,*)', 'pt');
		} else {
			$minSpace = 0;
		}
		# found explicit page break or ran out of space?
   		if (m/\x0C/ || (m/^\.PAGE/ && $minSpace == 0) || 
		    (($LineBottom - $spacing - $bottom - $minSpace) < 0)) {
			FinishObjects();
			newpage();
	    		next if (m/\x0C/ || m/^\.PAGE/);  # ignore anything else on line
    		}

		my ($NewFontFound, $NewFont, $NewFontSizeFound, $NewFontSize,
		    $NewFontSpacingFound, $NewFontSpacing, $NewFontTypeStrFound);
		# .FONT [= font_name] [LEFT|CENTER] SIZE = num SPACING = num [TYPE = C|TT]
		if (m/^\.FONT /) {
			$NewFontFound = 0; $NewFont = '';
			$NewFontSizeFound = 0; $NewFontSize = 0;
			$NewFontSpacingFound = 0; $NewFontSpacing = 0;

			# Change Centering if asked.
			if (m/\sLEFT(\s|$)/) { $CenterTextMode = 0; }
			if (m/\sCENTER(\s|$)/) { $CenterTextMode = 1; }

			# Change the font.
			if (m/\.FONT\s*=\s*(\w+)(\W|$)/) {
				$NewFontFound = 1;
				$NewFont = $1;
				if (m/TYPE\s*\=\s*(\w+)(\W|$)/) {
					$NewFontTypeStrFound = 1;
					$FontTypeStr = $1;
				}
			}

			if (m/SIZE\s*=\s*(\d+)(\D|$)/) {
				$NewFontSizeFound = 1;
				$NewFontSize = $1; # default: pt
			}
			if (m/SIZE\s*=\s*'([^']+)'/) {
				$NewFontSizeFound = 1;
				$NewFontSize = str2dim($1, 'f(0,100)', 'pt');
			}
			if (m/SIZE\s*=\s*"([^"]+)"/) {
				$NewFontSizeFound = 1;
				$NewFontSize = str2dim($1, 'f(0,100)', 'pt');
			}

			if (m/SPACING\s*=\s*(\d+)(\D|$)/) {
				$NewFontSpacingFound = 1;
				$NewFontSpacing = $1;
			}
			if (m/SPACING\s*=\s*'([^']+)'/) {
				$NewFontSpacingFound = 1;
				$NewFontSpacing = str2dim($1, 'f(0,100)', 'pt');
			}
			if (m/SPACING\s*=\s*"([^"]+)"/) {
				$NewFontSpacingFound = 1;
				$NewFontSpacing = str2dim($1, 'f(0,100)', 'pt');
			}

			unless ($NewFontFound or $NewFontSizeFound or $NewFontSpacingFound) {
				warn "ERROR: No Font, Size, or Spacing given on .FONT line.\n";
				warn "ERROR Line: $_\n";
			}
			if ($NewFontFound) {
				$FontNameStr = $NewFont;
				setfonts();
			}
			$fontsize = $NewFontSize if ($NewFontSizeFound);
			$spacing = $NewFontSpacing if ($NewFontSpacingFound);
			$txt->font($font,$fontsize);
			next;

  		# .IMAGE FILE = image_filename HEIGHT = num WIDTH = num
		} elsif (m/^\.IMAGE /) {
			# Load a picture.  The picture file name is all.
			my ($imageFileName, $ImageFileSuff, $imageObj) = ();
			my ($imageHeight, $imageWidth, $imageUpDown, $ImageLeftRight) = ();
			my $Debug_Image_Placement = 0;

			$imageFileName = ''; $ImageFileSuff = '';
			$imageHeight = 0; $imageWidth = 0; 
			if (m/FILE\s*=\s*(\S+)(\s|$)/) {
				$imageFileName = $1;
			}

			if (m/HEIGHT\s*=\s*(\d+)(\D|$)/) { $imageHeight = $1; }
			if (m/HEIGHT\s*=\s*'([^']+)'/) { $imageHeight = $1; }
			if (m/HEIGHT\s*=\s*"([^"]+)"/) { $imageHeight = $1; }

			if (m/WIDTH\s*=\s*(\d+)(\D|$)/) { $imageWidth = $1; }
			if (m/WIDTH\s*=\s*'([^']+)'/) { $imageWidth = $1; }
			if (m/WIDTH\s*=\s*"([^"]+)"/) { $imageWidth = $1; }

			$imageFileName =~ m/\.([^.]+)$/;
			$ImageFileSuff = $1 || "";
			warn "ERROR: No image file name.\n" unless $imageFileName;
			warn "ERROR: No image width.\n" unless $imageWidth;
			warn "ERROR: No image height.\n" unless $imageHeight;
			warn "ERROR: No image file name suffix.\n" unless $ImageFileSuff;
			unless (-r $imageFileName && -s $_) {
				warn "ERROR: The file $imageFileName is either unreadable or empty.\n";
				next;
			}

    			if (($LineBottom - $imageHeight - $bottom) < 0) {
				# found page break - Not enough height for image.
				FinishObjects();
      				newpage();
    			}
			if ($ImageFileSuff =~ m/^jpg$|^jpeg$/i ) {
				$imageObj = $pdf->image_jpeg($imageFileName);
			} elsif ($ImageFileSuff =~ m/^tif$|^tiff$/i ) {
				$imageObj = $pdf->image_tiff($imageFileName);
			} elsif ($ImageFileSuff =~ m/^png$/i ) {
				$imageObj = $pdf->image_png($imageFileName);
			} elsif ($ImageFileSuff =~ m/^pnm$|^ppm$|^pgm$|^pbm$/i ) {
				$imageObj = $pdf->image_pnm($imageFileName);
			} else {
				warn "ERROR: The file $imageFileName is has an unsupported suffix.\n";
				next;
			}
			$imageHeight = ${${$imageObj}{'Height'}}{'val'} unless ($imageHeight);
			$imageWidth = ${${$imageObj}{'Width'}}{'val'} unless ($imageWidth);
			$imageUpDown = $LineBottom - $imageHeight;
			$ImageLeftRight = int(($PGwidth -$imageWidth) / 2);
			if ($Debug_Image_Placement) {
				print "LineBottom $LineBottom \n";
				print "imageHeight $imageHeight imageWidth $imageWidth \n";
				print "imageUpDown $imageUpDown ImageLeftRight $ImageLeftRight \n";
			}
			$gfx->image($imageObj, $ImageLeftRight, $imageUpDown, $imageWidth, $imageHeight );
			$LineBottom -= $imageHeight;
			$pointscount += $imageHeight;
			next;

		# not .FONT or .IMAGE special processing
		} else {
			# Print the line in $_, after expanding tabs.
			if (@tabs) {
				my ($i, $j);
				for ($i=0; $i<length($_); $i++) {
					# step through $_ looking for \x09
					# replace by spaces to next tab position

					# need to expand @tabs on new longest line?
					# $i+1 is character column
					while ($i+1 >= $tabs[-1]) {
						$tabs[1+$#tabs] = $tabs[-1] + ($tabs[-1]-$tabs[-2]);
					}

					if (substr($_, $i, 1) eq "\x09") {
						# $i+1 is character column
						# find next tab position
						for ($j=0; $j<$#tabs; $j++) {
							if ($tabs[$j] > $i+1) { last; }
						}
						# jth tab entry is tab position to go to
						# (replace HT by tabs[j]-(i+1) spaces)
						$_ = substr($_, 0, $i) .
						     (' ' x ($tabs[$j]-($i+1))) .
						     substr($_, $i+1 );
					}
				}
			}

			my $TextLineWidth = 0; my @overrides = ();
			# how much of line can fit at a time?
			$txt->font($font,$fontsize);
			my ($lineChunk, $char, $thisCont);
			my $continued = 0;  # NEXT output line is a continuation

			if (!length($_)) { $_ = " "; } # empty lines still print
			# there are probably faster ways to do this, than 
			# checking one character at a time, but in the spirit
			# of Quick'n'Dirty...
			while (length($_)) {
				$thisCont = $continued;
				$TextLineWidth = $txt->advancewidth($_, @overrides );
				if ($TextLineWidth > $maxLineWidth) {
					# maybe start at TLW/mLW fraction of line, and go up or down by character until hit limit?
					$lineChunk = '';
					$char = substr($_, 0, 1);
					$_ = substr($_, 1);
					while ($txt->advancewidth($lineChunk.$char, @overrides) <= $maxLineWidth) {
						$lineChunk .= $char;
						# prep for next loop
						$char = substr($_, 0, 1);
						$_ = substr($_, 1);
					}
					$_ = $char.$_;  # restore
					$continued = 1;
				} else {
					$lineChunk = $_;
					$_ = '';
					$continued = 0;
				}

				# mark a line as continued
				if ($thisCont) {
					#$txt->font($contline,$fontsize);
					if ($CenterTextMode <= 1) {
						$txt->textlabel($LineStart-1.7*$fontsize, $LineBottom-$spacing, $contline,$fontsize, chr(229));
					} else {
						$txt->textlabel($LineStart+$maxLineWidth+.6*$fontsize, $LineBottom-$spacing, $contline,$fontsize, chr(229));
					}
					#$txt->font($font,$fontsize);
				}

				if ($CenterTextMode == 1) {
					$txt->textlabel($LineStart+(int(($maxLineWidth - $TextLineWidth) /2 )),
							$LineBottom-$spacing,$font,$fontsize,$lineChunk);
				} else {
					$txt->textlabel($LineStart,$LineBottom-$spacing,$font,$fontsize,$lineChunk);
				}
				$LineBottom -= $spacing;
				$pointscount += $spacing;
			}
		}

  	} # while(<$FILEIN>)
  	close($FILEIN);
	FinishObjects();
  	$pdf->save();
	$pdf->end();
} # foreach $file (@FILES)

sub newpage {
	my ($Debug_newpage, $border_left, $border_bottom,
            $border_right, $border_top, $Draw_Border);
    	my ($text, $TextLineWidth);
	our ($pageNum);

	$pageNum++;
	$Debug_newpage = 0;
	$Draw_Border = 0;
	$page = $pdf->page();
	$page ->mediabox($PGwidth,$PGheight);
	$LineStart = $left;
	$LineBottom = $PGheight - $top;
	$pointscount = 0;
	$gfx=$page->gfx();
	$txt=$page->text();
	# Draw a border around the page.
	$border_left = int($left/2);
	$border_right = $PGwidth - int($right/2);
	$border_bottom = int($bottom/2);
	$border_top = $PGheight - int($top/2);
	if ($Debug_newpage) {
		warn "Debug newpage PGwidth $PGwidth PGheight $PGheight\n";
		warn "Margins left $left right $right top $top bottom $bottom\n";
		warn "Border  left $border_left right $border_right top $border_top bottom $border_bottom\n";
	}
	$gfx_border = $page->gfx();
	if ( $Draw_Border ) {
		$gfx_border->strokecolor('black');
		$gfx_border->move($border_left,$border_bottom);
		$gfx_border->line($border_left,$border_top);
		$gfx_border->line($border_right,$border_top);
		$gfx_border->line($border_right,$border_bottom);
		$gfx_border->close();
		$gfx_border->stroke();
	}

	setfonts();
	$txt->font($hdrftr,6);
	# if only one of the top and bottom margins large enough, print $pageNum
	# header (if $top at least 20pt) $filename centered
	$text = "\x97  $pageNum  \x97";
	$TextLineWidth = $txt->advancewidth($text);
	if ($top >= 20 && $bottom < 20) {
		# top gets pageNum
		$txt->textlabel($left+(int(($PGwidth - $left - $right - $TextLineWidth) /2 )),
			$PGheight - $top + 8,$hdrftr,6,$text);
	} elsif ($bottom >= 20) {
		# bottom gets pageNum
		$txt->textlabel($left+(int(($PGwidth - $left - $right - $TextLineWidth) /2 )),
			$bottom - 14,$hdrftr,6,$text);
	}
	if ($top >= 20 && $bottom >= 20) {
		# top gets file
		$TextLineWidth = $txt->advancewidth($filename);
		$txt->textlabel($left+(int(($PGwidth - $left - $right - $TextLineWidth) /2 )),
			$PGheight - $top + 8,$hdrftr,6,$filename);
	}
	# body text font
	$txt->font($font,$fontsize);
	return;
} # end of newpage()

sub FinishObjects {
	$pdf->finishobjects($page,$gfx);
	return;
}

sub setfonts {
	if ($FontTypeStr eq "TT") {
		$font = $pdf->ttfont($FontNameStr, -encode => 'latin1');
	} elsif ($FontTypeStr eq "C") {
		$font = $pdf->corefont($FontNameStr, -encode => 'latin1');
	} else {
		die "ERROR: Incorrect Font Type string is $FontTypeStr.\n";
	}

	# for headers and footers
	$hdrftr = $pdf->corefont("Helvetica-Bold", -encode => 'latin1');
	# for continuation line
	$contline = $pdf->corefont("ZapfDingbats", -encode => 'latin1');
	return;
}

# given a tab definition string such as '9 17', expand it into an array
# 0 or more than 1 elements: 1 element not permitted
sub tabDef {
	my ($string) = @_;

	my @tabs;

	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	@tabs = split /\s+/, $string;
	if (@tabs == 1) { die "Error: --tabs must have 0, or 2 or more elements\n"; }
	return @tabs;
}

sub usage {
	my $message = <<"END_OF_USAGE";

Options:

  ## values may be bare numbers (units are as described), or number with unit
     (mm, cm, in, pt, ppt, pc, dd, cc) ppt = printer's points 72.27/inch,
     dd = Didot points 67.5532/inch, cc = Ciceros 5.62943/inch

  -h, --help       This help page
  --debug 	   Print out internal data for diagnostic purposes

  --dir=pathname   Specify destination pathname of the pdf file.

  --left=##        Specify left margin in points. 72 points = 1 inch
  --right=##       Specify right margin in points. 72 points = 1 inch
  --top=##         Specify top margin in points. 36 points = .5 inch
  --bottom=##      Specify bottom margin in points. 36 points = .5 inch

  --fontname=ss    Specify the Fontname. Default is TimesBold.
  --fonttype=ss    Specify the font type. C means Core. TT means TrueType.
                     The default is C.
  --fontsize=##    Specify font size, nominal height of characters (points).
                     The default is 7.
  --spacing=##     Specify spacing between lines (points).

  -l, -L           Set doc to landscape, (wider than tall). Default is portrait.
  -p, -P           Set doc to portrait, (taller than wide). This is the default.

  --PGpaper=name   Specify the page dimensions by named paper (media) size, or
  --PGheight=##      Specify the page height (inches).
  --PGwidth=##       Specify the page width (inches).
  
  --tabs=ss        Specify 0, or two or more tab stops (column numbers). The
                     list will be automatically expanded as needed by the 
		     increment of the last two elements given.

  Forcing a form feed (new page).
  General form feed line:
  .PAGE [= minimum remaining space;]   Note that semicolon required.
    .PAGE by itself always starts a new page.
    With a dimension, if the remaining vertical space is less than this
      (default unit: pt points), a new page will be started.
    A Form Feed character (0x0C) may be used instead of .PAGE.
    Any other text on the line with the form feed or .PAGE will be ignored.

  Changing fonts in the text file.
  General Font change line:
  .FONT [= font_name] [LEFT|CENTER] SIZE = ### SPACING = ### [TYPE = C|TT]
    All keywords and values are case sensitive.
    The keyword .FONT starts with the first character in the line.
    The "= font_name" must immediately follow the FONT keyword. It is optional.
    LEFT or CENTER are optional, and may be in any order.
      LEFT means left-justify the text.
      CENTER means center-justify the text.
    The SIZE parameter is the font size for the text (points).
      It may be an integer or number and unit in single ' or double " quotes.
    The SPACING paramter sets the space (leading) between lines (points).
      It may be an integer or number and unit in single ' or double " quotes.
      SIZE=8 SPACING=16 is like double line spacing.
    The TYPE keyword is for choosing a Core font, or True Type font.
    The TYPE keyword is ignored unless a "= font_name" is given. 
    Using bold, italics, or going back to normal is done by changing 
      the font name.  There is no bold, or italics flag.
    Any extra text on the font change line is ignored.

  Inserting an image in the text file.
  General Image insertion line:
  .IMAGE FILE = image_filename HEIGHT = num WIDTH = num
    Errors in the image insertion line are written to the error output,
      and the line is ignored.
    The suffix of the image_filename is used to determine the image type.
    The suffixes jp[e]g, tif[f], png, pnm, ppm, pgm, and pbm are supported.
    The HEIGHT and WIDTH are in points, or 'number unit' or "number unit", 
      and optional.
    The default values are the height and width of the image in pixels.
    The defaults are most useful if the images are at 72 pixels per inch.
    The images are always printed, center justified.

  Special thanks to Michael Collins for getting me started.
  Special thanks to Alfred Reibenschuh for such a cool Perl module!
  Also, many thanks to the PDF::API2 community for such great ideas.

END_OF_USAGE
	print "\nUsage:\n\n";
        print $0, " ";
	print "\[options\] \<source file name or pattern\>...\n";
	print $message;
  return;
}

__END__
