#!/usr/bin/perl
# list a font file's contents
# outputs ShowFont.<type>.<fontname>.pdf
# run without arguments to get help listing
# author: Phil M Perry

use strict;
use warnings;

our $VERSION = '3.025'; # VERSION
our $LAST_UPDATE = '3.024_002'; # manually update whenever code is changed

use PDF::Builder;
use utf8;
use Carp;

my $do_noncore = 1; # TTF, etc., will require manual update before running!
my $dump = 1; # debug dump of font data

my $name = $0;
$name =~ s/\.pl$/.pdf/; # write into examples directory

my ($page, $text, $grfx);
my $pdf = PDF::Builder->new('compress' => 'none');
# a font to use that doesn't hit anything in FontManager
#my $exmpl_font = $pdf->corefont('Helvetica');

# page 1
$page = $pdf->page();
$text = $page->text();
#$grfx = $page->gfx();

if ($dump) {
    print "=================================================================\n";
    print "=== dump initial state of FontManager before doing anything else.\n";
    # note that this prints to STDOUT, not to the PDF
    $pdf->dump_font_tables();
}

# we have the default core fonts loaded. put out a little text
my ($x,$y, $xcur, $word, $width, @textwords);
$x = 50; $y = 700;
my $colwidth = 400;
my $font_size = 20;
my $leading = 1.1 * $font_size;
$xcur = $x; # x,y is start of current line, xcur,y is where we are in line

if ($dump) { print "**** Times Roman\n"; }
# should be current font (core, Times Roman)
$text->font($pdf->get_font('italic'=>0), $font_size);
my $space_w = $text->advancewidth(' ');
@textwords = split / /, "Start out in normal text. Now switch";
while (@textwords) {
    ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
}

if ($dump) { print "**** Times Italic\n"; }
$text->font($pdf->get_font('italic'=>1), $font_size);
$space_w = $text->advancewidth(' ');
@textwords = split / /, "from normal to italic text.";
while (@textwords) {
    ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
}

if ($dump) { print "**** Times Roman\n"; }
# back to Roman. could add 'bold'=>0 to be certain
$text->font($pdf->get_font('italic'=>0), $font_size);
$space_w = $text->advancewidth(' ');
@textwords = split / /, "And back to Roman (normal).";
while (@textwords) {
    ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
}

if ($dump) { print "**** Times Bold\n"; }
$text->font($pdf->get_font('bold'=>1), $font_size);
$space_w = $text->advancewidth(' ');
@textwords = split / /, "Does BOLD get your attention?";
while (@textwords) {
    ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
}

if ($dump) { print "**** Times BoldItalic\n"; }
$text->font($pdf->get_font('italic'=>1), $font_size);
$space_w = $text->advancewidth(' ');
@textwords = split / /, "Then how about bold AND italic?";
while (@textwords) {
    ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
}

if ($dump) { print "**** Times Roman\n"; }
$text->font($pdf->get_font('italic'=>0, 'bold'=>0), $font_size);
$space_w = $text->advancewidth(' ');
@textwords = split ' ', "OK, too much excitement. Back to plain old Roman.";
while (@textwords) {
    ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
}

# start next paragraph
$y -= 3*$leading;
$xcur = $x;

if ($dump) {
    print "=================================================================\n";
    print "=== dump state of FontManager after playing with Times face.\n";
    # note that this prints to STDOUT, not to the PDF
    $pdf->dump_font_tables();
}

if ($dump) { print "**** Helvetica (sans serif)\n"; }
$text->font($pdf->get_font('face'=>'sans-serif', 'italic'=>0, 'bold'=>0), $font_size);
$space_w = $text->advancewidth(' ');
@textwords = split / /, "Take the default sans serif face, which is Helvetica.";
while (@textwords) {
    ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
}

if ($dump) { print "**** Courier\n"; }
$text->font($pdf->get_font('face'=>'Courier'), $font_size);
$space_w = $text->advancewidth(' ');
@textwords = split / /, "No? Then how about typewriter output (Courier)?";
while (@textwords) {
    ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
}

if ($dump) { print "**** Symbol\n"; }
$text->font($pdf->get_font('face'=>'Symbol'), $font_size);
$space_w = $text->advancewidth(' ');
@textwords = split / /, "Any idea what this says, like whazzup, dude?";
while (@textwords) {
    ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
}

if ($dump) { print "**** Helvetica\n"; }
$text->font($pdf->get_font('face'=>'Helvetica'), $font_size);
$space_w = $text->advancewidth(' ');
@textwords = split / /, "And this looks like the signs in the NYC subway.";
while (@textwords) {
    ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
}

if ($dump) { print "**** default font\n"; }
$text->font($pdf->get_font('face'=>'default'), $font_size);
$space_w = $text->advancewidth(' ');
@textwords = split / /, "Back to the default face (Times).";
while (@textwords) {
    ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
}

if ($do_noncore) {
    if ($dump) { print "**** Georgia\n"; }
    # CAUTION: face may need to be changed on non-Windows systems
    $text->font($pdf->get_font('face'=>'Georgia'), $font_size);
    $space_w = $text->advancewidth(' ');
    @textwords = split / /, "And finally, I've got Georgia on my mind...";
    while (@textwords) {
        ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
    }
}

if ($dump) {
    print "=================================================================\n";
    print "=== dump state of FontManager after face switching.\n";
    # note that this prints to STDOUT, not to the PDF
    $pdf->dump_font_tables();
}

# now to load in some non-core fonts. you will need to update these!
if ($do_noncore) {
    # codec BDF
    if ($pdf->add_font('face' => 'Codec', 'type' => 'bdf', 
		       'style' => 'sans-serif', 'width' => 'constant', 
		       'settings' => { 'encode' => 'iso-8859-1' },
		       'file' => { 'roman' => 'codec/codec.bdf' } )) {
        carp "Something went sideways trying to add BDF font to list.";
    }
    # URW PalladioL-Roma T1
    if ($pdf->add_font('face' => 'Palladio', 'type' => 'type1', 
		       'style' => 'serif', 'width' => 'proportional', 
		       'settings' => { 'encode' => 'iso-8859-1',
		                       'afmfile' => 'URWPalladioL-Roma.afm' },
		       'file' => { 'roman' => 'URWPalladioL-Roma.pfb' } )) {
        carp "Something went sideways trying to add T1 font to list.";
    }
    # DejaVu Sans TTF
    if ($pdf->add_font('face' => 'DejaVuSans', 'type' => 'ttf', 
		       'style' => 'sans-serif', 'width' => 'proportional', 
		       'settings' => { 'encode' => 'utf8' },
		       'file' => { 'roman' => 'DejaVuSans.ttf',
		                   'italic' => 'DejaVuSans-Oblique.ttf',
			           'bold' => 'DejaVuSans-Bold.ttf',
			           'bold-italic' => 'DejaVuSans-BoldOblique.ttf' } )) {
        carp "Something went sideways trying to add TTF font to list.";
    }
    # Adobe Gothic Standard (Chinese) CJK
    if ($pdf->add_font('face' => 'Chinese', 'type' => 'ttf', 
		       'style' => 'serif', 'width' => 'proportional', 
		       'settings' => { 'encode' => 'utf8' },
		       'file' => { 'roman' => '/Program Files/Adobe/Acrobat DC/Resource/CIDFont/AdobeGothicStd-Light.otf' } )) {
        carp "Something went sideways trying to add CJK font to list.";
    }

    # FR SCRIPT script font
    if ($pdf->add_font('face' => 'FRscript', 'type' => 'ttf', 
		       'style' => 'sans-serif', 'width' => 'proportional', 
		       'settings' => { 'encode' => 'utf8' },
		       'file' => { 'roman' => 'FRSCRIPT.TTF' } )) {
        carp "Something went sideways trying to add script font to list.";
    }

    # and load some local font search paths. you will need to update these!
    # currently, these paths are NOT checked/validated upon entry!
    # Windows predefined /WINDOWS/Fonts for TTF
    my @fontpaths;

    # ==== type1 (PS)
    push @fontpaths, "C:/Users/Phil/fonts/T1fonts";  # Windows absolute path with drive letter
    # URW Bookman for MikTex (Windows)
    push @fontpaths, "/Program Files/MikTex 2.9/fonts/type1/urw/bookman";
    # URW Bookman for older versions of MikTex (Windows)
    push @fontpaths, "/Program Files (x86)/MikTex 2.9/fonts/type1/urw/bookman";
    # ==== BDF (bitmapped)
    push @fontpaths, "/Users/Phil/fonts/BDFfonts";
    # ==== CJK (Chinese)
    push @fontpaths, "/Program Files/Adobe/Acrobat DC/Resource/CIDFont";

    while (@fontpaths) {
        my $path = shift @fontpaths;
        if ($pdf->add_font_path($path)) {
            print "Something went wrong with adding path '$path'\n";
        }
    }

    if ($dump) {
        print "=================================================================\n";
        print "=== dump state of FontManager after adding more fonts.\n";
        # note that this prints to STDOUT, not to the PDF
        $pdf->dump_font_tables();
    }
    # start next paragraph
    $y -= 3*$leading;
    $xcur = $x;

    if ($dump) { print "**** default font\n"; }
    $text->font($pdf->get_font('face'=>'default'), $font_size);
    $space_w = $text->advancewidth(' ');
    @textwords = split / /, "Start with the default face (core Times).";
    while (@textwords) {
        ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
    }

    if ($dump) { print "**** DejaVu Sans TTF font\n"; }
    $text->font($pdf->get_font('face'=>'DejaVuSans'), $font_size);
    $space_w = $text->advancewidth(' ');
    @textwords = split / /, "Switch to DejaVu Sans, also in";
    while (@textwords) {
        ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
    }
    $text->font($pdf->get_font('face'=>'DejaVuSans', 'italic'=>1), $font_size);
    $space_w = $text->advancewidth(' ');
    @textwords = split / /, "italic,";
    while (@textwords) {
        ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
    }
    $text->font($pdf->get_font('face'=>'DejaVuSans', 'italic'=>0, 'bold'=>1), $font_size);
    $space_w = $text->advancewidth(' ');
    @textwords = split / /, "bold,";
    while (@textwords) {
        ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
    }
    $text->font($pdf->get_font('face'=>'DejaVuSans', 'italic'=>1), $font_size);
    $space_w = $text->advancewidth(' ');
    @textwords = split / /, "and both.";
    while (@textwords) {
        ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
    }
    # remember that both italic and bold flags are set

    if ($dump) { print "**** Palladio Type1 font\n"; }
    $text->font($pdf->get_font('face'=>'Palladio', 'italic'=>0, 'bold'=>0), $font_size);
    $space_w = $text->advancewidth(' ');
    @textwords = split / /, "Now try out a Type 1 (PostScript) font named PalladioL, from URW.";
    while (@textwords) {
        ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
    }

    if ($dump) { print "**** Codec BDF (bitmapped) font\n"; }
    $text->font($pdf->get_font('face'=>'Codec'), $font_size);
    $space_w = $text->advancewidth(' ');
    @textwords = split / /, "This should be ugly: X11 bitmapped Codec font.";
    while (@textwords) {
        ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
    }

    if ($dump) { print "**** Adobe Gothic CJK (Chinese) font\n"; }
    $text->font($pdf->get_font('face'=>'Chinese'), $font_size);
    $space_w = $text->advancewidth(' ');
    @textwords = split / /, "And finally, a sample of CJK (e.g., Chinese) text output: \x{4F7F}\x{7528}\x{9019}\x{500B}\x{FF08}\x{66F4}\x{767D}\x{7684}\x{7259}\x{9F52}\x{FF09}\x{3002}";
    while (@textwords) {
        ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
    }

    if ($dump) { print "**** FRSCRIPT script font\n"; }
    $text->font($pdf->get_font('face'=>'FRscript'), $font_size);
    $space_w = $text->advancewidth(' ');
    @textwords = split / /, "Let's try a possible script font.";
    while (@textwords) {
        ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
    }
    $pdf->font_settings('script' => 'FRscript'); # make it the new default script
    $text->font($pdf->get_font('face'=>'default'), $font_size);
    $space_w = $text->advancewidth(' ');
    @textwords = split / /, "Indeed, it was script.";
    while (@textwords) {
        ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
    }
    $text->font($pdf->get_font('face'=>'script'), $font_size);
    $space_w = $text->advancewidth(' ');
    @textwords = split / /, "Have some more!";
    while (@textwords) {
        ($xcur,$y, @textwords) = output($text, $xcur,$y, $x,$x+$colwidth, $space_w, $leading, @textwords);
    }

    if ($dump) {
        print "=================================================================\n";
        print "=== dump state of FontManager after non-core fonts used.\n";
        # note that this prints to STDOUT, not to the PDF
        $pdf->dump_font_tables();
    }
} # non-core samples, likely requiring manual updates

$pdf->saveas($name);

# output a stream of words on THIS line, returning unused portion.
# for now, not worrying about running off bottom of page!
sub output {
    my ($text, $xcur, $y, $x, $max_x, $space, $leading, @words) = @_;

    $text->translate($xcur,$y); # only need to do at start of string
    while (@words) {
	$word = shift @words;
        $width = $text->advancewidth($word);
        if ($xcur+$width > $max_x) {
            # need to split text. for now, just fit whole words
	    unshift @words, $word;
	    $y -= $leading; # for now, not checking if go off bottom!
	    $xcur = $x; # start of new line
            return ($xcur,$y, @words);
	}

	# there is room for at least one more word on this line
	# we will put down TRAILING space after a word. let's not worry
	# for now whether this space actually exceeds right margin, as
	# it's invisible anyway.
	$text->text($word.' ');
	$xcur += $width+$space;
    }

    # we used up all the words without filling the line? return
    return ($xcur,$y, @words);
}

