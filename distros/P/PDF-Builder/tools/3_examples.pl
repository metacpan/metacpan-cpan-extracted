#!/usr/bin/perl
# run examples test suite
# roughly equivalent to examples.bat
#   you will need to update the %args list before running
# author: Phil M Perry

use strict;
use warnings;

our $VERSION = '3.024'; # VERSION
our $LAST_UPDATE = '3.018'; # manually update whenever code is changed

# dependent on optional packages:
my $HS_installed = 1; # HarfBuzz::Shaper IS installed and you want to use it.
                      # will quit if Shaper not installed!
                      # note that you will likely need to update font file list

# command line:
#   -step  = stop after each test to let the tester look at the PDF file
#   -cont  = (default) run continuously to the end, to not tie up tester
my $pause;

my (@example_list, @example_results);
  push @example_list, "011_open_update";
  push @example_results, "create examples/011_open_update.BASE.pdf with one 'Hello World' page\n examples/011_open_update.UPDATED.pdf with 'Hello World (2)' added\n examples/011_open_update.STRING.pdf with 'Hello World (3)' and (4) added.\n";

  push @example_list, "012_pages";
  push @example_results, "create examples/012_pages.pdf with pages i..iii, 1, 9, 2..8.\n";

  push @example_list, "020_corefonts";
  push @example_results, "create examples/020_corefonts.<font name>.<encoding>.pdf for each core font,\n each of one or more pages of characters.\n";

  push @example_list, "020_textrise";
  push @example_results, "create examples/020_textrise.pdf, one page showing + and - text rise examples.\n";

  push @example_list, "020_textunderline";
  push @example_results, "create examples/020_textunderline.pdf, one page showing sample underlined text.\n";

  # require provision of a Type 1 font in %args
  push @example_list, "021_psfonts";
  push @example_results, "create examples/021_psfonts.<font name>.<encoding>.pdf,\n showing one or more pages of characters and Lorem Ipsum text.\n";

  push @example_list, "021_synfonts";
  push @example_results, "create examples/021_synfonts.<core font name>.pdf, showing one or more pages\n of characters, for each of 4 variants, and Lorem Ipsum text.\n";

  # require provision of a TTF font in %args
  push @example_list, "022_truefonts";
  push @example_results, "create examples/022_truefonts.<font name>.pdf, showing one or more pages\n of characters and Lorem Ipsum text.\n";

  # require provision of a TTF font in %args
  push @example_list, "022_truefonts_diacrits_utf8";
  push @example_results, "create examples/022_truefonts_diacrits_utf8.<font name>.pdf, showing one\n page of characters and a page with a combining diacritic.\n";

  push @example_list, "023_cjkfonts";
  push @example_results, "create examples/023_cjkfonts.<font name>.pdf, showing many pages of characters\n and a page of Lorem Ipsum text for each of 4 variants (regular, bold, italic,\n and bold-italic. Note that Latin text may be proportional or fixed pitch.\n";

  # require provision of a BDF font in %args
  push @example_list, "024_bdffonts";
  push @example_results, "create examples/024_bdffonts.<font name>.pdf, showing one page of 256 glyphs\n and a page of Lorem Ipsum text.\n";

  push @example_list, "025_unifonts";
  push @example_results, "create examples/025_unifonts.pdf, with the first 45 lines of an attached PDF-J\n file in four different Western + CJK fonts. Don't worry about long lines\n running off the right margin.\n";

  push @example_list, "026_unifont2";
  push @example_results, "create examples/026_unifont2.pdf, showing pages with labeled sections and\n full descriptive name on each character.\n";

# push @example_list, "027_winfont";
# push @example_results, "create examples/027_winfont.pdf. It has been removed (put in Windows directory for now)";

  push @example_list, "030_colorspecs";
  push @example_results, "create examples/030_colorspecs.pdf, showing many color models with\n a large sample of colors each, including named colors.\n";

  push @example_list, "031_color_hsv";
  push @example_results, "create examples/031_color_hsv.pdf, showing the HSV color model\n a large sample of colors.\n";

  push @example_list, "032_separation";
  push @example_results, "create examples/032_separation.pdf, showing the CMYK color separations\n (on one page) for printer use.\n";

  push @example_list, "040_annotation";
  push @example_results, "create examples/040_annotation.pdf, showing some text annotations.\n If you interact with the page, you will be asked if you want to save it\n when leaving (no need to do so).\n";

  push @example_list, "041_annot_fileattach";
  push @example_results, "create examples/041_annot_fileattach.pdf, showing some attached file\n annotations. Depending on your OS, Reader, and permission settings,\n you may not be allowed to open some files, or have to select a reader.\n";

  push @example_list, "042_links";
  push @example_results, "create examples/042_links.pdf, showing some examples of linking from \na PDF to other pages, other PDFs, and even other things such as browser pages.\n";

  push @example_list, "050_pagelabels";
  push @example_results, "create examples/050_pagelabels.pdf, showing a number of pages, each with its\n own page label in different formats. You will see them when you drag the\n vertical scroll thumb and you see a thumbnail of each page,\n each with its own label.\n";

  push @example_list, "055_outlines";
  push @example_results, "create examples/055_outlines_sample_55.pdf, showing a 12 page document.\n Click on the \"bookmark\" icon to see three pages in the outline, where you\n can click to jump to any of them.\n";

  push @example_list, "060_transparency";
  push @example_results, "create examples/060_transparency.pdf, showing 2 pages with red opaque text\n partly covered by 40% transparent black text.\n";

  push @example_list, "BarCode.pl";
  push @example_results, "create examples/BarCode.pdf, showing 1 page with some bar code samples.\n It appears that the BarCodes need some more work.\n";

  push @example_list, "Boxes.pl";
  push @example_results, "create examples/Boxes.pdf, showing multiple pages on the effect\n of different PDF \"boxes\".\n";

  push @example_list, "Bspline.pl";
  push @example_results, "create examples/Bspline.pdf, showing 4 pages with some annotated examples of\n using (cubic) B-splines to draw smoothly-connected lines through all the\n given points.\n";

  push @example_list, "Content.pl";
  push @example_results, "create examples/Content.pdf, showing multiple pages demonstrating the\n capabilities of the Content.pm library methods (graphics and text).\n";

  push @example_list, "ContentText.pl";
  push @example_results, "create examples/ContentText.pdf, showing multiple pages demonstrating the\n capabilities of the Content/Text.pm library advanced text methods.\n";

 if ($HS_installed) {
  push @example_list, "HarfBuzz.pl";
  push @example_results, "create examples/HarfBuzz.pdf, showing raw text output through text(), and\n the equivalent text output by textHS() after processing by HarfBuzz::Shaper.\n";
 }

  push @example_list, "RMtutorial.pl";
  push @example_results, "create examples/RMtutorial.pdf, demonstrating very basic usage of\n PDF::Builder text and graphics.\n";

  push @example_list, "Rotated.pl";
  push @example_results, "create examples/Rotated.pdf, showing a way of embedding rotated pages\n within a document of unrotated pages.\n";

  # require provision of a core font in %args
  push @example_list, "ShowFont.pl";
  push @example_results, "create examples/ShowFont.<type>.<font name>.pdf, showing multiple pages\n demonstrating the display of various encodings.\n";
 
# push @example_list, "examples/Windows/027_winfont.pl";
# push @example_results, "create examples/Windows/027_winfont.<type>.<font name>.pdf, showing multiple pages\n demonstrating the display of various encodings.\n";
 
# run with perl examples/<file> [args]

my %args;
# if you do not define a file for a test (leave it EMPTY ''), it will be skipped
# if any spaces in a path, make sure double quoted or use escapes
#
# 021_psfonts needs T1 glyph and metrics files (not included)
# assuming metrics file (.afm or .pfm) is in same directory
  $args{'021_psfonts'} = "/Users/Phil/T1fonts/URWPalladioL-Roma.pfb";
# 022_truefonts needs a TTF or OTF font to do its thing
  $args{'022_truefonts'} = "/WINDOWS/fonts/times.ttf";
# 022_truefonts_diacrits_utf8 needs a TTF or OTF font that includes a
# diacritic (combining accent mark) to do its thing
  $args{'022_truefonts_diacrits_utf8'} = "/WINDOWS/fonts/tahoma.ttf";
# 024_bdffonts needs a sample BDF (bitmapped font), which is not
# included with the distribution
  $args{'024_bdffonts'} = "/Users/Phil/BDFfonts/codec/codec.bdf";
# ShowFont.pl needs a corefont (by default) font name
  $args{'ShowFont.pl'} = "Helvetica";

my $type;
# one command line arg allowed (-cont is default)
if      (scalar @ARGV == 0) {
    $type = '-cont';
} elsif (scalar @ARGV == 1) {
    if      ($ARGV[0] eq '-step') {
        $type = '-step';
    } elsif ($ARGV[0] eq '-cont') {
	# default
        $type = '-cont';
    } else {
	die "Unknown command line argument '$ARGV[0]'\n";
    }
    splice @ARGV, 0, 1;  # remove command line arg so <> will work
} else {
    die "0 or 1 argument permitted. -cont is default.\n";
}

$pause = '';
# some warnings:
foreach my $test (@example_list) {
    if ($test eq '023_cjkfonts') {
        print "$test: to display the resulting PDFs, you may need to install\n";
        print "  East Asian fonts for your PDF reader.\n";
        $pause = ' ';
    }
}
if ($pause eq ' ') {
    print "Press Enter to continue: ";
    $pause = <>;
}

print STDERR "\nStarting example runs...";

my ($i, $arg);
for ($i=0; $i<scalar(@example_list); $i++) {
    my $file = $example_list[$i];
    my $desc = $example_results[$i];

    if (defined $args{$file}) {
	$arg = $args{$file};
	if ($arg eq '') {
	    print "test examples/$file skipped at your request\n";
	    next;
	}
    } else {
        $arg = '';
    }
    print "\n=== Running test examples/$file $arg\n";
    print $desc;

    system("perl examples/$file $arg");

    if ($type eq '-cont') { next; }
    print "Press Enter to continue: ";
    $pause = <>;
}

print STDERR "\nAfter examining files (results), do NOT erase files \n";
print STDERR "  examples/011_open_update.BASE.pdf\n";
print STDERR "  examples/012_pages.pdf\n";
print STDERR "  examples/011_open_update.UPDATED.pdf\n";
print STDERR "if you are going to run 4_contrib.pl\n";
print STDERR "\nAll other examples output PDF files may be erased.\n";
