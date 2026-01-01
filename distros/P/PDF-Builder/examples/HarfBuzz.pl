#!/usr/bin/perl
# demonstrate some usage of HarfBuzz::Shaper and related text calls
# outputs HarfBuzz.pdf
# author: Phil M Perry

use strict;
use warnings;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.028'; # manually update whenever code is changed

my $PDFname = $0;
   $PDFname =~ s/\..*$//;  # remove extension such as .pl
   $PDFname .= '.pdf';     # add new extension pdf

use PDF::Builder;

# do NOT attempt to run unless HarfBuzz::Shaper is installed
# (should fail gracefully with message)
my $rc;
$rc = eval {
    require HarfBuzz::Shaper;
    1;
};
if (!defined $rc) { $rc = 0; } # else is 1
if ($rc == 0) {
    print STDERR "HarfBuzz::Shaper does not appear to be installed. Not running HarfBuzz.pl\n";
    exit;
}

my $dokern = 1; # ttfont defaults -dokern to 0, Shaper to 1
my $doliga = 1; # built-in ligatures

my $fontsize = 20;
my $dump = 0; # 1 to dump Shaper data, 0 no
my $showNextWrite = 1; # 1 to write | after text (at next position)
my $strike = 'none';  # or 'auto' strikethrough
my $under = 'none';  # or 'auto' underlining (only for alignment examples)
my $leading = 1.6; # baseline-to-baseline * font size

my $latinFont =   # for kerning, ligature demos
  # '/WINDOWS/Fonts/times.ttf';
  # '/WINDOWS/Fonts/arial.ttf';
    '/Users/philp/AppData/Local/Microsoft/Windows/Fonts/NimbusRoman-Regular.otf';
my $ligFont =     # for full ligature list, Shaper ignores
  # $latinFont;
  # '/Users/philp/AppData/Local/Microsoft/Windows/Fonts/NimbusRoman-Regular.otf';
  # '/WINDOWS/Fonts/verdana.ttf';
  # '/WINDOWS/Fonts/arial.ttf';
    '/WINDOWS/Fonts/times.ttf';  # missing fj, ij, and et
my $arabicFont = '/Program Files/Adobe/Acrobat DC/Resource/Font/AdobeArabic-Regular.otf';
# You will certainly have to modify the font file locations and names
# per your local installation and operating system, here and below in %samples.
# Some .ttf fonts may be usable by HarfBuzz for shaping, but others don't seem
# to be.

my $pdf = PDF::Builder->new(-compress => 'none');
#my $pdf = PDF::Builder->new();

$pdf->mediabox('universal');  # narrower and shorter of US letter and A4, so
                              # it should be printable on either paper
my $labelFont = $pdf->corefont('Helvetica');
my ($font);

# A collection of text in various scripts. Non-Latin (English) lines include
# "PDF::Builder" chunks in the middle, to demonstrate switching back and forth
# of scripts, and that LTR text like that stays in that direction even when the
# rest of the line is RTL (Arabic, Hebrew).
#
# The top line of each pair outputs the raw text (Unicode points) WITHOUT 
# HarfBuzz::Shaper modifying it, using the normal text() method. There is no 
# shaping. The bottom line uses HarfBuzz::Shaper to rearrange and substitute 
# characters (details below). Some of the glyphs may not have Unicode points.

my %samples = (
   # Demonstrate ligatures in a Latin script, assuming you haven't disabled
   # ligatures with $doliga = 0. 'ft', 'ffl', and 'fi' may have ligatures
   # available in the font, although 'fi' is the only common one. 'ff' is 
   # another commonly available ligature, but here it is disabled with a ZWNJ
   # (Zero Width Non Joiner U+200C) between the f's. Some fonts may respond
   # instead to a ZWJ (Zero Width Joiner U+200D), so you might need to change
   # the text if you change fonts. The ZWNJ is removed if ligatures are 
   # disabled, otherwise a space is left between the f's!
   'LatinL' => { 'title' => "LatinL",  # are ligatures done?
	         'fontFile' => $latinFont,
		 'dir' => 'L',
		 'script' => 'Latn',
		# ft, ffl, fi ligatures desired, if available; ff no ligature!
	 	# might have to insert ZWNJ (U+200C) between f-f
		# ZWNJ (U+200c) text() renders as full space, Shaper renders
		#   as full space but advance = 0
		# ZWJ (U+200d) text() renders as full space, Shaper renders
		#   as ff legature PLUS full space, advance = 0
	         'text' => ["Eat soft waffles in a field, read a shelf\x{200c}ful of books"] },

   # Demonstrate all Unicode ligatures in a Latin script. Not all will be 
   # available in a given font. note that Shaper is not used for ligatures!
   # It also seems to ignore most or all ligatures in .ttf fonts.
   'LatinL2' => { 'title' => "LatinL2",
	          'fontFile' => $ligFont,
		  'dir' => 'L',
		  'script' => 'Latn',
		  'specials' => 1, # -liga plus call Builder filter
		  # ss/eszett sz/eszett 'n/'n, ff fi fl fj oo
	          'text' => ["strasse strasze R 'n R staff fish flow fjord good"] },
   'LatinL3' => { 'title' => "LatinL3",
	          'fontFile' => $ligFont,
		  'dir' => 'L',
		  'script' => 'Latn',
		  'specials' => 1, # -liga plus call Builder filter
		  # long-st st aa ao au av ay et
	          'text' => ["mo\x{017f}t fast aardvark Mao Maui have aye et"] },
   'LatinL4' => { 'title' => "LatinL4",
	          'fontFile' => $ligFont,
		  'dir' => 'L',
		  'script' => 'Latn',
		  'specials' => 1, # -liga plus call Builder filter
		  # tz TZ ue vy ffi ffl ij
		  # TBD see if setting language to German will do ss, tz, TZ
	          'text' => ["Tirpitz TIRPITZ blue heavy suffice waffle pij"] },

   # Demonstrate kerning (closing up overlapping characters) in a Latin script.
   # You should see AVA and AWAY are closed up, due to letter shapes. This can
   # be disabled with $dokern = 0. Note that some minor kerning may be done
   # between other letter pairs, such as 'ke'.
   'LatinK' => { 'title' => "LatinK",  # is kerning done? YES!
	         'fontFile' => $latinFont,
		 'dir' => 'L',
		 'script' => 'Latn',
	         'text' => ["AVA, do AWAY with kerning!"] },

   # Demonstrate synthesis of new accented letters and logos by manipulating a 
   # HarfBuzz array directly. Creates an n-umlaut (not a standard character)
   # and rescales and moves letters (think of the "LA" combination as a new
   # ligature). Note that three letters are Greek, which if it ever causes a
   # problem, would need to be split into separate Shaper chunks.
   'LatinS' => { 'title' => "LatinS",
	         'fontFile' => '/Windows/Fonts/times.ttf',
		 'dir' => 'L',
		 'script' => 'Latn',
		 'specials' => 2,
		 # note use of NONcombining diaeresis, Tau-Epsilon-Chi
		 # this will be cut into 3 pieces, because A is smaller
	         'text' => ["This is Spi\x{A8}nal Tap!  LA\x{03a4}\x{0395}\x{03a7} Rulz?"] },

   # Some Devanagari text (an Indian script). I have no idea if the words here
   # mean anything... I just copied them from an article on typesetting. You
   # can see that there is some rearrangement of characters and some combining
   # and removal, all taken care of by HarfBuzz.
   'Devan' => { 'title' => "Devanagari", # see PP_Advanced pg 26 & 27
	                                 # and PP_Avanced_typography_in_PDF.pdf
	        'fontFile' => '/Program Files/Adobe/Acrobat DC/Resource/Font/AdobeDevanagari-Regular.otf',
		'dir' => 'L',
		'script' => 'Deva',
	        'text' => ["\x{091A}\x{093F}\x{0928}\x{094D}\x{0939}\x{0947}", " PDF::Builder ", "\x{0905}\x{0932}\x{093f}\x{091c}\x{093f}\x{0939}\x{094d}\x{0935}\x{0940}\x{092f}"] },

   # Some Khmer text (a Cambodian script). I don't think the first "word" means
   # anything, but the second may be something like "a dog".
   'Khmer' => { 'title' => "Khmer", 
	        'fontFile' => '/Users/philp/OneDrive/Desktop/closed tickets/D.O.N.E/khmer/KhmerOS_.ttf',
		'dir' => 'L',
		'script' => 'Khmr',
		# KA COENG KA and "dog" CHA COENG KA AE 
	        'text' => ["\x{1780}\x{17D2}\x{1780}", " PDF::Builder ", "\x{1786}\x{17D2}\x{1780}\x{17C2}"] },

   # Some Arabic text. I understand that the first "word" translates to "the
   # Arabic language". I just removed a couple letters to make the second 
   # "word", which probably is meaningless now (just to show the RTL order they 
   # were rendered in). Note that the "left" margin is over on the right side of
   # the page.
   'Arabic' => { 'title' => "Arabic", # see Wikipedia/Complex_text_layout
                 'fontFile' => $arabicFont,
		 'dir' => 'R',
		 'script' => 'Arab',
                 'text' => ["\x{0627}\x{0644}\x{0639}\x{0631}\x{0628}\x{064a}\x{0629}", " PDF::Builder ", "\x{0627}\x{0644}\x{0628}\x{064a}\x{0629}"] },

   # Some Hebrew text. I used Google Translate on a couple phrases like "Hello,
   # my name is" and "Happy to meet you", and transliterated them into Unicode
   # points. The typefaces were not identical (between GT and my Unicode 
   # reference book), so I may have made some mistakes, and I removed a word or 
   # two to shorten the line and emphasize that it is written RTL, so now it 
   # probably doesn't make any sense!
   'Hebrew' => { 'title' => "Hebrew", 
	         'fontFile' => '/WINDOWS/Fonts/times.ttf', # has Hebrew too
		 'dir' => 'R',
		 'script' => 'Hebr',
		 'text' => ["\x{05e9}\x{05dc}\x{05d5}\x{05dd} \x{05e9}\x{05de}\x{05d9}", " PDF::Builder ", "\x{05d5}\x{05d0}\x{05e0}\x{05d9} \x{05e9}\x{05de}\x{05d7}\x{05d4} \x{05dc}\x{05e4}\x{05d2}\x{05d5}\x{05e9} \x{05d0}\x{05d5}\x{05ea}."] },

);
#  many examples (incl Arabic) in 
#    https://en.wikipedia.org/wiki/Zero-width_non-joiner (need fonts to try out)
#  also GitHub tangrams/harfBuzz-example/
#  also see https://english.stackexchange.com/questions/50660/when-should-i-not-
#    use-a-ligature-in-english-typesetting#answer-50957 for many places NOT to 
#    use a ligature (according to the "don't ligature across a morpheme 
#    boundary camp").

my $page = $pdf->page();
my $text = $page->text();
my $grfx = $page->gfx();
my $y = 750;
my $hb = HarfBuzz::Shaper->new();
my ($fontfile, $info, $startx, $starty);
my %settings;

foreach my $samp (sort keys %samples) {
    $settings{'dump'} = $dump;  ### diagnostic dump to STDOUT
    my $title = $samples{$samp}->{'title'};
    $settings{'script'} = $samples{$samp}->{'script'}; ### Latn, Hebr, etc.
    $settings{'features'} = (); ### required entry

    $fontfile = $samples{$samp}->{'fontFile'};
    $text->font($labelFont, $fontsize);
    my $dir = $samples{$samp}->{'dir'}; # L(TR), R(TL), future T(TB), B(TT)
    $text->translate(25, $y);
    
    $text->text($title);
    # same line, at x=150 write raw characters
    print "###### start of $samp output\n";
    my $specials = $samples{$samp}->{'specials'} || 0; # default 0

    # $hb->set_language( 'en_US' ); # unnecessary?
    # $settings{'language'} = 'en'; ###
    # TBD try language = de (German) and see if tz, etc. automatically done
    if ($samples{$samp}->{'script'} eq 'Latn') {
	if (!$doliga || $specials==1) {  ### not needed in textHS
            $hb->add_features( '-liga' );  # +liga is default, -liga works
	    push @{ $settings{'features'} }, '-liga';
	}
	if (!$dokern || $specials==1) {  ### needed in textHS
	    # for forceLigs, turn off kerning to keep clean
            $hb->add_features( '-kern' );  # shut off kerning, +kern default
	    push @{ $settings{'features'} }, '-kern';
	}
    }
    $font = $pdf->ttfont($fontfile);
    $text->font($font, $fontsize);
    $text->translate(150, $y);
    my $textstr = join('', @{ $samples{$samp}->{'text'} });
    $textstr =~ s/[\x{200c}\x{200d}]//g; # remove ZWNJ, ZWJ for text() output
    $text->text($textstr, -strikethru=>$strike, -underline=>$under);
    $y -= $leading*$fontsize;

    # write Shaped chars at x=150 (LTR) or 550 (RTL)
    # Shaper output is LTR even if chunk is RTL
    # we will let 'align' value default (Left aligned for LTR)
    if ($dir eq 'L') {
        $startx = 150; 
	# $settings{'align'} = 'B'; ### beginning of line (LTR at L)
    } else {
        $startx = 550; 
	# $settings{'align'} = 'B'; ### beginning of line (RTL at R)
    }
    $starty = $y;
    $settings{'dir'} = $dir; ###  L(TR), R(TL)

    $hb->set_font($fontfile);
    $hb->set_size($fontsize);
    # start at left or right end of line (beginning)
    $text->translate($startx, $starty);

    foreach (@{ $samples{$samp}->{'text'} }) { # a "chunk" of text
	# if no ligatures, remove ZWNJ and ZWJ (ligature suppression)
	# otherwise may get odd extra space in middle of word
	if (!$doliga) {
            $_ =~ s/[\x{200c}\x{200d}]//g; 
	}
	 
	# TBD here could split up a long string for paragraph/page shaping,
	#       or wait until Shaper gives final sizes.
	# TBD here could do line full justification (modify ax per charspace
	#       and wordspace settings). for connected/cursive scripts, don't
	#       change interletter spacing, just interword. Probably want to 
	#       wait for Shaper to give final sizes.

        $hb->set_text($_);
        $info = $hb->shaper(); # output is built LTR in all cases
	if ($specials == 1) { 
	    # here modify $info array to use additional ligatures if
	    # Shaper doesn't pick them up (e.g., many .ttf fonts)
	    $info = uniLigatures($info); 
        }
	if ($specials == 2) {
	    # special treatment for one line, and only tail end is output here
	    $info = buildChars($info, $strike, %settings);
	}
	
	# output to the PDF file
	$text->textHS($info, \%settings, -strikethru=>$strike, -underline=>$under);

    } # end of array of chunks for one sample

    # show where next write would go
    nextWrite($dir);

    $y -= $leading*$fontsize;

} # end loop through samples

# demonstrate alignment
print "###### start of alignment output\n";
my @xpos = (85, 210, 335, 460);
my @align = ('', 'B', 'C', 'E');

$text->font($labelFont, $fontsize);
$text->translate($xpos[0], 100); $text->text_center('Default');
$text->translate($xpos[1], 100); $text->text_center('B (begin)');
$text->translate($xpos[2], 100); $text->text_center('C (centered)');
$text->translate($xpos[3], 100); $text->text_center('E (end)');
foreach my $x (@xpos) {
    $grfx->poly($x,70, $x,90); $grfx->stroke();
    $grfx->poly($x,40, $x,60); $grfx->stroke();
    $grfx->circle($x,75, 2); $grfx->fill();
    $grfx->circle($x,45, 2); $grfx->fill();
}

# first line is Latin text
$hb->set_font($latinFont);
$hb->set_size($fontsize);
$hb->set_text('aligned');
$info = $hb->shaper(); 
$settings{'dir'} = 'L';

$font = $pdf->ttfont($latinFont);
$text->font($font, $fontsize);
for my $i (0 .. 3) {
    $text->translate($xpos[$i],75); 
    # output to the PDF file

    $settings{'align'} = $align[$i];
    if ($settings{'align'} eq '') { delete $settings{'align'}; }
    $text->textHS($info, \%settings, -strikethru=>$strike, -underline=>$under);
    # show where next write would go
    nextWrite('L');
}

# second line is Arabic text
$hb->set_font($arabicFont);
$hb->set_size($fontsize);
$hb->set_text("\x{0627}\x{0644}\x{0639}\x{0631}\x{0628}\x{064a}\x{0629}");
$info = $hb->shaper(); 
$settings{'dir'} = 'R';

$font = $pdf->ttfont($arabicFont);
$text->font($font, $fontsize);
for my $i (0 .. 3) {
    $text->translate($xpos[$i],45); 
    # output to the PDF file

    $settings{'align'} = $align[$i];
    if ($settings{'align'} eq '') { undef $settings{'align'}; }
    $text->textHS($info, \%settings, -strikethru=>$strike, -underline=>$under);
    
    # show where next write would go
    nextWrite('R');

}

###### second page with vertical orientation text
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();
$y = 750;
#$doliga = 0; # suppress ligatures  NOT necessary?
#$dokern = 0; # suppress kerning  NOT necessary?

%samples = (
   # Latin (English) text top to bottom
   'TTBLatin'     => { 'title' => 'TTBLatin',
	          'fontFile' => $latinFont,
		  'dir' => 'T', 
		  'script' => 'Latn',
		  'text' => ["Hi There!"] },

   # Latin (English) text bottom to top
   # note that Shaper returns reversed text to be rendered TTB
   'BTTLatin'     => { 'title' => 'BTTLatin',
	          'fontFile' => $latinFont,
		  'dir' => 'B', 
		  'script' => 'Latn',
		  'text' => ["Hi There!"] },

   # some random Chinese characters. most interested in what direction is
   # the default, and what is settable
   'TTBChinese' => { 'title' => 'TTBChinese',
#   	        'fontFile' => '/Program Files/Adobe/Acrobat DC/Resource/CIDFont/AdobeMingStd-Light.otf',
   	        'fontFile' => '/Program Files/Adobe/Acrobat DC/Resource/CIDFont/AdobeGothicStd-Light.otf',
 	  	'dir' => 'T',  
 	  	'script' => 'Chin',
# 	  	'text' => ["\x{5A40}\x{5A41}\x{5A42}\x{5A43}", " PDF::Builder ", "\x{5A44}\x{5A45}"] },
# 	  	'text' => ["\x{58D8}\x{5A41}\x{5C62}\x{6A13}", " PDF::Builder ", "\x{6DDA}\x{6F0F}"] },
# want to show some punctuation that gets rotated around in TTB mode. text is Google Translate-produced "use this (whiter teeth)"
##              'text' => ["使用這個（更白的牙齒）。"] },
                'text' => ["\x{4F7F}\x{7528}\x{9019}\x{500B}\x{FF08}\x{66F4}\x{767D}\x{7684}\x{7259}\x{9F52}\x{FF09}\x{3002}"] },

   # Languages which are normally RTL don't seem to behave with TTB.
   # I would expect them to be reversed, but they aren't. Maybe the direction
   # override is scrambling HarfBuzz?
   #
   # Hebrew (normally RTL) and Latin (LTR) TTB direction
   'TTBHebrew' => { 'title' => "TTBHebrew", 
         	 'fontFile' => '/WINDOWS/Fonts/times.ttf', # has Hebrew too
		 'dir' => 'T',
		 'script' => 'Hebr',
		 'text' => ["\x{05e9}\x{05dc}\x{05d5}\x{05dd} \x{05e9}\x{05de}\x{05d9}", " PDF ", "\x{05d5}\x{05d0}\x{05e0}\x{05d9}"] },
 
   # A cursive script such as Arabic needs to be drawn as unconnected individual
   # (standalone) glyphs, but still, I would expect the order to be reversed.
   # Arabic (normally RTL) and Latin (LTR) TTB direction
   'TTBArabic' => { 'title' => "TTBArabic", 
         	 'fontFile' => $arabicFont,
		 'dir' => 'T',
		 'script' => 'Arab',
                 'text' => ["\x{0627}\x{0644}\x{0639}\x{0631}\x{0628}\x{064a}\x{0629}", " PDF ", "\x{0627}\x{0644}\x{0639}"] },

   # Hebrew (normally RTL) and Latin (normally LTR) BTT direction
   'BTTHebrew' => { 'title' => "BTTHebrew", 
         	 'fontFile' => '/WINDOWS/Fonts/times.ttf', # has Hebrew too
		 'dir' => 'B',
		 'script' => 'Hebr',
		 'text' => ["\x{05e9}\x{05dc}\x{05d5}\x{05dd} \x{05e9}\x{05de}\x{05d9}", " NOT rec. ", "\x{05d5}\x{05d0}\x{05e0}\x{05d9}"] },
 
   # Arabic (normally RTL) and Latin (normally LTR) BTT direction
   'BTTArabic' => { 'title' => "BTTArabic", 
         	 'fontFile' => $arabicFont,
		 'dir' => 'B',
		 'script' => 'Arab',
                 'text' => ["\x{0627}\x{0644}\x{0639}\x{0631}\x{0628}\x{064a}\x{0629}", " NOT rec. ", "\x{0627}\x{0644}\x{0639}"] },

);

my $depth = 1; # indentation
foreach my $samp ('TTBLatin', 'BTTLatin', 'TTBChinese', 'BTTHebrew', 'BTTArabic', 'TTBHebrew', 'TTBArabic') {  # in order given
    $settings{'dump'} = $dump;  ### diagnostic dump to STDOUT
    my $title = $samples{$samp}->{'title'};
    $settings{'script'} = $samples{$samp}->{'script'}; ### Latn, Hebr, etc.
    $settings{'features'} = (); ### required entry

    $fontfile = $samples{$samp}->{'fontFile'};
    $text->font($labelFont, $fontsize);
    my $dir = $samples{$samp}->{'dir'}; # L(TR), R(TL), T(TB), B(TT)
    # no underline or strikethru for now TTB, BTT
    if ($dir eq 'T' || $dir eq 'B') { 
       #$strike = 'none';
	$under  = 'none';
    }
    $text->translate(50*$depth, $y);
    
    $text->text($title);
    # same line, at x+150 write raw characters
    print "###### start of $samp output\n";
    my $specials = $samples{$samp}->{'specials'} || 0; # default 0

    # $hb->set_language( 'en_US' ); # unnecessary?
    # $settings{'language'} = 'en'; ###
    # language de-DE does NOT auto-ligature ss and tz
#   if ($samples{$samp}->{'script'} eq 'Latn') {
#       if (!$doliga || $specials==1) {  ### not needed in textHS
#           $hb->add_features( '-liga' );  # +liga is default, -liga works
#           push @{ $settings{'features'} }, '-liga';
#       }
#       if (!$dokern || $specials==1) {  ### needed in textHS
#           # for forceLigs, turn off kerning to keep clean
#           $hb->add_features( '-kern' );  # shut off kerning, +kern default
#           push @{ $settings{'features'} }, '-kern';
#       }
#   }

    $hb->reset(); # clear out previous chunk's explicit settings

    if      ($samples{$samp}->{'dir'} eq 'T') {
        $hb->set_direction('TTB');
    } elsif ($samples{$samp}->{'dir'} eq 'B') {
        $hb->set_direction('BTT');
    } elsif ($samples{$samp}->{'dir'} eq 'L') {
        $hb->set_direction('LTR');
    } else { # R
        $hb->set_direction('RTL');
    }

    # horizontal non-Shaper output
    $font = $pdf->ttfont($fontfile);
    $text->font($font, $fontsize);
    $text->translate(120+50*$depth, $y);
    my $textstr = join('', @{ $samples{$samp}->{'text'} });
    $textstr =~ s/[\x{200c}\x{200d}]//g; # remove ZWNJ, ZWJ for text() output
    $text->text($textstr, -strikethru=>$strike, -underline=>$under);
    $y -= $leading*$fontsize;

    # write Shaped chars at x=50*$depth
    # Shaper output is TTB even if chunk is BTT
    # we will let 'align' value default (Left aligned for LTR)
    $startx = 50*$depth;
    $starty = $y;

    if ($samp eq 'BTTHebrew') { $starty -= 440; }
    if ($samp eq 'BTTArabic') { $starty -= 400; }

    $settings{'dir'} = $dir; ###  L(TR), R(TL), T(TB), B(TT)
    my %opts;
#   my $minKern = 1;

    $hb->set_font($fontfile);
    $hb->set_size($fontsize);

    my $first_chunk = 1;
    foreach (@{ $samples{$samp}->{'text'} }) { # a "chunk" of text
	# if no ligatures, remove ZWNJ and ZWJ (ligature suppression)
	# otherwise may get odd extra space in middle of word
	#if (!$doliga) {
	#    $_ =~ s/[\x{200c}\x{200d}]//g; 
	#}
	 
	# TBD here could split up a long string for paragraph/page shaping,
	#       or wait until Shaper gives final sizes.
	# TBD here could do line full justification (modify ax per charspace
	#       and wordspace settings). for connected/cursive scripts, don't
	#       change interletter spacing, just interword. Probably want to 
	#       wait for Shaper to give final sizes.

        $hb->set_text($_);
        #
        $info = $hb->shaper(); # output is built LTR or TTB in all cases

# what was used?
#print "language found by Shaper (or set): ".($hb->get_language())."\n";
#print "direction found by Shaper (or set): ".($hb->get_direction())."\n";
#print "script found by Shaper (or set): ".($hb->get_script())."\n";
#
#if ($samples{$samp}->{'dir'} eq 'T' || $samples{$samp}->{'dir'} eq 'B') {
#   foreach (@{$info}) {
#     if (defined $_->{'g'}) { print "g $_->{'g'} "; }
#     print "ax $_->{'ax'}, ay $_->{'ay'} dx $_->{'dx'} dy $_->{'dy'}\n";
#   }
#}

	if      ($samp eq 'TTBLatin') {
            # for single Latin text, show alignments, output text, next write
#           my $chunkLength = $text->advancewidthHS($info, \%settings,
#	        	      %opts, -doKern=>$dokern, -minKern=>$minKern);
            my $chunkLength = $text->advancewidthHS($info, \%settings, %opts);
            # B position at top (startx, starty)
            $text->translate($startx-15, $starty-5);
 	    $text->text_right('B');
            $text->translate($startx, $starty);
            $grfx->poly($startx-10,$starty, $startx+10,$starty);
	    $grfx->stroke();
	    $grfx->circle($startx,$starty, 2); 
	    $grfx->fill();
	    # output text
	    $settings{'align'} = 'B';
	    $text->textHS($info, \%settings, -strikethru=>$strike, -underline=>$under);
	    # show next write
	    nextWrite($dir);

            # C position lower
	    $starty -= 1.5*$chunkLength + 50;
            $text->translate($startx-15, $starty-5);
 	    $text->text_right('C');
            $text->translate($startx, $starty);
            $grfx->poly($startx-10,$starty, $startx+10,$starty);
	    $grfx->stroke();
	    $grfx->circle($startx,$starty, 2); 
	    $grfx->fill();
	    # output text
	    $settings{'align'} = 'C';
	    $text->textHS($info, \%settings, -strikethru=>$strike, -underline=>$under);
	    # show next write
	    nextWrite($dir);

            # E position at bottom
	    $starty -= 1.5*$chunkLength + 50;
            $text->translate($startx-15, $starty-5);
 	    $text->text_right('E');
            $text->translate($startx, $starty);
            $grfx->poly($startx-10,$starty, $startx+10,$starty);
	    $grfx->stroke();
	    $grfx->circle($startx,$starty, 2); 
	    $grfx->fill();
	    # output text
	    $settings{'align'} = 'E';
	    $text->textHS($info, \%settings, -strikethru=>$strike, -underline=>$under);

	} elsif ($samp eq 'BTTLatin') {
            # for single Latin text, show alignments, output text, next write
#           my $chunkLength = $text->advancewidthHS($info, \%settings,
#	        	      %opts, -doKern=>$dokern, -minKern=>$minKern);
            my $chunkLength = $text->advancewidthHS($info, \%settings, %opts);
            # B position at top (startx, starty-chunkLength)
	    $starty -= $chunkLength;
            $text->translate($startx-15, $starty-5);
 	    $text->text_right('B');
            $text->translate($startx, $starty);
            $grfx->poly($startx-10,$starty, $startx+10,$starty);
	    $grfx->stroke();
	    $grfx->circle($startx,$starty, 2); 
	    $grfx->fill();
	    # output text
	    $settings{'align'} = 'B';
	    $text->textHS($info, \%settings, -strikethru=>$strike, -underline=>$under);
	    # show next write
	    nextWrite($dir);

            # C position lower
	    $starty -= 0.5*$chunkLength + 50;
            $text->translate($startx-15, $starty-5);
 	    $text->text_right('C');
            $text->translate($startx, $starty);
            $grfx->poly($startx-10,$starty, $startx+10,$starty);
	    $grfx->stroke();
	    $grfx->circle($startx,$starty, 2); 
	    $grfx->fill();
	    # output text
	    $settings{'align'} = 'C';
	    $text->textHS($info, \%settings, -strikethru=>$strike, -underline=>$under);
	    # show next write
	    nextWrite($dir);

            # E position at bottom
	    $starty -= 0.5*$chunkLength + 50;
            $text->translate($startx-15, $starty-5);
 	    $text->text_right('E');
            $text->translate($startx, $starty);
            $grfx->poly($startx-10,$starty, $startx+10,$starty);
	    $grfx->stroke();
	    $grfx->circle($startx,$starty, 2); 
	    $grfx->fill();
	    # output text
	    $settings{'align'} = 'E';
	    $text->textHS($info, \%settings, -strikethru=>$strike, -underline=>$under);

	} else {
	    if ($first_chunk) { # only do first time
                # mark starting position (dir TTB, align B)
                $grfx->poly($startx-10,$starty, $startx+10,$starty);
                $grfx->stroke();
                $grfx->circle($startx,$starty, 2); 
                $grfx->fill();
	        # output text
                $text->translate($startx, $starty);
	        $settings{'align'} = 'B';
		$first_chunk = 0;
	    }
	    $text->textHS($info, \%settings, -strikethru=>$strike, -underline=>$under);
	}
    } # end of array of chunks for one sample
    # show next write
    nextWrite($dir);

    if ($dir eq 'L' || $dir eq 'R') {
        $y -= $leading*$fontsize;
    }

    $depth++;
}

######
$pdf->saveas($PDFname);

###################################################################
sub nextWrite {
    my $dir = shift;

    my @pos = $text->textpos();
    if ($showNextWrite) {
        if      ($dir eq 'L') { 
	    $grfx->poly($pos[0],$pos[1], $pos[0],$pos[1]+10, $pos[0]+5,$pos[1]+5);
        } elsif ($dir eq 'R') { 
	    $grfx->poly($pos[0],$pos[1], $pos[0],$pos[1]+10, $pos[0]-5,$pos[1]+5);
        } elsif ($dir eq 'T') { 
	    $grfx->poly($pos[0]-5,$pos[1], $pos[0]+5,$pos[1], $pos[0],$pos[1]-5);
	} else { # B
	    $grfx->poly($pos[0]-5,$pos[1], $pos[0]+5,$pos[1], $pos[0],$pos[1]+5);
        }
    }
    $grfx->close();
    $grfx->fill();
    return;
}

###################################################################
# A crude filter to look at all Unicode ligatures in a chunk and return
# a modified chunk with ligatures replacing letter combinations it can
# find a glyph for. Note that this may violate a number of languages'
# orthography rules, so use only as a starting point for your own version!
# If you use ZWJ or ZWNJ between letters, it will skip that ligature, but
# then you may have to remove the resulting space between letters.
#
# Some fonts have many, many more ligatures (without Unicode points). Perhaps
# looking at the font CMap could tell what's available (for automated), or 
# just look at 022_truefonts output to manually build another list with 
# similar code.

sub uniLigatures {
    my ($info) = @_;  # array of hashes
    my @array = @{ $info };
    # inherited from caller: $font, $fontsize

    # a table of all known Unicode Latin script ligatures. longest ones first!
    # N=in NimbusRoman-Regular, V=Verdana, A=Arial, T=Times
    my @list = (
	['ffi', 0xFB03],                                              #   NV T
	['ffl', 0xFB04],                                              #   NV T
	["\x{017f}t", 0xFB05], # long s followed by t                       AT
	['et', 0x1F670],  # cannot have a letter preceding or following    
	   # et also 1F671, 1F673, 1F674 (bold); 1F672, 1F675 (light)
        ["\x{02BC}n", 0x149], # close single quote followed by n. cf 'n     AT
	['ss', 0xDF  ],                                               #   NVAT
	['sz', 0xDF  ],                                               #   NVAT
	["'n", 0x149 ], # ' may be U+02BC                             #   NVAT
	['ff', 0xFB00],                                               #   NVAT
	['fi', 0xFB01],                                               #   NV T
	['fl', 0xFB02],                                               #   NV T
	['st', 0xFB06],                                               #     AT
	['aa', 0xA733],                                               #     AT
	['ao', 0xA735],                                               #     AT
	['au', 0xA737],                                               #     AT
	['av', 0xA739],                                               #     AT
	['ay', 0xA73D],                                               #     AT
	['oo', 0xA74F],                                               #     AT
	['tz', 0xA729],                                               #     AT
	['TZ', 0xA728],                                               #     AT
	['Tz', 0xA728], # unclear whether you'll ever see this              AT
	['ue', 0x1D6B],                                               #     AT
	['vy', 0xA761],                                               #     AT
    );

    # The input @array contains glyph IDs, but not Unicode points.
    # For each entry in the substitution @list, build a list of glyphs.
    # Also check that the replacement glyph exists in this font!
    # Compare to @array and if you have 2 or 3 glyph matches, replace
    # the 2 or 3 @array elements by one new element with the replacement
    # glyph and its ax (from character width). ay, dx, dy are 0.

    my $arrayLen = scalar @array;
    foreach my $item (@list) {
	# longest to shortest. does replacement glyph (ligature) even exist?
	if (!defined $font->cidByUni($item->[1])) { next; }

	my @letters = split //, $item->[0]; # 'f', 'f', 'i' etc.
	my @glyphs; # empty list of CIDs
	for (my $i=0; $i<scalar @letters; $i++) {
	    push @glyphs, $font->cidByUni(ord($letters[$i])) || 0;
	}
        my $glyphsLen = scalar @glyphs;

	for (my $letterS=0; $letterS<=$arrayLen-$glyphsLen; $letterS++) { 
            # start char number in array (element number)
            for (my $i=0; $i<$glyphsLen; $i++) {
		if ($array[$letterS+$i]->{'g'} != $glyphs[$i]) { last; }
		# so far, so good. are we on the last glyph?
		while ($i == $glyphsLen-1) {
		    # special cases?
		    # et must have a space on both sides, or be at end
		    # if necessary, could check against letters and punctuation
		    if ($item->[0] eq 'et') {
			my $space = $font->cidByUni(0x20) || 0;
			if ($letterS > 0 && $array[$letterS-1]->{'g'} != $space) { last; }
			if ($letterS < $arrayLen-$glyphsLen && $array[$letterS+$glyphsLen]->{'g'} != $space) { last; }
                    }
                        
		    # Ladies and Gentlemen, we have a match!
		    # rewrite array[letterS] with ligature
		    $array[$letterS]->{'g'}  = $font->cidByUni($item->[1]) || 0;
		    $array[$letterS]->{'ax'} = $font->wxByUni($item->[1])/1000*$fontsize || 0;
		    $array[$letterS]->{'ay'} = 0;
		    $array[$letterS]->{'dx'} = 0;
		    $array[$letterS]->{'dy'} = 0;
		    $array[$letterS]->{'name'} = $item->[0];
      
		    # discard rest of matched elements
                    splice(@array, $letterS+1, $glyphsLen-1);
		    $arrayLen -= $glyphsLen-1;
		    # search will resume at $letterS+1, as array shortened
		    last;
		} # all matched, may or may not have substituted
	    } # loop through all glyphs in ligature
	} # go through letters (glyphs) in chunk
    } # go through each ligature to be considered

    return \@array;
}

###################################################################

# An example of creating a non-standard accented letter (n-umlaut, in this
# case), and replacing and moving characters. In the latter case, since
# one letter is rescaled, the array has to be broken up into five arrays
# and the first four are output here, with the fifth returned for standard 
# processing.

sub buildChars {
    my ($info, $strike, %settings) = @_;  # array of hashes
    my @array = @{ $info };
    # inherited from caller: $text, $font, $fontsize

    my $arrayLen = scalar @array;
    if ($arrayLen != 33) {
	print STDERR "Something went sideways with LatinS, array not expected length\n of 33, but is $arrayLen.";
        return \@array;
    }
    # Assume no ligatures or other funny stuff, so glyphs in the same postion
    # as the Unicode points in the original string.
    #
    # First, we need to split the array into three pieces: up to the 'A' in 
    # LATeX, the 'A' itself (as the font size is 60%), and the TeX Greek text.
    # The first two will be fed to textHS() here, and the third part returned
    # for normal output.

    my (@subArray1, @subArray2);
    @subArray1 = @subArray2 = @array;
    splice(@subArray1, 23);     # This is Spinal Tap!  L
             # note that this includes an umlaut for the n, auto. taken care of
    splice(@subArray2, 24);     # A  to be reduced and moved northwest
    splice(@subArray2, 0, 23);
    splice(@array, 0, 24);      # Tau-Epsilon (drop)-Chi Rulz?

    # there's a lot of trial-and-error positioning and sizing glyphs. you
    # will have to start all over if you change the font or font size.
    # first, adjust the diaeresis (umlaut) position [11] up and right. 
    # n-umlaut is not a standard Unicode character!
    $subArray1[11]->{'dx'} = 1.6;
    $subArray1[11]->{'dy'} = 1.4; 
    $subArray1[11]->{'axs'} = 0; # SET width ("n" starts right after "i")
    $text->textHS(\@subArray1, \%settings, -strikethru=>$strike, -underline=>$under);

    # second, scale down 'A' and move and write. we have to do this letter
    # all by itself b/c the scale has changed. let 'L' take care of underline
    # or strikethru, as 'A' baseline is different. If 'A' extended past 'L',
    # there might be a problem with baseline alignments.
    $text->font($font, 0.6*$fontsize);
    $subArray2[0]->{'axs'} = 0;  # will be almost entirely "within" L
    $subArray2[0]->{'dx'} = -7;  
    $subArray2[0]->{'dy'} = 3.9; 
    $text->textHS(\@subArray2, \%settings, -strikethru=>$strike, -underline=>$under);
    # TBD consider second write with offset to make a little heavier. this 
    # would be repeating the element, with a slightly different dx and dy
    # (say, about 0.5 points each)
    $text->font($font, $fontsize); # restore font

    # third, move Tau left close to LA
    $array[0]->{'dx'} = -2;   # close up to previous glyph
    $array[0]->{'axr'} = 2;   # preserve overall chunk length

    # fourth, move Epsilon down and left. It may already have some kerning
    #  built-in from Tau before it
    $array[1]->{'dx'} = -2;
    $array[1]->{'dy'} = -4;
    $array[1]->{'axr'} = 5;   # close up next glyph
    # Chi and rest of text start at normal place. close up space a bit
    $array[3]->{'axr'} = 2;

    # return Tau Epsilon Chi Rulz? for normal output
    return \@array;
}

